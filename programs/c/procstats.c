#include </opt/cuda/targets/x86_64-linux/include/nvml.h>
#include <ctype.h>
#include <dirent.h>
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
  unsigned int gpu_util_pct;
} GpuProcInfo;

GpuProcInfo gpu_procs[MAX_PIDS];
int gpu_proc_count = 0;

unsigned long long last_seen_ts =
    0; // Tracks newest NVML util sample seen so far

typedef enum { MODE_TABLE, MODE_JSON } OutputMode;

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
  if (nvmlDeviceGetGraphicsRunningProcesses(device, &count, infos) ==
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
  if (nvmlDeviceGetComputeRunningProcesses(device, &count, infos) ==
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
  if (nvmlDeviceGetProcessUtilization(device, util_samples, &util_count,
                                      last_seen_ts) == NVML_SUCCESS) {
    unsigned long long max_ts_this_call = last_seen_ts;

    for (unsigned int i = 0; i < util_count; i++) {
      int idx = get_or_create_gpu_proc(util_samples[i].pid);
      if (idx != -1) {
        gpu_procs[idx].gpu_util_pct = util_samples[i].smUtil;
      }
      if (util_samples[i].timeStamp > max_ts_this_call) {
        max_ts_this_call = util_samples[i].timeStamp;
      }
    }

    last_seen_ts = max_ts_this_call;
  }
}

void get_gpu_info_for_pid(unsigned int pid, unsigned long long *vram_bytes,
                          unsigned int *gpu_util) {
  *vram_bytes = 0;
  *gpu_util = 0;
  for (int i = 0; i < gpu_proc_count; i++) {
    if (gpu_procs[i].pid == pid) {
      *vram_bytes = gpu_procs[i].vram_bytes;
      *gpu_util = gpu_procs[i].gpu_util_pct;
      return;
    }
  }
}

void track_processes(unsigned long long system_ticks_delta, int num_cores,
                     OutputMode mode) {
  DIR *dir = opendir("/proc");
  if (!dir)
    return;

  struct dirent *entry;
  CpuSnap next_cpu_snaps[MAX_PIDS];
  int next_cpu_count = 0;

  if (mode == MODE_TABLE) {
    printf("\033[H\033[J");
    printf("%-8s %-20s %-10s %-10s %-10s %-8s\n", "PID", "NAME", "CPU(%)",
           "RAM(MB)", "VRAM(MB)", "GPU(%)");
    printf("-------------------------------------------------------------------"
           "----\n");
  } else {
    printf("[");
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
    unsigned int gpu_util = 0;
    get_gpu_info_for_pid(pid, &vram_bytes, &gpu_util);
    double vram_mb = vram_bytes / (1024.0 * 1024.0);

    if (ram_mb > 0.1 || vram_mb > 0.0 || gpu_util > 0 || cpu_pct > 0.1) {
      if (mode == MODE_JSON) {
        if (printed_json_count > 0)
          printf(",");
        printf("{\"pid\":%d,\"name\":\"%s\",\"cpu_pct\":%.1f,\"ram_mb\":%.2f,"
               "\"vram_mb\":%.2f,\"gpu_pct\":%u}",
               pid, comm, cpu_pct, ram_mb, vram_mb, gpu_util);
        printed_json_count++;
      } else {
        printf("%-8d %-20s %-10.1f %-10.2f %-10.2f %-8u\n", pid, comm, cpu_pct,
               ram_mb, vram_mb, gpu_util);
      }
    }
  }
  closedir(dir);

  if (mode == MODE_JSON) {
    printf("]\n");
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

  if (nvmlInit() != NVML_SUCCESS) {
    fprintf(stderr, "Failed to initialize NVML\n");
    return 1;
  }

  nvmlDevice_t device;
  if (nvmlDeviceGetHandleByIndex(0, &device) != NVML_SUCCESS) {
    fprintf(stderr, "Failed to get GPU handle\n");
    nvmlShutdown();
    return 1;
  }

  useconds_t sleep_us = (useconds_t)interval_ms * 1000;
  unsigned long long prev_sys_ticks = get_system_cpu_ticks();

  while (1) {
    usleep(sleep_us);

    unsigned long long current_sys_ticks = get_system_cpu_ticks();
    unsigned long long system_ticks_delta = current_sys_ticks - prev_sys_ticks;
    prev_sys_ticks = current_sys_ticks;

    fetch_gpu_data(device);
    track_processes(system_ticks_delta, num_cores, mode);
  }

  nvmlShutdown();
  return 0;
}
