#include <ctype.h>
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <nvml.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

typedef enum {
  GPU_VENDOR_NONE = 0,
  GPU_VENDOR_NVIDIA,
  GPU_VENDOR_AMD
} GpuVendor;

typedef enum {
  PROC_TYPE_NONE = 0,
  PROC_TYPE_GRAPHICS = (1 << 0),                            // 1
  PROC_TYPE_COMPUTE = (1 << 1),                             // 2
  PROC_TYPE_BOTH = (PROC_TYPE_GRAPHICS | PROC_TYPE_COMPUTE) // 3
} GpuProcType;

typedef enum { MODE_TABLE, MODE_JSON } OutputMode;

// ---------------------------------------------------------------------
// Dynamic CPU Snap Storage
// ---------------------------------------------------------------------
typedef struct {
  unsigned int pid;
  unsigned long total_proc_ticks;
} CpuSnap;

static CpuSnap *prev_cpu_snaps = NULL;
static int prev_cpu_count = 0;
static int prev_cpu_capacity = 0;

static CpuSnap *next_cpu_snaps = NULL;
static int next_cpu_count = 0;
static int next_cpu_capacity = 0;

// ---------------------------------------------------------------------
// Dynamic GPU Process Info Storage
// ---------------------------------------------------------------------
typedef struct {
  unsigned int pid;
  unsigned long long vram_bytes;
  GpuProcType type;
  unsigned int gpu_util_pct; // Unified GPU utilization % (SM/Engine)
  unsigned int mem_util_pct;
  unsigned int enc_util_pct;
  unsigned int dec_util_pct;

  // Last seen nanoseconds for AMD calculation
  unsigned long long prev_gfx_ns;
  unsigned long long prev_compute_ns;
  unsigned long long prev_enc_ns;
  unsigned long long prev_dec_ns;
} GpuProcInfo;

static GpuProcInfo *gpu_procs = NULL;
static int gpu_proc_count = 0;
static int gpu_proc_capacity = 0;

static unsigned long long last_seen_ts = 0; // NVML timestamp tracking

// Global state
static GpuVendor active_gpu_vendor = GPU_VENDOR_NONE;
static int gpu_available = 0;
static volatile sig_atomic_t keep_running = 1;

// ---------------------------------------------------------------------
// Dynamic NVML Function Pointers
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
static nvmlDevice_t nvml_device;

static void handle_signal(int sig) {
  (void)sig;
  keep_running = 0;
}

static void *resolve_symbol(const char *names[], int count) {
  for (int i = 0; i < count; i++) {
    void *sym = dlsym(nvml_handle, names[i]);
    if (sym)
      return sym;
  }
  return NULL;
}

int init_nvml_dynamic(void) {
  nvml_handle = dlopen("libnvidia-ml.so.1", RTLD_NOW);
  if (!nvml_handle) {
    nvml_handle = dlopen("libnvidia-ml.so", RTLD_NOW);
    if (!nvml_handle)
      return 0;
  }

  p_nvmlInit = (nvmlInit_fn)resolve_symbol(
      (const char *[]){"nvmlInit_v2", "nvmlInit"}, 2);
  p_nvmlShutdown =
      (nvmlShutdown_fn)resolve_symbol((const char *[]){"nvmlShutdown"}, 1);
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

// ---------------------------------------------------------------------
// AMD GPU Detection & /proc/<pid>/fdinfo Scanner
// ---------------------------------------------------------------------
int detect_amd_gpu(void) {
  DIR *dir = opendir("/sys/class/drm");
  if (!dir)
    return 0;

  struct dirent *entry;
  int found = 0;
  while ((entry = readdir(dir)) != NULL) {
    if (strncmp(entry->d_name, "card", 4) == 0 && !strchr(entry->d_name, '-')) {
      char path[256];
      snprintf(path, sizeof(path), "/sys/class/drm/%s/device/vendor",
               entry->d_name);
      FILE *f = fopen(path, "r");
      if (f) {
        char vendor[32];
        if (fgets(vendor, sizeof(vendor), f)) {
          if (strstr(vendor, "0x1002")) { // 0x1002 = AMD PCI Vendor ID
            found = 1;
            fclose(f);
            break;
          }
        }
        fclose(f);
      }
    }
  }
  closedir(dir);
  return found;
}

typedef struct {
  unsigned long long vram_bytes;
  GpuProcType type;
  unsigned long long gfx_ns;
  unsigned long long compute_ns;
  unsigned long long enc_ns;
  unsigned long long dec_ns;
} AmdFdinfoData;

void scan_amd_fdinfo(unsigned int pid, AmdFdinfoData *out) {
  memset(out, 0, sizeof(AmdFdinfoData));
  char fdinfo_dir[256];
  snprintf(fdinfo_dir, sizeof(fdinfo_dir), "/proc/%u/fdinfo", pid);

  DIR *dir = opendir(fdinfo_dir);
  if (!dir)
    return;

  struct dirent *entry;
  while ((entry = readdir(dir)) != NULL) {
    if (entry->d_name[0] == '.')
      continue;

    char filepath[512];
    snprintf(filepath, sizeof(filepath), "%s/%s", fdinfo_dir, entry->d_name);

    FILE *f = fopen(filepath, "r");
    if (!f)
      continue;

    char line[256];
    int is_amdgpu = 0;
    unsigned long long vram_kb = 0;
    unsigned long long gfx_ns = 0, compute_ns = 0, enc_ns = 0, dec_ns = 0;

    while (fgets(line, sizeof(line), f)) {
      if (strncmp(line, "drm-driver:", 11) == 0) {
        if (strstr(line, "amdgpu")) {
          is_amdgpu = 1;
        }
      } else if (strncmp(line, "drm-memory-vram:", 16) == 0) {
        sscanf(line, "drm-memory-vram:\t%llu", &vram_kb);
      } else if (strncmp(line, "drm-engine-gfx:", 15) == 0) {
        sscanf(line, "drm-engine-gfx:\t%llu", &gfx_ns);
      } else if (strncmp(line, "drm-engine-compute:", 19) == 0) {
        sscanf(line, "drm-engine-compute:\t%llu", &compute_ns);
      } else if (strncmp(line, "drm-engine-enc:", 15) == 0 ||
                 strncmp(line, "drm-engine-vce:", 15) == 0) {
        sscanf(line, "%*s\t%llu", &enc_ns);
      } else if (strncmp(line, "drm-engine-dec:", 15) == 0 ||
                 strncmp(line, "drm-engine-uvd:", 15) == 0 ||
                 strncmp(line, "drm-engine-vcn:", 15) == 0) {
        sscanf(line, "%*s\t%llu", &dec_ns);
      }
    }
    fclose(f);

    if (is_amdgpu) {
      out->vram_bytes += vram_kb * 1024;
      out->gfx_ns += gfx_ns;
      out->compute_ns += compute_ns;
      out->enc_ns += enc_ns;
      out->dec_ns += dec_ns;
      if (gfx_ns > 0)
        out->type |= PROC_TYPE_GRAPHICS;
      if (compute_ns > 0)
        out->type |= PROC_TYPE_COMPUTE;
    }
  }
  closedir(dir);
}

void init_gpu_system(void) {
  if (init_nvml_dynamic()) {
    active_gpu_vendor = GPU_VENDOR_NVIDIA;
    gpu_available = 1;
  } else if (detect_amd_gpu()) {
    active_gpu_vendor = GPU_VENDOR_AMD;
    gpu_available = 1;
  } else {
    active_gpu_vendor = GPU_VENDOR_NONE;
    gpu_available = 0;
  }
}

unsigned long long get_system_cpu_ticks(void) {
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

  if (gpu_proc_count >= gpu_proc_capacity) {
    int new_cap = (gpu_proc_capacity == 0) ? 256 : gpu_proc_capacity * 2;
    GpuProcInfo *tmp = realloc(gpu_procs, new_cap * sizeof(GpuProcInfo));
    if (!tmp)
      return -1;
    gpu_procs = tmp;
    gpu_proc_capacity = new_cap;
  }

  gpu_procs[gpu_proc_count].pid = pid;
  gpu_procs[gpu_proc_count].vram_bytes = 0;
  gpu_procs[gpu_proc_count].type = PROC_TYPE_NONE;
  gpu_procs[gpu_proc_count].gpu_util_pct = 0;
  gpu_procs[gpu_proc_count].mem_util_pct = 0;
  gpu_procs[gpu_proc_count].enc_util_pct = 0;
  gpu_procs[gpu_proc_count].dec_util_pct = 0;
  gpu_procs[gpu_proc_count].prev_gfx_ns = 0;
  gpu_procs[gpu_proc_count].prev_compute_ns = 0;
  gpu_procs[gpu_proc_count].prev_enc_ns = 0;
  gpu_procs[gpu_proc_count].prev_dec_ns = 0;
  return gpu_proc_count++;
}

int pid_alive(unsigned int pid) {
  return kill((pid_t)pid, 0) == 0 || errno != ESRCH;
}

void evict_dead_gpu_procs(void) {
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

void fetch_nvidia_gpu_data(nvmlDevice_t device) {
  evict_dead_gpu_procs();

  for (int i = 0; i < gpu_proc_count; i++) {
    gpu_procs[i].vram_bytes = 0;
    gpu_procs[i].type = PROC_TYPE_NONE;
    gpu_procs[i].gpu_util_pct = 0;
    gpu_procs[i].mem_util_pct = 0;
    gpu_procs[i].enc_util_pct = 0;
    gpu_procs[i].dec_util_pct = 0;
  }

  unsigned int count = 1024;
  nvmlProcessInfo_t *infos = malloc(count * sizeof(nvmlProcessInfo_t));
  if (!infos)
    return;

  if (p_nvmlDeviceGetGraphicsRunningProcesses(device, &count, infos) ==
      NVML_SUCCESS) {
    for (unsigned int i = 0; i < count; i++) {
      int idx = get_or_create_gpu_proc(infos[i].pid);
      if (idx != -1) {
        gpu_procs[idx].vram_bytes = infos[i].usedGpuMemory;
        gpu_procs[idx].type |= PROC_TYPE_GRAPHICS;
      }
    }
  }

  count = 1024;
  if (p_nvmlDeviceGetComputeRunningProcesses(device, &count, infos) ==
      NVML_SUCCESS) {
    for (unsigned int i = 0; i < count; i++) {
      int idx = get_or_create_gpu_proc(infos[i].pid);
      if (idx != -1) {
        if (infos[i].usedGpuMemory > gpu_procs[idx].vram_bytes) {
          gpu_procs[idx].vram_bytes = infos[i].usedGpuMemory;
        }
        gpu_procs[idx].type |= PROC_TYPE_COMPUTE;
      }
    }
  }
  free(infos);

  unsigned int util_count = 1024;
  nvmlProcessUtilizationSample_t *util_samples =
      malloc(util_count * sizeof(nvmlProcessUtilizationSample_t));
  if (util_samples) {
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
    free(util_samples);
  }
}

void fetch_amd_gpu_data(unsigned long long interval_ns) {
  evict_dead_gpu_procs();

  DIR *dir = opendir("/proc");
  if (!dir)
    return;

  struct dirent *entry;
  while ((entry = readdir(dir)) != NULL) {
    if (!isdigit(entry->d_name[0]))
      continue;
    unsigned int pid = (unsigned int)atoi(entry->d_name);

    AmdFdinfoData amd_data;
    scan_amd_fdinfo(pid, &amd_data);

    if (amd_data.vram_bytes > 0 || amd_data.type != PROC_TYPE_NONE) {
      int idx = get_or_create_gpu_proc(pid);
      if (idx != -1) {
        gpu_procs[idx].vram_bytes = amd_data.vram_bytes;
        gpu_procs[idx].type = amd_data.type;

        if (interval_ns > 0) {
          unsigned long long total_engine_ns_delta = 0;

          if (gpu_procs[idx].prev_gfx_ns > 0 &&
              amd_data.gfx_ns >= gpu_procs[idx].prev_gfx_ns) {
            total_engine_ns_delta +=
                (amd_data.gfx_ns - gpu_procs[idx].prev_gfx_ns);
          }
          if (gpu_procs[idx].prev_compute_ns > 0 &&
              amd_data.compute_ns >= gpu_procs[idx].prev_compute_ns) {
            total_engine_ns_delta +=
                (amd_data.compute_ns - gpu_procs[idx].prev_compute_ns);
          }

          unsigned int util =
              (unsigned int)((total_engine_ns_delta * 100ULL) / interval_ns);
          gpu_procs[idx].gpu_util_pct = (util > 100) ? 100 : util;

          if (gpu_procs[idx].prev_enc_ns > 0 &&
              amd_data.enc_ns >= gpu_procs[idx].prev_enc_ns) {
            unsigned long long delta =
                amd_data.enc_ns - gpu_procs[idx].prev_enc_ns;
            gpu_procs[idx].enc_util_pct =
                (unsigned int)((delta * 100ULL) / interval_ns);
          }
          if (gpu_procs[idx].prev_dec_ns > 0 &&
              amd_data.dec_ns >= gpu_procs[idx].prev_dec_ns) {
            unsigned long long delta =
                amd_data.dec_ns - gpu_procs[idx].prev_dec_ns;
            gpu_procs[idx].dec_util_pct =
                (unsigned int)((delta * 100ULL) / interval_ns);
          }
        }

        gpu_procs[idx].prev_gfx_ns = amd_data.gfx_ns;
        gpu_procs[idx].prev_compute_ns = amd_data.compute_ns;
        gpu_procs[idx].prev_enc_ns = amd_data.enc_ns;
        gpu_procs[idx].prev_dec_ns = amd_data.dec_ns;
      }
    }
  }
  closedir(dir);
}

void get_gpu_info_for_pid(unsigned int pid, unsigned long long *vram_bytes,
                          GpuProcType *type, unsigned int *gpu_util,
                          unsigned int *mem_util, unsigned int *enc_util,
                          unsigned int *dec_util) {
  *vram_bytes = 0;
  *type = PROC_TYPE_NONE;
  *gpu_util = 0;
  *mem_util = 0;
  *enc_util = 0;
  *dec_util = 0;

  for (int i = 0; i < gpu_proc_count; i++) {
    if (gpu_procs[i].pid == pid) {
      *vram_bytes = gpu_procs[i].vram_bytes;
      *type = gpu_procs[i].type;
      *gpu_util = gpu_procs[i].gpu_util_pct;
      *mem_util = gpu_procs[i].mem_util_pct;
      *enc_util = gpu_procs[i].enc_util_pct;
      *dec_util = gpu_procs[i].dec_util_pct;
      return;
    }
  }
}

// Read process command line from /proc/<pid>/cmdline
void get_process_cmdline(int pid, char *out_buf, size_t max_len,
                         const char *fallback) {
  char path[256];
  snprintf(path, sizeof(path), "/proc/%d/cmdline", pid);

  FILE *f = fopen(path, "r");
  if (!f) {
    snprintf(out_buf, max_len, "[%s]", fallback);
    return;
  }

  size_t bytes_read = fread(out_buf, 1, max_len - 1, f);
  fclose(f);

  if (bytes_read == 0) {
    // Kernel thread or empty cmdline fallback
    snprintf(out_buf, max_len, "[%s]", fallback);
    return;
  }

  out_buf[bytes_read] = '\0';

  // Replace null byte separators with spaces
  for (size_t i = 0; i < bytes_read - 1; i++) {
    if (out_buf[i] == '\0') {
      out_buf[i] = ' ';
    }
  }
}

const char *get_proc_type_str(GpuProcType type) {
  switch (type) {
  case PROC_TYPE_GRAPHICS:
    return "GFX";
  case PROC_TYPE_COMPUTE:
    return "COMP";
  case PROC_TYPE_BOTH:
    return "BOTH";
  default:
    return "N/A";
  }
}

static void print_json_escaped(const char *str) {
  for (const char *p = str; *p; p++) {
    switch (*p) {
    case '"':
      fputs("\\\"", stdout);
      break;
    case '\\':
      fputs("\\\\", stdout);
      break;
    case '\b':
      fputs("\\b", stdout);
      break;
    case '\f':
      fputs("\\f", stdout);
      break;
    case '\n':
      fputs("\\n", stdout);
      break;
    case '\r':
      fputs("\\r", stdout);
      break;
    case '\t':
      fputs("\\t", stdout);
      break;
    default:
      if ((unsigned char)*p < 0x20) {
        printf("\\u%04x", (unsigned char)*p);
      } else {
        putchar(*p);
      }
      break;
    }
  }
}

void track_processes(unsigned long long system_ticks_delta, int num_cores,
                     OutputMode mode, int gpu_avail) {
  DIR *dir = opendir("/proc");
  if (!dir)
    return;

  struct dirent *entry;
  next_cpu_count = 0;

  const char *vendor_str = (active_gpu_vendor == GPU_VENDOR_NVIDIA) ? "NVIDIA"
                           : (active_gpu_vendor == GPU_VENDOR_AMD)  ? "AMD"
                                                                    : "None";

  if (mode == MODE_TABLE) {
    printf("\033[H\033[J");
    if (gpu_avail) {
      printf("%-8s %-16s %-8s %-10s %-6s %-10s %-8s %-8s %-8s %-8s %s\n", "PID",
             "NAME", "CPU(%)", "RAM(MB)", "TYPE", "VRAM(MB)", "GPU(%)",
             "MEM(%)", "ENC(%)", "DEC(%)", "COMMAND");
      printf("-----------------------------------------------------------------"
             "--------------------------------------------------\n");
    } else {
      printf("%-8s %-16s %-8s %-10s %s\n", "PID", "NAME", "CPU(%)", "RAM(MB)",
             "COMMAND");
      printf(
          "(GPU stats unavailable — no supported NVIDIA or AMD GPU found)\n");
      printf("-----------------------------------------------------------------"
             "-----\n");
    }
  } else {
    printf("{\"gpu_available\":%s,\"gpu_vendor\":\"%s\",\"processes\":[",
           gpu_avail ? "true" : "false", vendor_str);
  }

  int printed_json_count = 0;

  while ((entry = readdir(dir)) != NULL) {
    if (!isdigit(entry->d_name[0]))
      continue;

    int pid = atoi(entry->d_name);
    char path[256], comm[256] = "Unknown", cmdline[2048] = "";
    unsigned long utime = 0, stime = 0;
    long rss_pages = 0;

    snprintf(path, sizeof(path), "/proc/%d/stat", pid);
    FILE *fstat = fopen(path, "r");
    if (fstat) {
      char stat_buf[1024];
      if (fgets(stat_buf, sizeof(stat_buf), fstat)) {
        char *open_paren = strchr(stat_buf, '(');
        char *close_paren = strrchr(stat_buf, ')');

        if (open_paren && close_paren && close_paren > open_paren) {
          int comm_len = close_paren - open_paren - 1;
          if (comm_len > 255)
            comm_len = 255;
          strncpy(comm, open_paren + 1, comm_len);
          comm[comm_len] = '\0';

          sscanf(close_paren + 2,
                 "%*c %*d %*d %*d %*d %*d %*u %*u %*u %*u %*u %lu %lu", &utime,
                 &stime);
        }
      }
      fclose(fstat);
    } else {
      continue;
    }

    // Fetch command line from /proc/<pid>/cmdline
    get_process_cmdline(pid, cmdline, sizeof(cmdline), comm);

    snprintf(path, sizeof(path), "/proc/%d/statm", pid);
    FILE *fstatm = fopen(path, "r");
    if (fstatm) {
      fscanf(fstatm, "%*d %ld", &rss_pages);
      fclose(fstatm);
    }

    unsigned long total_proc_ticks = utime + stime;

    if (next_cpu_count >= next_cpu_capacity) {
      int new_cap = (next_cpu_capacity == 0) ? 256 : next_cpu_capacity * 2;
      CpuSnap *tmp = realloc(next_cpu_snaps, new_cap * sizeof(CpuSnap));
      if (tmp) {
        next_cpu_snaps = tmp;
        next_cpu_capacity = new_cap;
      }
    }

    if (next_cpu_count < next_cpu_capacity) {
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
    GpuProcType gpu_type = PROC_TYPE_NONE;
    unsigned int gpu_util = 0, mem_util = 0, enc_util = 0, dec_util = 0;

    if (gpu_avail) {
      get_gpu_info_for_pid(pid, &vram_bytes, &gpu_type, &gpu_util, &mem_util,
                           &enc_util, &dec_util);
    }
    double vram_mb = vram_bytes / (1024.0 * 1024.0);

    int worth_printing =
        (ram_mb > 0.1 || cpu_pct > 0.1) ||
        (gpu_avail &&
         (vram_mb > 0.0 || gpu_type != PROC_TYPE_NONE || gpu_util > 0 ||
          mem_util > 0 || enc_util > 0 || dec_util > 0));

    if (worth_printing) {
      if (mode == MODE_JSON) {
        if (printed_json_count > 0)
          printf(",");
        if (gpu_avail) {
          printf("{\"pid\":%d,\"name\":\"", pid);
          print_json_escaped(comm);
          printf("\",\"cmdline\":\"");
          print_json_escaped(cmdline);
          printf("\",\"cpu_pct\":%.1f,\"ram_mb\":%.2f,\"gpu_type\":\"%s\","
                 "\"vram_mb\":%.2f,\"gpu_pct\":%u,\"mem_pct\":%u,\"enc_pct\":%"
                 "u,\"dec_pct\":%u}",
                 cpu_pct, ram_mb, get_proc_type_str(gpu_type), vram_mb,
                 gpu_util, mem_util, enc_util, dec_util);
        } else {
          printf("{\"pid\":%d,\"name\":\"", pid);
          print_json_escaped(comm);
          printf("\",\"cmdline\":\"");
          print_json_escaped(cmdline);
          printf("\",\"cpu_pct\":%.1f,\"ram_mb\":%.2f}", cpu_pct, ram_mb);
        }
        printed_json_count++;
      } else {
        if (gpu_avail) {
          printf("%-8d %-16.16s %-8.1f %-10.2f %-6s %-10.2f %-8u %-8u %-8u "
                 "%-8u %s\n",
                 pid, comm, cpu_pct, ram_mb, get_proc_type_str(gpu_type),
                 vram_mb, gpu_util, mem_util, enc_util, dec_util, cmdline);
        } else {
          printf("%-8d %-16.16s %-8.1f %-10.2f %s\n", pid, comm, cpu_pct,
                 ram_mb, cmdline);
        }
      }
    }
  }
  closedir(dir);

  if (mode == MODE_JSON) {
    printf("]}\n");
  }

  if (prev_cpu_capacity < next_cpu_count) {
    CpuSnap *tmp = realloc(prev_cpu_snaps, next_cpu_count * sizeof(CpuSnap));
    if (tmp) {
      prev_cpu_snaps = tmp;
      prev_cpu_capacity = next_cpu_count;
    }
  }
  if (prev_cpu_snaps) {
    memcpy(prev_cpu_snaps, next_cpu_snaps, sizeof(CpuSnap) * next_cpu_count);
    prev_cpu_count = next_cpu_count;
  }

  fflush(stdout);
}

int main(int argc, char *argv[]) {
  int interval_ms = 1000;
  OutputMode mode = MODE_TABLE;

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

  signal(SIGINT, handle_signal);
  signal(SIGTERM, handle_signal);

  int num_cores = sysconf(_SC_NPROCESSORS_ONLN);

  init_gpu_system();

  if (mode == MODE_TABLE) {
    if (active_gpu_vendor == GPU_VENDOR_NVIDIA) {
      fprintf(stderr, "Note: Active GPU -> NVIDIA (via NVML)\n");
    } else if (active_gpu_vendor == GPU_VENDOR_AMD) {
      fprintf(stderr,
              "Note: Active GPU -> AMD (via /proc/fdinfo DRM parser)\n");
    } else {
      fprintf(stderr, "Note: No supported GPU found — running CPU/RAM mode.\n");
    }
  }

  useconds_t sleep_us = (useconds_t)interval_ms * 1000;
  unsigned long long prev_sys_ticks = get_system_cpu_ticks();

  struct timespec prev_time, curr_time;
  clock_gettime(CLOCK_MONOTONIC, &prev_time);

  while (keep_running) {
    usleep(sleep_us);

    clock_gettime(CLOCK_MONOTONIC, &curr_time);
    unsigned long long interval_ns =
        (curr_time.tv_sec - prev_time.tv_sec) * 1000000000ULL +
        (curr_time.tv_nsec - prev_time.tv_nsec);
    prev_time = curr_time;

    unsigned long long current_sys_ticks = get_system_cpu_ticks();
    unsigned long long system_ticks_delta = current_sys_ticks - prev_sys_ticks;
    prev_sys_ticks = current_sys_ticks;

    if (active_gpu_vendor == GPU_VENDOR_NVIDIA) {
      fetch_nvidia_gpu_data(nvml_device);
    } else if (active_gpu_vendor == GPU_VENDOR_AMD) {
      fetch_amd_gpu_data(interval_ns);
    }

    track_processes(system_ticks_delta, num_cores, mode, gpu_available);
  }

  if (mode == MODE_TABLE) {
    printf("\nExiting gracefully...\n");
  }

  if (active_gpu_vendor == GPU_VENDOR_NVIDIA && p_nvmlShutdown) {
    p_nvmlShutdown();
  }
  if (nvml_handle) {
    dlclose(nvml_handle);
  }

  free(gpu_procs);
  free(prev_cpu_snaps);
  free(next_cpu_snaps);

  return 0;
}
