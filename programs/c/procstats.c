#include </opt/cuda/targets/x86_64-linux/include/nvml.h>
#include <ctype.h>
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_PIDS 2048

typedef struct {
  unsigned int pid;
  unsigned long total_proc_ticks;
} CpuSnap;

CpuSnap prev_cpu_snaps[MAX_PIDS];
int prev_cpu_count = 0;

typedef struct {
  unsigned int pid;
  unsigned long long vram_bytes;
  unsigned int gpu_util_pct;   // smUtil    — compute core (SM) occupancy
  unsigned int mem_util_pct;   // memUtil   — memory controller/bandwidth usage
  unsigned int enc_util_pct;   // encUtil   — video encoder engine usage
  unsigned int dec_util_pct;   // decUtil   — video decoder engine usage
} GpuProcInfo;

GpuProcInfo gpu_procs[MAX_PIDS];
int gpu_proc_count = 0;

unsigned long long last_seen_ts =
    0; // Tracks newest NVML util sample seen so far

typedef enum { MODE_TABLE, MODE_JSON } OutputMode;

// ---------------------------------------------------------------------
// Dynamic NVML loading. We deliberately do NOT link against
// libnvidia-ml.so at compile time (no -lnvidia-ml). Instead we dlopen it
// at runtime and resolve each function we need via dlsym. If the library
// isn't present at all (e.g. an AMD-only laptop), dlopen just returns
// NULL and we fall back to CPU/RAM-only mode instead of crashing.
// ---------------------------------------------------------------------

typedef nvmlReturn_t (*nvmlInit_fn)(void);
typedef nvmlReturn_t (*nvmlShutdown_fn)(void);
typedef nvmlReturn_t (*nvmlDeviceGetHandleByIndex_fn)(unsigned int,
                                                       nvmlDevice_t *);
typedef nvmlReturn_t (*nvmlDeviceGetGraphicsRunningProcesses_fn)(
    nvmlDevice_t, unsigned int *, nvmlProcessInfo_t *);
typedef nvmlReturn_t (*nvmlDeviceGetComputeRunningProcesses_fn)(
    nvmlDevice_t, unsigned int *, nvmlProcessInfo_t *);
typedef nvmlReturn_t (*nvmlDeviceGetProcessUtilization_fn)(
    nvmlDevice_t, nvmlProcessUtilizationSample_t *, unsigned int *,
    unsigned long long);

static void *nvml_handle = NULL;
static nvmlInit_fn p_nvmlInit = NULL;
static nvmlShutdown_fn p_nvmlShutdown = NULL;
static nvmlDeviceGetHandleByIndex_fn p_nvmlDeviceGetHandleByIndex = NULL;
static nvmlDeviceGetGraphicsRunningProcesses_fn
    p_nvmlDeviceGetGraphicsRunningProcesses = NULL;
static nvmlDeviceGetComputeRunningProcesses_fn
    p_nvmlDeviceGetComputeRunningProcesses = NULL;
static nvmlDeviceGetProcessUtilization_fn p_nvmlDeviceGetProcessUtilization =
    NULL;

// gpu_available is decided ONCE at startup and gates every GPU code path
// for the rest of the program's life. This is what the UI-facing output
// (JSON's "gpu_available" field / table mode's fallback message) reflects.
int gpu_available = 0;
static nvmlDevice_t nvml_device;

// Tries each candidate symbol name in order, returns the first one that
// resolves. NVML's real ELF-exported names are versioned
// (e.g. "nvmlInit_v2"); the header's plain "nvmlInit" is just a macro
// that only exists at compile time, so dlsym needs the real name.
static void *resolve_symbol(const char *names[], int count) {
  for (int i = 0; i < count; i++) {
    void *sym = dlsym(nvml_handle, names[i]);
    if (sym)
      return sym;
  }
  return NULL;
}

// Attempts to bring up NVML end-to-end: load the library, resolve every
// function we need, call nvmlInit, and grab device 0's handle. Returns 1
// only if ALL of that succeeded — any failure anywhere means "no usable
// NVIDIA GPU" and we cleanly fall back to gpu_available = 0.
int init_nvml_dynamic() {
  nvml_handle = dlopen("libnvidia-ml.so.1", RTLD_NOW);
  if (!nvml_handle) {
    return 0; // no NVIDIA driver installed — not an error, just absence
  }

  p_nvmlInit = (nvmlInit_fn)resolve_symbol(
      (const char *[]){"nvmlInit_v2", "nvmlInit"}, 2);
  p_nvmlShutdown = (nvmlShutdown_fn)resolve_symbol(
      (const char *[]){"nvmlShutdown"}, 1);
  p_nvmlDeviceGetHandleByIndex = (nvmlDeviceGetHandleByIndex_fn)resolve_symbol(
      (const char *[]){"nvmlDeviceGetHandleByIndex_v2",
                       "nvmlDeviceGetHandleByIndex"},
      2);
  p_nvmlDeviceGetGraphicsRunningProcesses =
      (nvmlDeviceGetGraphicsRunningProcesses_fn)resolve_symbol(
          (const char *[]){"nvmlDeviceGetGraphicsRunningProcesses_v3",
                           "nvmlDeviceGetGraphicsRunningProcesses_v2",
                           "nvmlDeviceGetGraphicsRunningProcesses"},
          3);
  p_nvmlDeviceGetComputeRunningProcesses =
      (nvmlDeviceGetComputeRunningProcesses_fn)resolve_symbol(
          (const char *[]){"nvmlDeviceGetComputeRunningProcesses_v3",
                           "nvmlDeviceGetComputeRunningProcesses_v2",
                           "nvmlDeviceGetComputeRunningProcesses"},
          3);
  p_nvmlDeviceGetProcessUtilization =
      (nvmlDeviceGetProcessUtilization_fn)resolve_symbol(
          (const char *[]){"nvmlDeviceGetProcessUtilization"}, 1);

  if (!p_nvmlInit || !p_nvmlShutdown || !p_nvmlDeviceGetHandleByIndex ||
      !p_nvmlDeviceGetGraphicsRunningProcesses ||
      !p_nvmlDeviceGetComputeRunningProcesses ||
      !p_nvmlDeviceGetProcessUtilization) {
    dlclose(nvml_handle);
    nvml_handle = NULL;
    return 0;
  }

  if (p_nvmlInit() != NVML_SUCCESS) {
    dlclose(nvml_handle);
    nvml_handle = NULL;
    return 0;
  }

  if (p_nvmlDeviceGetHandleByIndex(0, &nvml_device) != NVML_SUCCESS) {
    p_nvmlShutdown();
    dlclose(nvml_handle);
    nvml_handle = NULL;
    return 0;
  }

  return 1;
}

unsigned long long get_system_cpu_ticks() {
  FILE *f = fopen("/proc/stat", "r");
  if (!f)
    return 0;

  char line[256];
  if (!fgets(line, sizeof(line), f)) {
    fclose(f);
    return 0;
  }
  fclose(f);

  unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
  sscanf(line, "cpu %llu %llu %llu %llu %llu %llu %llu %llu", &user, &nice,
         &system, &idle, &iowait, &irq, &softirq, &steal);

  return user + nice + system + idle + iowait + irq + softirq + steal;
}

unsigned long get_prev_proc_ticks(unsigned int pid) {
  for (int i = 0; i < prev_cpu_count; i++) {
    if (prev_cpu_snaps[i].pid == pid) {
      return prev_cpu_snaps[i].total_proc_ticks;
    }
  }
  return 0;
}

int get_or_create_gpu_proc(unsigned int pid) {
  for (int i = 0; i < gpu_proc_count; i++) {
    if (gpu_procs[i].pid == pid)
      return i;
  }
  if (gpu_proc_count < MAX_PIDS) {
    gpu_procs[gpu_proc_count].pid = pid;
    gpu_procs[gpu_proc_count].vram_bytes = 0;
    gpu_procs[gpu_proc_count].gpu_util_pct = 0;
    gpu_procs[gpu_proc_count].mem_util_pct = 0;
    gpu_procs[gpu_proc_count].enc_util_pct = 0;
    gpu_procs[gpu_proc_count].dec_util_pct = 0;
    return gpu_proc_count++;
  }
  return -1;
}

// Checks whether a PID still exists, without actually sending it a signal.
// kill(pid, 0) does no harm — it just asks the kernel "does this PID exist
// and am I allowed to signal it?" ESRCH means "no such process".
int pid_alive(unsigned int pid) {
  return kill((pid_t)pid, 0) == 0 || errno != ESRCH;
}

// Removes entries for PIDs that have exited, so gpu_procs doesn't grow
// forever. Compacts the array in place (like sliding surviving elements
// down over the gaps left by dead ones).
void evict_dead_gpu_procs() {
  int write_idx = 0;
  for (int i = 0; i < gpu_proc_count; i++) {
    if (pid_alive(gpu_procs[i].pid)) {
      if (write_idx != i) {
        gpu_procs[write_idx] = gpu_procs[i];
      }
      write_idx++;
    }
  }
  gpu_proc_count = write_idx;
}

void fetch_gpu_data(nvmlDevice_t device) {
  evict_dead_gpu_procs();

  // NOTE: gpu_procs is no longer wiped every call. VRAM is refreshed in
  // full each round (NVML gives us the complete list), but gpu_util_pct
  // must persist across calls that don't get a fresh sample, otherwise
  // a still-active process reads as 0% whenever NVML's sampling window
  // hasn't produced new data yet.
  unsigned int count = MAX_PIDS;
  nvmlProcessInfo_t infos[MAX_PIDS];
  int vram_seen[MAX_PIDS] = {0};

  // 1. Graphics processes
  if (p_nvmlDeviceGetGraphicsRunningProcesses(device, &count, infos) ==
      NVML_SUCCESS) {
    for (unsigned int i = 0; i < count; i++) {
      int idx = get_or_create_gpu_proc(infos[i].pid);
      if (idx != -1) {
        gpu_procs[idx].vram_bytes = infos[i].usedGpuMemory;
        vram_seen[idx] = 1;
      }
    }
  }

  // 2. Compute processes
  count = MAX_PIDS;
  if (p_nvmlDeviceGetComputeRunningProcesses(device, &count, infos) ==
      NVML_SUCCESS) {
    for (unsigned int i = 0; i < count; i++) {
      int idx = get_or_create_gpu_proc(infos[i].pid);
      if (idx != -1) {
        gpu_procs[idx].vram_bytes = infos[i].usedGpuMemory;
        vram_seen[idx] = 1;
      }
    }
  }

  // Any tracked process NOT reported by either list above is no longer
  // holding GPU memory, so its VRAM is cleared. gpu_util_pct is left
  // untouched here on purpose.
  for (int i = 0; i < gpu_proc_count; i++) {
    if (!vram_seen[i]) {
      gpu_procs[i].vram_bytes = 0;
    }
  }

  // 3. Process GPU utilization — only overwrite when a NEW sample exists
  unsigned int util_count = MAX_PIDS;
  nvmlProcessUtilizationSample_t util_samples[MAX_PIDS];
  if (p_nvmlDeviceGetProcessUtilization(device, util_samples, &util_count,
                                        last_seen_ts) == NVML_SUCCESS) {
    unsigned long long max_ts_this_call = last_seen_ts;

    for (unsigned int i = 0; i < util_count; i++) {
      int idx = get_or_create_gpu_proc(util_samples[i].pid);
      if (idx != -1) {
        gpu_procs[idx].gpu_util_pct = util_samples[i].smUtil;
        gpu_procs[idx].mem_util_pct = util_samples[i].memUtil;
        gpu_procs[idx].enc_util_pct = util_samples[i].encUtil;
        gpu_procs[idx].dec_util_pct = util_samples[i].decUtil;
      }
      if (util_samples[i].timeStamp > max_ts_this_call) {
        max_ts_this_call = util_samples[i].timeStamp;
      }
    }

    last_seen_ts = max_ts_this_call;
  }
}

void get_gpu_info_for_pid(unsigned int pid, unsigned long long *vram_bytes,
                          unsigned int *gpu_util, unsigned int *mem_util,
                          unsigned int *enc_util, unsigned int *dec_util) {
  *vram_bytes = 0;
  *gpu_util = 0;
  *mem_util = 0;
  *enc_util = 0;
  *dec_util = 0;
  for (int i = 0; i < gpu_proc_count; i++) {
    if (gpu_procs[i].pid == pid) {
      *vram_bytes = gpu_procs[i].vram_bytes;
      *gpu_util = gpu_procs[i].gpu_util_pct;
      *mem_util = gpu_procs[i].mem_util_pct;
      *enc_util = gpu_procs[i].enc_util_pct;
      *dec_util = gpu_procs[i].dec_util_pct;
      return;
    }
  }
}

void track_processes(unsigned long long system_ticks_delta, int num_cores,
                     OutputMode mode, int gpu_avail) {
  DIR *dir = opendir("/proc");
  if (!dir)
    return;

  struct dirent *entry;
  CpuSnap next_cpu_snaps[MAX_PIDS];
  int next_cpu_count = 0;

  if (mode == MODE_TABLE) {
    printf("\033[H\033[J");
    if (gpu_avail) {
      printf("%-8s %-20s %-10s %-10s %-10s %-8s %-8s %-8s %-8s\n", "PID",
             "NAME", "CPU(%)", "RAM(MB)", "VRAM(MB)", "SM(%)", "MEM(%)",
             "ENC(%)", "DEC(%)");
      printf(
          "-------------------------------------------------------------------"
          "---------------------------\n");
    } else {
      printf("%-8s %-20s %-10s %-10s\n", "PID", "NAME", "CPU(%)", "RAM(MB)");
      printf("(GPU stats unavailable on this device — no supported NVIDIA "
             "driver found)\n");
      printf("--------------------------------------------------\n");
    }
  } else {
    printf("{\"gpu_available\":%s,\"processes\":[",
           gpu_avail ? "true" : "false");
  }

  int printed_json_count = 0;

  while ((entry = readdir(dir)) != NULL) {
    if (!isdigit(entry->d_name[0]))
      continue;

    int pid = atoi(entry->d_name);
    char path[256], comm[256] = "Unknown";
    unsigned long utime = 0, stime = 0;
    long rss_pages = 0;

    snprintf(path, sizeof(path), "/proc/%d/stat", pid);
    FILE *fstat = fopen(path, "r");
    if (fstat) {
      fscanf(
          fstat,
          "%*d (%255[^)]) %*c %*d %*d %*d %*d %*d %*u %*u %*u %*u %*u %lu %lu",
          comm, &utime, &stime);
      fclose(fstat);
    } else {
      continue;
    }

    snprintf(path, sizeof(path), "/proc/%d/statm", pid);
    FILE *fstatm = fopen(path, "r");
    if (fstatm) {
      fscanf(fstatm, "%*d %ld", &rss_pages);
      fclose(fstatm);
    }

    unsigned long total_proc_ticks = utime + stime;

    if (next_cpu_count < MAX_PIDS) {
      next_cpu_snaps[next_cpu_count].pid = pid;
      next_cpu_snaps[next_cpu_count].total_proc_ticks = total_proc_ticks;
      next_cpu_count++;
    }

    double cpu_pct = 0.0;
    if (system_ticks_delta > 0) {
      unsigned long prev_proc_ticks = get_prev_proc_ticks(pid);
      if (prev_proc_ticks > 0 && total_proc_ticks >= prev_proc_ticks) {
        unsigned long proc_ticks_delta = total_proc_ticks - prev_proc_ticks;
        cpu_pct =
            ((double)proc_ticks_delta / system_ticks_delta) * 100.0 * num_cores;
      }
    }

    long page_size_kb = sysconf(_SC_PAGESIZE) / 1024;
    double ram_mb = (rss_pages * page_size_kb) / 1024.0;

    unsigned long long vram_bytes = 0;
    unsigned int gpu_util = 0, mem_util = 0, enc_util = 0, dec_util = 0;
    if (gpu_avail) {
      get_gpu_info_for_pid(pid, &vram_bytes, &gpu_util, &mem_util, &enc_util,
                           &dec_util);
    }
    double vram_mb = vram_bytes / (1024.0 * 1024.0);

    int worth_printing =
        (ram_mb > 0.1 || cpu_pct > 0.1) ||
        (gpu_avail && (vram_mb > 0.0 || gpu_util > 0 || mem_util > 0 ||
                      enc_util > 0 || dec_util > 0));

    if (worth_printing) {
      if (mode == MODE_JSON) {
        if (printed_json_count > 0)
          printf(",");
        if (gpu_avail) {
          printf("{\"pid\":%d,\"name\":\"%s\",\"cpu_pct\":%.1f,\"ram_mb\":%."
                 "2f,\"vram_mb\":%.2f,\"gpu_pct\":%u,\"mem_pct\":%u,\"enc_"
                 "pct\":%u,\"dec_pct\":%u}",
                 pid, comm, cpu_pct, ram_mb, vram_mb, gpu_util, mem_util,
                 enc_util, dec_util);
        } else {
          printf("{\"pid\":%d,\"name\":\"%s\",\"cpu_pct\":%.1f,\"ram_mb\":%."
                 "2f}",
                 pid, comm, cpu_pct, ram_mb);
        }
        printed_json_count++;
      } else {
        if (gpu_avail) {
          printf("%-8d %-20s %-10.1f %-10.2f %-10.2f %-8u %-8u %-8u %-8u\n",
                 pid, comm, cpu_pct, ram_mb, vram_mb, gpu_util, mem_util,
                 enc_util, dec_util);
        } else {
          printf("%-8d %-20s %-10.1f %-10.2f\n", pid, comm, cpu_pct, ram_mb);
        }
      }
    }
  }
  closedir(dir);

  if (mode == MODE_JSON) {
    printf("]}\n");
  }

  memcpy(prev_cpu_snaps, next_cpu_snaps, sizeof(CpuSnap) * next_cpu_count);
  prev_cpu_count = next_cpu_count;

  fflush(stdout);
}

int main(int argc, char *argv[]) {
  int interval_ms = 1000;
  OutputMode mode = MODE_TABLE; // Default mode

  if (argc > 1) {
    interval_ms = atoi(argv[1]);
    if (interval_ms <= 0) {
      fprintf(stderr, "Usage: %s [interval_ms] [table|json]\n", argv[0]);
      return 1;
    }
  }

  if (argc > 2) {
    if (strcmp(argv[2], "json") == 0) {
      mode = MODE_JSON;
    } else if (strcmp(argv[2], "table") == 0) {
      mode = MODE_TABLE;
    } else {
      fprintf(stderr, "Invalid mode: '%s'. Use 'table' or 'json'.\n", argv[2]);
      return 1;
    }
  }

  int num_cores = sysconf(_SC_NPROCESSORS_ONLN);

  // Try to bring up NVML dynamically. Failure here is NOT fatal — it just
  // means we run in CPU/RAM-only mode for the rest of the program's life.
  gpu_available = init_nvml_dynamic();

  if (mode == MODE_TABLE && !gpu_available) {
    fprintf(stderr,
            "Note: no supported NVIDIA GPU/driver found — running in "
            "CPU/RAM-only mode.\n");
  }

  useconds_t sleep_us = (useconds_t)interval_ms * 1000;
  unsigned long long prev_sys_ticks = get_system_cpu_ticks();

  while (1) {
    usleep(sleep_us);

    unsigned long long current_sys_ticks = get_system_cpu_ticks();
    unsigned long long system_ticks_delta = current_sys_ticks - prev_sys_ticks;
    prev_sys_ticks = current_sys_ticks;

    if (gpu_available) {
      fetch_gpu_data(nvml_device);
    }
    track_processes(system_ticks_delta, num_cores, mode, gpu_available);
  }

  if (gpu_available) {
    p_nvmlShutdown();
  }
  if (nvml_handle) {
    dlclose(nvml_handle);
  }

  return 0;
}
