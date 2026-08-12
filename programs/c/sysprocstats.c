#include <arpa/inet.h>
#include <ctype.h>
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <ifaddrs.h>
#include <limits.h>
#include <netinet/in.h>
#include <nvml.h>
#include <pwd.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>

#include <linux/wireless.h>

typedef enum {
    GPU_VENDOR_NONE = 0,
    GPU_VENDOR_NVIDIA,
    GPU_VENDOR_AMD
} GpuVendor;

typedef enum {
    PROC_TYPE_NONE     = 0,
    PROC_TYPE_GRAPHICS = (1 << 0),
    PROC_TYPE_COMPUTE  = (1 << 1),
    PROC_TYPE_BOTH     = (PROC_TYPE_GRAPHICS | PROC_TYPE_COMPUTE)
} GpuProcType;

static volatile sig_atomic_t keep_running = 1;

static void handle_signal(int sig) {
    (void)sig;
    keep_running = 0;
}

// Global state
static GpuVendor active_gpu_vendor = GPU_VENDOR_NONE;
static int gpu_available = 0;
static unsigned long long last_seen_nvml_ts = 0;
static unsigned long long prev_rapl_energy_uj = 0;
static unsigned long long cached_max_energy_uj = 0;

// ---------------------------------------------------------------------
// Dynamic NVML Function Pointers
// ---------------------------------------------------------------------
typedef nvmlReturn_t (*nvmlInit_fn)(void);
typedef nvmlReturn_t (*nvmlShutdown_fn)(void);
typedef nvmlReturn_t (*nvmlDeviceGetCount_fn)(unsigned int *);
typedef nvmlReturn_t (*nvmlDeviceGetHandleByIndex_fn)(unsigned int, nvmlDevice_t *);
typedef nvmlReturn_t (*nvmlDeviceGetName_fn)(nvmlDevice_t, char *, unsigned int);
typedef nvmlReturn_t (*nvmlDeviceGetTemperature_fn)(nvmlDevice_t, nvmlTemperatureSensors_t, unsigned int *);
typedef nvmlReturn_t (*nvmlDeviceGetUtilizationRates_fn)(nvmlDevice_t, nvmlUtilization_t *);
typedef nvmlReturn_t (*nvmlDeviceGetEncoderUtilization_fn)(nvmlDevice_t, unsigned int *, unsigned int *);
typedef nvmlReturn_t (*nvmlDeviceGetDecoderUtilization_fn)(nvmlDevice_t, unsigned int *, unsigned int *);
typedef nvmlReturn_t (*nvmlDeviceGetMemoryInfo_fn)(nvmlDevice_t, nvmlMemory_t *);
typedef nvmlReturn_t (*nvmlDeviceGetClockInfo_fn)(nvmlDevice_t, nvmlClockType_t, unsigned int *);
typedef nvmlReturn_t (*nvmlDeviceGetMaxClockInfo_fn)(nvmlDevice_t, nvmlClockType_t, unsigned int *);
typedef nvmlReturn_t (*nvmlDeviceGetNumGpuCores_fn)(nvmlDevice_t, unsigned int *);
typedef nvmlReturn_t (*nvmlDeviceGetPowerUsage_fn)(nvmlDevice_t, unsigned int *);
typedef nvmlReturn_t (*nvmlDeviceGetEnforcedPowerLimit_fn)(nvmlDevice_t, unsigned int *);
typedef nvmlReturn_t (*nvmlDeviceGetGraphicsRunningProcesses_fn)(nvmlDevice_t, unsigned int *, nvmlProcessInfo_t *);
typedef nvmlReturn_t (*nvmlDeviceGetComputeRunningProcesses_fn)(nvmlDevice_t, unsigned int *, nvmlProcessInfo_t *);
typedef nvmlReturn_t (*nvmlDeviceGetProcessUtilization_fn)(nvmlDevice_t, nvmlProcessUtilizationSample_t *, unsigned int *, unsigned long long);

static void *nvml_handle = NULL;
static nvmlInit_fn p_nvmlInit = NULL;
static nvmlShutdown_fn p_nvmlShutdown = NULL;
static nvmlDeviceGetCount_fn p_nvmlDeviceGetCount = NULL;
static nvmlDeviceGetHandleByIndex_fn p_nvmlDeviceGetHandleByIndex = NULL;
static nvmlDeviceGetName_fn p_nvmlDeviceGetName = NULL;
static nvmlDeviceGetTemperature_fn p_nvmlDeviceGetTemperature = NULL;
static nvmlDeviceGetUtilizationRates_fn p_nvmlDeviceGetUtilizationRates = NULL;
static nvmlDeviceGetEncoderUtilization_fn p_nvmlDeviceGetEncoderUtilization = NULL;
static nvmlDeviceGetDecoderUtilization_fn p_nvmlDeviceGetDecoderUtilization = NULL;
static nvmlDeviceGetMemoryInfo_fn p_nvmlDeviceGetMemoryInfo = NULL;
static nvmlDeviceGetClockInfo_fn p_nvmlDeviceGetClockInfo = NULL;
static nvmlDeviceGetMaxClockInfo_fn p_nvmlDeviceGetMaxClockInfo = NULL;
static nvmlDeviceGetNumGpuCores_fn p_nvmlDeviceGetNumGpuCores = NULL;
static nvmlDeviceGetPowerUsage_fn p_nvmlDeviceGetPowerUsage = NULL;
static nvmlDeviceGetEnforcedPowerLimit_fn p_nvmlDeviceGetEnforcedPowerLimit = NULL;
static nvmlDeviceGetGraphicsRunningProcesses_fn p_nvmlDeviceGetGraphicsRunningProcesses = NULL;
static nvmlDeviceGetComputeRunningProcesses_fn p_nvmlDeviceGetComputeRunningProcesses = NULL;
static nvmlDeviceGetProcessUtilization_fn p_nvmlDeviceGetProcessUtilization = NULL;
static nvmlDevice_t nvml_device_0;

static void *resolve_symbol(const char *names[], int count) {
    for (int i = 0; i < count; i++) {
        void *sym = dlsym(nvml_handle, names[i]);
        if (sym) return sym;
    }
    return NULL;
}

static int init_nvml_dynamic(void) {
    nvml_handle = dlopen("libnvidia-ml.so.1", RTLD_NOW);
    if (!nvml_handle) {
        nvml_handle = dlopen("libnvidia-ml.so", RTLD_NOW);
        if (!nvml_handle) return 0;
    }

    p_nvmlInit = (nvmlInit_fn)resolve_symbol((const char *[]){"nvmlInit_v2", "nvmlInit"}, 2);
    p_nvmlShutdown = (nvmlShutdown_fn)resolve_symbol((const char *[]){"nvmlShutdown"}, 1);
    p_nvmlDeviceGetCount = (nvmlDeviceGetCount_fn)resolve_symbol((const char *[]){"nvmlDeviceGetCount_v2", "nvmlDeviceGetCount"}, 2);
    p_nvmlDeviceGetHandleByIndex = (nvmlDeviceGetHandleByIndex_fn)resolve_symbol((const char *[]){"nvmlDeviceGetHandleByIndex_v2", "nvmlDeviceGetHandleByIndex"}, 2);
    p_nvmlDeviceGetName = (nvmlDeviceGetName_fn)resolve_symbol((const char *[]){"nvmlDeviceGetName"}, 1);
    p_nvmlDeviceGetTemperature = (nvmlDeviceGetTemperature_fn)resolve_symbol((const char *[]){"nvmlDeviceGetTemperature"}, 1);
    p_nvmlDeviceGetUtilizationRates = (nvmlDeviceGetUtilizationRates_fn)resolve_symbol((const char *[]){"nvmlDeviceGetUtilizationRates"}, 1);
    p_nvmlDeviceGetEncoderUtilization = (nvmlDeviceGetEncoderUtilization_fn)resolve_symbol((const char *[]){"nvmlDeviceGetEncoderUtilization"}, 1);
    p_nvmlDeviceGetDecoderUtilization = (nvmlDeviceGetDecoderUtilization_fn)resolve_symbol((const char *[]){"nvmlDeviceGetDecoderUtilization"}, 1);
    p_nvmlDeviceGetMemoryInfo = (nvmlDeviceGetMemoryInfo_fn)resolve_symbol((const char *[]){"nvmlDeviceGetMemoryInfo"}, 1);
    p_nvmlDeviceGetClockInfo = (nvmlDeviceGetClockInfo_fn)resolve_symbol((const char *[]){"nvmlDeviceGetClockInfo"}, 1);
    p_nvmlDeviceGetMaxClockInfo = (nvmlDeviceGetMaxClockInfo_fn)resolve_symbol((const char *[]){"nvmlDeviceGetMaxClockInfo"}, 1);
    p_nvmlDeviceGetNumGpuCores = (nvmlDeviceGetNumGpuCores_fn)resolve_symbol((const char *[]){"nvmlDeviceGetNumGpuCores"}, 1);
    p_nvmlDeviceGetPowerUsage = (nvmlDeviceGetPowerUsage_fn)resolve_symbol((const char *[]){"nvmlDeviceGetPowerUsage"}, 1);
    p_nvmlDeviceGetEnforcedPowerLimit = (nvmlDeviceGetEnforcedPowerLimit_fn)resolve_symbol((const char *[]){"nvmlDeviceGetEnforcedPowerLimit"}, 1);
    p_nvmlDeviceGetGraphicsRunningProcesses = (nvmlDeviceGetGraphicsRunningProcesses_fn)resolve_symbol((const char *[]){"nvmlDeviceGetGraphicsRunningProcesses_v3", "nvmlDeviceGetGraphicsRunningProcesses_v2", "nvmlDeviceGetGraphicsRunningProcesses"}, 3);
    p_nvmlDeviceGetComputeRunningProcesses = (nvmlDeviceGetComputeRunningProcesses_fn)resolve_symbol((const char *[]){"nvmlDeviceGetComputeRunningProcesses_v3", "nvmlDeviceGetComputeRunningProcesses_v2", "nvmlDeviceGetComputeRunningProcesses"}, 3);
    p_nvmlDeviceGetProcessUtilization = (nvmlDeviceGetProcessUtilization_fn)resolve_symbol((const char *[]){"nvmlDeviceGetProcessUtilization"}, 1);

    if (!p_nvmlInit || p_nvmlInit() != NVML_SUCCESS) {
        dlclose(nvml_handle);
        nvml_handle = NULL;
        return 0;
    }

    if (p_nvmlDeviceGetHandleByIndex && p_nvmlDeviceGetHandleByIndex(0, &nvml_device_0) != NVML_SUCCESS) {
        p_nvmlShutdown();
        dlclose(nvml_handle);
        nvml_handle = NULL;
        return 0;
    }

    return 1;
}

static int detect_amd_gpu(void) {
    DIR *dir = opendir("/sys/class/drm");
    if (!dir) return 0;

    struct dirent *entry;
    int found = 0;
    while ((entry = readdir(dir)) != NULL) {
        if (strncmp(entry->d_name, "card", 4) == 0 && !strchr(entry->d_name, '-')) {
            char path[256];
            snprintf(path, sizeof(path), "/sys/class/drm/%s/device/vendor", entry->d_name);
            FILE *f = fopen(path, "r");
            if (f) {
                char vendor[32];
                if (fgets(vendor, sizeof(vendor), f) && strstr(vendor, "0x1002")) {
                    found = 1;
                    fclose(f);
                    break;
                }
                fclose(f);
            }
        }
    }
    closedir(dir);
    return found;
}

static void init_gpu_system(void) {
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

// Helpers
static void trim_str(char *s) {
    size_t len = strlen(s);
    while (len > 0 && (s[len - 1] == '\n' || s[len - 1] == '\r' || s[len - 1] == ' ' || s[len - 1] == '\t')) {
        s[--len] = '\0';
    }
}

static void print_json_escaped(const char *str) {
    for (const char *p = str; *p; p++) {
        switch (*p) {
            case '"':  fputs("\\\"", stdout); break;
            case '\\': fputs("\\\\", stdout); break;
            case '\b': fputs("\\b", stdout); break;
            case '\f': fputs("\\f", stdout); break;
            case '\n': fputs("\\n", stdout); break;
            case '\r': fputs("\\r", stdout); break;
            case '\t': fputs("\\t", stdout); break;
            default:
                if ((unsigned char)*p < 0x20) printf("\\u%04x", (unsigned char)*p);
                else putchar(*p);
                break;
        }
    }
}

static int read_sys_file(const char *path, char *out, size_t max_len) {
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    if (fgets(out, max_len, f)) {
        trim_str(out);
        fclose(f);
        return 1;
    }
    fclose(f);
    return 0;
}

static void fetch_drm_gpu_clocks(const char *card_name, double *cur_freq_mhz, double *max_freq_mhz) {
    char path[256], buf[256];

    snprintf(path, sizeof(path), "/sys/class/drm/%s/device/hwmon", card_name);
    DIR *hdir = opendir(path);
    if (hdir) {
        struct dirent *he;
        while ((he = readdir(hdir)) != NULL) {
            if (strncmp(he->d_name, "hwmon", 5) == 0) {
                char fpath[256];
                snprintf(fpath, sizeof(fpath), "/sys/class/drm/%s/device/hwmon/%s/freq1_input", card_name, he->d_name);
                if (read_sys_file(fpath, buf, sizeof(buf))) {
                    double hz = atof(buf);
                    if (hz > 0) *cur_freq_mhz = hz / 1000000.0;
                }
                break;
            }
        }
        closedir(hdir);
    }

    snprintf(path, sizeof(path), "/sys/class/drm/%s/device/pp_dpm_sclk", card_name);
    FILE *f = fopen(path, "r");
    if (f) {
        char line[256];
        double highest = 0;
        while (fgets(line, sizeof(line), f)) {
            double freq = 0;
            if (sscanf(line, "%*d: %lfMhz", &freq) == 1 || sscanf(line, "%*d: %lfMHz", &freq) == 1) {
                if (freq > highest) highest = freq;
                if (strstr(line, "*") && *cur_freq_mhz == 0) {
                    *cur_freq_mhz = freq;
                }
            }
        }
        fclose(f);
        if (highest > 0) *max_freq_mhz = highest;
    }

    if (*cur_freq_mhz == 0) {
        snprintf(path, sizeof(path), "/sys/class/drm/%s/gt_act_freq_mhz", card_name);
        if (read_sys_file(path, buf, sizeof(buf))) *cur_freq_mhz = atof(buf);
    }
    if (*max_freq_mhz == 0) {
        snprintf(path, sizeof(path), "/sys/class/drm/%s/gt_max_freq_mhz", card_name);
        if (read_sys_file(path, buf, sizeof(buf))) *max_freq_mhz = atof(buf);
    }
}

static void fetch_drm_gpu_mem_clocks(const char *card_name, double *cur_mem_freq_mhz, double *max_mem_freq_mhz) {
    char path[256], buf[256];

    snprintf(path, sizeof(path), "/sys/class/drm/%s/device/hwmon", card_name);
    DIR *hdir = opendir(path);
    if (hdir) {
        struct dirent *he;
        while ((he = readdir(hdir)) != NULL) {
            if (strncmp(he->d_name, "hwmon", 5) == 0) {
                char fpath[256];
                snprintf(fpath, sizeof(fpath), "/sys/class/drm/%s/device/hwmon/%s/freq2_input", card_name, he->d_name);
                if (read_sys_file(fpath, buf, sizeof(buf))) {
                    double hz = atof(buf);
                    if (hz > 0) *cur_mem_freq_mhz = hz / 1000000.0;
                }
                break;
            }
        }
        closedir(hdir);
    }

    snprintf(path, sizeof(path), "/sys/class/drm/%s/device/pp_dpm_mclk", card_name);
    FILE *f = fopen(path, "r");
    if (f) {
        char line[256];
        double highest = 0;
        while (fgets(line, sizeof(line), f)) {
            double freq = 0;
            if (sscanf(line, "%*d: %lfMhz", &freq) == 1 || sscanf(line, "%*d: %lfMHz", &freq) == 1) {
                if (freq > highest) highest = freq;
                if (strstr(line, "*") && *cur_mem_freq_mhz == 0) {
                    *cur_mem_freq_mhz = freq;
                }
            }
        }
        fclose(f);
        if (highest > 0) *max_mem_freq_mhz = highest;
    }
}

// ---------------------------------------------------------------------
// System Info Data Structures & Fetchers
// ---------------------------------------------------------------------
typedef struct {
    char username[64];
    char hostname[256];
    char os_name[128];
    char arch[32];
    char kernel[128];
    double uptime_sec;
    char wm[64];
    char board_name[256];
} SystemMeta;

static void fetch_system_meta(SystemMeta *m) {
    memset(m, 0, sizeof(SystemMeta));
    struct passwd *pw = getpwuid(geteuid());
    snprintf(m->username, sizeof(m->username), "%s", pw ? pw->pw_name : (getenv("USER") ? getenv("USER") : "user"));
    gethostname(m->hostname, sizeof(m->hostname));

    FILE *f = fopen("/etc/os-release", "r");
    snprintf(m->os_name, sizeof(m->os_name), "Linux");
    if (f) {
        char line[256];
        while (fgets(line, sizeof(line), f)) {
            if (strncmp(line, "PRETTY_NAME=", 12) == 0) {
                char *val = line + 12;
                if (*val == '"') val++;
                snprintf(m->os_name, sizeof(m->os_name), "%s", val);
                trim_str(m->os_name);
                size_t len = strlen(m->os_name);
                if (len > 0 && m->os_name[len - 1] == '"') {
                    m->os_name[len - 1] = '\0';
                }
                break;
            }
        }
        fclose(f);
    }

    struct utsname uts;
    if (uname(&uts) == 0) {
        snprintf(m->arch, sizeof(m->arch), "%s", uts.machine);
        snprintf(m->kernel, sizeof(m->kernel), "%s", uts.release);
    }

    FILE *fup = fopen("/proc/uptime", "r");
    if (fup) {
        fscanf(fup, "%lf", &m->uptime_sec);
        fclose(fup);
    }

    const char *xdg_wm = getenv("XDG_CURRENT_DESKTOP");
    snprintf(m->wm, sizeof(m->wm), "%s", xdg_wm ? xdg_wm : "Unknown");

    char vendor[128] = "", board[128] = "";
    read_sys_file("/sys/class/dmi/id/board_vendor", vendor, sizeof(vendor));
    read_sys_file("/sys/class/dmi/id/board_name", board, sizeof(board));
    if (strlen(board) > 0) snprintf(m->board_name, sizeof(m->board_name), "%s %s", vendor, board);
    else snprintf(m->board_name, sizeof(m->board_name), "Motherboard");
}

typedef struct {
    unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
} CpuTicks;

typedef struct {
    char model[128];
    int cores;
    int threads;
    double cur_freq_mhz;
    double max_freq_mhz;
    double temp_c;
    double power_w;
    double power_max_w;
    int rapl_restricted;
    double total_usage_pct;
    int num_core_stats;
    double *core_usage_pct;
} CpuInfo;

static CpuTicks *prev_sys_cpu_ticks = NULL;
static int prev_sys_cpu_count = 0;

static double fetch_cpu_max_power(void) {
    char buf[64];
    const char *rapl_paths[] = {
        "/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw",
        "/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw",
        "/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_max_power_uw"
    };

    for (size_t i = 0; i < sizeof(rapl_paths) / sizeof(rapl_paths[0]); i++) {
        if (access(rapl_paths[i], R_OK) == 0 && read_sys_file(rapl_paths[i], buf, sizeof(buf))) {
            double watts = atof(buf) / 1000000.0;
            if (watts > 0) return watts;
        }
    }

    DIR *dir = opendir("/sys/class/hwmon");
    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (strncmp(entry->d_name, "hwmon", 5) == 0) {
                char name_path[256], name[64] = "";
                snprintf(name_path, sizeof(name_path), "/sys/class/hwmon/%s/name", entry->d_name);
                read_sys_file(name_path, name, sizeof(name));

                if (strstr(name, "coretemp") || strstr(name, "k10temp") || strstr(name, "zenpower") || strstr(name, "cpu")) {
                    char cap_path[256];
                    snprintf(cap_path, sizeof(cap_path), "/sys/class/hwmon/%s/power1_cap_max", entry->d_name);
                    if (!read_sys_file(cap_path, buf, sizeof(buf))) {
                        snprintf(cap_path, sizeof(cap_path), "/sys/class/hwmon/%s/power1_cap", entry->d_name);
                        read_sys_file(cap_path, buf, sizeof(buf));
                    }

                    if (buf[0] != '\0') {
                        double watts = atof(buf) / 1000000.0;
                        if (watts > 0) {
                            closedir(dir);
                            return watts;
                        }
                    }
                }
            }
        }
        closedir(dir);
    }

    return 0.0;
}

static void fetch_cpu_info(CpuInfo *cpu, double interval_sec, unsigned long long *out_sys_ticks_delta) {
    memset(cpu, 0, sizeof(CpuInfo));
    *out_sys_ticks_delta = 0;

    FILE *f = fopen("/proc/cpuinfo", "r");
    if (f) {
        char line[256];
        int parsed_cores = 0;
        while (fgets(line, sizeof(line), f)) {
            if (strncmp(line, "model name", 10) == 0 && cpu->model[0] == '\0') {
                char *colon = strchr(line, ':');
                if (colon) {
                    snprintf(cpu->model, sizeof(cpu->model), "%s", colon + 2);
                    trim_str(cpu->model);
                }
            } else if (strncmp(line, "cpu cores", 9) == 0 && parsed_cores == 0) {
                sscanf(line, "cpu cores : %d", &parsed_cores);
            }
        }
        fclose(f);
        cpu->cores = (parsed_cores > 0) ? parsed_cores : (int)sysconf(_SC_NPROCESSORS_ONLN) / 2;
    }
    cpu->threads = (int)sysconf(_SC_NPROCESSORS_ONLN);

    double sum_freq = 0, max_boost = 0;
    int freq_count = 0;
    for (int i = 0; i < cpu->threads; i++) {
        char path[256], buf[64];
        snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%d/cpufreq/scaling_cur_freq", i);
        if (read_sys_file(path, buf, sizeof(buf))) {
            sum_freq += atof(buf) / 1000.0;
            freq_count++;
        }
        snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_max_freq", i);
        if (read_sys_file(path, buf, sizeof(buf))) {
            double freq = atof(buf) / 1000.0;
            if (freq > max_boost) max_boost = freq;
        }
    }
    cpu->cur_freq_mhz = (freq_count > 0) ? (sum_freq / freq_count) : 0;
    cpu->max_freq_mhz = max_boost;

    DIR *dir = opendir("/sys/class/hwmon");
    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (strncmp(entry->d_name, "hwmon", 5) == 0) {
                char path[256], name[64] = "";
                snprintf(path, sizeof(path), "/sys/class/hwmon/%s/name", entry->d_name);
                read_sys_file(path, name, sizeof(name));
                if (strstr(name, "coretemp") || strstr(name, "k10temp") || strstr(name, "zenpower") || strstr(name, "cpu")) {
                    snprintf(path, sizeof(path), "/sys/class/hwmon/%s/temp1_input", entry->d_name);
                    char tbuf[32];
                    if (read_sys_file(path, tbuf, sizeof(tbuf))) cpu->temp_c = atof(tbuf) / 1000.0;

                    snprintf(path, sizeof(path), "/sys/class/hwmon/%s/power1_input", entry->d_name);
                    if (!read_sys_file(path, tbuf, sizeof(tbuf))) {
                        snprintf(path, sizeof(path), "/sys/class/hwmon/%s/power1_average", entry->d_name);
                        read_sys_file(path, tbuf, sizeof(tbuf));
                    }
                    if (tbuf[0] != '\0') cpu->power_w = atof(tbuf) / 1000000.0;

                    if (cpu->temp_c > 0) break;
                }
            }
        }
        closedir(dir);
    }

    const char *rapl_dir = "/sys/class/powercap/intel-rapl";
    const char *rapl_path = "/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj";

    int dir_check = access(rapl_dir, F_OK);
    if (dir_check == 0 || errno == EACCES) {
        if (access(rapl_path, R_OK) == 0) {
            cpu->rapl_restricted = 0;
            char buf[64];

            if (cached_max_energy_uj == 0) {
                if (read_sys_file("/sys/class/powercap/intel-rapl/intel-rapl:0/max_energy_range_uj", buf, sizeof(buf))) {
                    cached_max_energy_uj = strtoull(buf, NULL, 10);
                }
            }

            if (interval_sec > 0 && read_sys_file(rapl_path, buf, sizeof(buf))) {
                unsigned long long curr_energy_uj = strtoull(buf, NULL, 10);

                if (prev_rapl_energy_uj > 0) {
                    unsigned long long delta_uj = 0;
                    if (curr_energy_uj >= prev_rapl_energy_uj) {
                        delta_uj = curr_energy_uj - prev_rapl_energy_uj;
                    } else if (cached_max_energy_uj > 0) {
                        delta_uj = (cached_max_energy_uj - prev_rapl_energy_uj) + curr_energy_uj;
                    }
                    cpu->power_w = (double)delta_uj / (interval_sec * 1000000.0);
                }
                prev_rapl_energy_uj = curr_energy_uj;
            }
        } else {
            cpu->rapl_restricted = 1;
        }
    } else {
        cpu->rapl_restricted = 0;
    }

    cpu->power_max_w = fetch_cpu_max_power();

    f = fopen("/proc/stat", "r");
    if (f) {
        char line[256];
        CpuTicks current_ticks[256];
        int num_cpus = 0;

        while (fgets(line, sizeof(line), f)) {
            if (strncmp(line, "cpu", 3) == 0) {
                CpuTicks t;
                char cpu_name[16];
                sscanf(line, "%s %llu %llu %llu %llu %llu %llu %llu %llu",
                       cpu_name, &t.user, &t.nice, &t.system, &t.idle, &t.iowait, &t.irq, &t.softirq, &t.steal);
                current_ticks[num_cpus++] = t;
                if (num_cpus >= 256) break;
            }
        }
        fclose(f);

        if (prev_sys_cpu_ticks && prev_sys_cpu_count == num_cpus) {
            cpu->num_core_stats = num_cpus - 1;
            cpu->core_usage_pct = calloc(cpu->num_core_stats > 0 ? cpu->num_core_stats : 1, sizeof(double));
            for (int i = 0; i < num_cpus; i++) {
                CpuTicks p = prev_sys_cpu_ticks[i];
                CpuTicks c = current_ticks[i];

                unsigned long long prev_idle = p.idle + p.iowait;
                unsigned long long curr_idle = c.idle + c.iowait;
                unsigned long long prev_total = prev_idle + p.user + p.nice + p.system + p.irq + p.softirq + p.steal;
                unsigned long long curr_total = curr_idle + c.user + c.nice + c.system + c.irq + c.softirq + c.steal;

                unsigned long long totald = curr_total - prev_total;
                unsigned long long idled = curr_idle - prev_idle;

                double pct = (totald > 0) ? ((double)(totald - idled) / totald) * 100.0 : 0.0;
                if (i == 0) {
                    cpu->total_usage_pct = pct;
                    *out_sys_ticks_delta = totald;
                } else if (i - 1 < cpu->num_core_stats) {
                    cpu->core_usage_pct[i - 1] = pct;
                }
            }
        }

        if (prev_sys_cpu_count != num_cpus) {
            prev_sys_cpu_ticks = realloc(prev_sys_cpu_ticks, num_cpus * sizeof(CpuTicks));
            prev_sys_cpu_count = num_cpus;
        }
        memcpy(prev_sys_cpu_ticks, current_ticks, num_cpus * sizeof(CpuTicks));
    }
}

typedef struct {
    char name[128];
    char type[32];
    double cur_freq_mhz;
    double max_freq_mhz;
    double cur_mem_freq_mhz;
    double max_mem_freq_mhz;
    double temp_c;
    double power_cur_w;
    double power_max_w;
    unsigned int gpu_util_pct;
    unsigned int mem_util_pct;
    unsigned int enc_util_pct;
    unsigned int dec_util_pct;
    unsigned int cores;
    unsigned long long vram_total_bytes;
    unsigned long long vram_used_bytes;
} GpuInfo;

static int fetch_system_gpus(GpuInfo **gpus_out) {
    int count = 0;
    GpuInfo *gpus = NULL;

    if (nvml_handle && p_nvmlDeviceGetCount) {
        unsigned int nv_count = 0;
        if (p_nvmlDeviceGetCount(&nv_count) == NVML_SUCCESS) {
            for (unsigned int i = 0; i < nv_count; i++) {
                nvmlDevice_t dev;
                if (p_nvmlDeviceGetHandleByIndex(i, &dev) == NVML_SUCCESS) {
                    gpus = realloc(gpus, (count + 1) * sizeof(GpuInfo));
                    GpuInfo *g = &gpus[count++];
                    memset(g, 0, sizeof(GpuInfo));

                    p_nvmlDeviceGetName(dev, g->name, sizeof(g->name));
                    snprintf(g->type, sizeof(g->type), "Discrete");

                    unsigned int temp = 0;
                    if (p_nvmlDeviceGetTemperature) p_nvmlDeviceGetTemperature(dev, NVML_TEMPERATURE_GPU, &temp);
                    g->temp_c = temp;

                    unsigned int p_cur = 0, p_limit = 0;
                    if (p_nvmlDeviceGetPowerUsage && p_nvmlDeviceGetPowerUsage(dev, &p_cur) == NVML_SUCCESS) {
                        g->power_cur_w = p_cur / 1000.0;
                    }
                    if (p_nvmlDeviceGetEnforcedPowerLimit && p_nvmlDeviceGetEnforcedPowerLimit(dev, &p_limit) == NVML_SUCCESS) {
                        g->power_max_w = p_limit / 1000.0;
                    }

                    nvmlUtilization_t util;
                    if (p_nvmlDeviceGetUtilizationRates && p_nvmlDeviceGetUtilizationRates(dev, &util) == NVML_SUCCESS) {
                        g->gpu_util_pct = util.gpu;
                        g->mem_util_pct = util.memory;
                    }

                    unsigned int enc = 0, dec = 0, sample = 0;
                    if (p_nvmlDeviceGetEncoderUtilization) p_nvmlDeviceGetEncoderUtilization(dev, &enc, &sample);
                    if (p_nvmlDeviceGetDecoderUtilization) p_nvmlDeviceGetDecoderUtilization(dev, &dec, &sample);
                    g->enc_util_pct = enc;
                    g->dec_util_pct = dec;

                    nvmlMemory_t mem;
                    if (p_nvmlDeviceGetMemoryInfo && p_nvmlDeviceGetMemoryInfo(dev, &mem) == NVML_SUCCESS) {
                        g->vram_total_bytes = mem.total;
                        g->vram_used_bytes = mem.used;
                    }

                    unsigned int clock = 0, max_clock = 0;
                    if (p_nvmlDeviceGetClockInfo) p_nvmlDeviceGetClockInfo(dev, NVML_CLOCK_GRAPHICS, &clock);
                    if (p_nvmlDeviceGetMaxClockInfo) p_nvmlDeviceGetMaxClockInfo(dev, NVML_CLOCK_GRAPHICS, &max_clock);
                    g->cur_freq_mhz = clock;
                    g->max_freq_mhz = max_clock;

                    unsigned int mem_clock = 0, max_mem_clock = 0;
                    if (p_nvmlDeviceGetClockInfo) p_nvmlDeviceGetClockInfo(dev, NVML_CLOCK_MEM, &mem_clock);
                    if (p_nvmlDeviceGetMaxClockInfo) p_nvmlDeviceGetMaxClockInfo(dev, NVML_CLOCK_MEM, &max_mem_clock);
                    g->cur_mem_freq_mhz = mem_clock;
                    g->max_mem_freq_mhz = max_mem_clock;

                    unsigned int cores = 0;
                    if (p_nvmlDeviceGetNumGpuCores) p_nvmlDeviceGetNumGpuCores(dev, &cores);
                    g->cores = cores;
                }
            }
        }
    }

    DIR *dir = opendir("/sys/class/drm");
    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (strncmp(entry->d_name, "card", 4) == 0 && !strchr(entry->d_name, '-')) {
                char path[256], buf[128];
                snprintf(path, sizeof(path), "/sys/class/drm/%s/device/vendor", entry->d_name);
                if (!read_sys_file(path, buf, sizeof(buf)) || strstr(buf, "0x10de")) continue;

                gpus = realloc(gpus, (count + 1) * sizeof(GpuInfo));
                GpuInfo *g = &gpus[count++];
                memset(g, 0, sizeof(GpuInfo));

                int is_amd = strstr(buf, "0x1002") != NULL;
                int is_intel = strstr(buf, "0x8086") != NULL;

                snprintf(path, sizeof(path), "/sys/class/drm/%s/device/product_name", entry->d_name);
                if (!read_sys_file(path, g->name, sizeof(g->name))) {
                    snprintf(g->name, sizeof(g->name), "%s GPU", is_amd ? "AMD" : (is_intel ? "Intel" : "Generic"));
                }

                snprintf(path, sizeof(path), "/sys/class/drm/%s/device/pcie_bw", entry->d_name);
                struct stat st_pcie;
                int has_pcie_bw = (stat(path, &st_pcie) == 0);

                int is_integrated = !has_pcie_bw;
                if (strstr(g->name, "Graphics") || strstr(g->name, "Vega") || strstr(g->name, "780M") ||
                    strstr(g->name, "680M") || strstr(g->name, "610M") || strstr(g->name, "Intel") ||
                    strstr(g->name, "UHD") || strstr(g->name, "Iris")) {
                    is_integrated = 1;
                }
                snprintf(g->type, sizeof(g->type), is_integrated ? "Integrated" : "Discrete");

                fetch_drm_gpu_clocks(entry->d_name, &g->cur_freq_mhz, &g->max_freq_mhz);
                fetch_drm_gpu_mem_clocks(entry->d_name, &g->cur_mem_freq_mhz, &g->max_mem_freq_mhz);

                snprintf(path, sizeof(path), "/sys/class/drm/%s/device/hwmon", entry->d_name);
                DIR *hdir = opendir(path);
                if (hdir) {
                    struct dirent *he;
                    while ((he = readdir(hdir)) != NULL) {
                        if (strncmp(he->d_name, "hwmon", 5) == 0) {
                            char tpath[256], tbuf[32];
                            snprintf(tpath, sizeof(tpath), "/sys/class/drm/%s/device/hwmon/%s/temp1_input", entry->d_name, he->d_name);
                            if (read_sys_file(tpath, tbuf, sizeof(tbuf))) g->temp_c = atof(tbuf) / 1000.0;

                            snprintf(tpath, sizeof(tpath), "/sys/class/drm/%s/device/hwmon/%s/power1_average", entry->d_name, he->d_name);
                            if (!read_sys_file(tpath, tbuf, sizeof(tbuf))) {
                                snprintf(tpath, sizeof(tpath), "/sys/class/drm/%s/device/hwmon/%s/power1_input", entry->d_name, he->d_name);
                                read_sys_file(tpath, tbuf, sizeof(tbuf));
                            }
                            if (tbuf[0] != '\0') g->power_cur_w = atof(tbuf) / 1000000.0;

                            snprintf(tpath, sizeof(path), "/sys/class/drm/%s/device/hwmon/%s/power1_cap", entry->d_name, he->d_name);
                            if (read_sys_file(tpath, tbuf, sizeof(tbuf))) g->power_max_w = atof(tbuf) / 1000000.0;

                            break;
                        }
                    }
                    closedir(hdir);
                }

                snprintf(path, sizeof(path), "/sys/class/drm/%s/device/mem_info_vram_total", entry->d_name);
                if (read_sys_file(path, buf, sizeof(buf))) g->vram_total_bytes = strtoull(buf, NULL, 10);
                snprintf(path, sizeof(path), "/sys/class/drm/%s/device/mem_info_vram_used", entry->d_name);
                if (read_sys_file(path, buf, sizeof(buf))) g->vram_used_bytes = strtoull(buf, NULL, 10);

                snprintf(path, sizeof(path), "/sys/class/drm/%s/device/gpu_busy_percent", entry->d_name);
                if (read_sys_file(path, buf, sizeof(buf))) g->gpu_util_pct = atoi(buf);
            }
        }
        closedir(dir);
    }

    *gpus_out = gpus;
    return count;
}

typedef struct {
    unsigned long long ram_total_bytes;
    unsigned long long ram_used_bytes;
    unsigned long long swap_total_bytes;
    unsigned long long swap_used_bytes;
} MemInfo;

static void fetch_memory(MemInfo *m) {
    memset(m, 0, sizeof(MemInfo));
    FILE *f = fopen("/proc/meminfo", "r");
    if (!f) return;

    char line[256];
    unsigned long long total = 0, avail = 0, stotal = 0, sfree = 0;
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "MemTotal:", 9) == 0) sscanf(line, "MemTotal: %llu kB", &total);
        else if (strncmp(line, "MemAvailable:", 13) == 0) sscanf(line, "MemAvailable: %llu kB", &avail);
        else if (strncmp(line, "SwapTotal:", 10) == 0) sscanf(line, "SwapTotal: %llu kB", &stotal);
        else if (strncmp(line, "SwapFree:", 9) == 0) sscanf(line, "SwapFree: %llu kB", &sfree);
    }
    fclose(f);

    m->ram_total_bytes = total * 1024ULL;
    m->ram_used_bytes = (total - avail) * 1024ULL;
    m->swap_total_bytes = stotal * 1024ULL;
    m->swap_used_bytes = (stotal - sfree) * 1024ULL;
}

typedef struct {
    char name[128];
    char label[128];
    char mountpoint[256];
    char filesystem[64];
    unsigned long long total_bytes;
    unsigned long long used_bytes;
} DiskInfo;

static void decode_udev_name(char *str) {
    char *p = str, *q = str;
    while (*p) {
        if (*p == '\\' && *(p + 1) == 'x' && isxdigit((unsigned char)*(p + 2)) && isxdigit((unsigned char)*(p + 3))) {
            char hex[3] = { *(p + 2), *(p + 3), '\0' };
            *q++ = (char)strtol(hex, NULL, 16);
            p += 4;
        } else {
            *q++ = *p++;
        }
    }
    *q = '\0';
}

static void get_disk_label(const char *dev_path, char *out_label, size_t max_len) {
    out_label[0] = '\0';
    DIR *dir = opendir("/dev/disk/by-label");
    if (!dir) return;

    char target_real[PATH_MAX];
    if (!realpath(dev_path, target_real)) snprintf(target_real, sizeof(target_real), "%s", dev_path);

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.') continue;
        char link_path[512], resolved[PATH_MAX];
        snprintf(link_path, sizeof(link_path), "/dev/disk/by-label/%s", entry->d_name);
        if (realpath(link_path, resolved) && strcmp(resolved, target_real) == 0) {
            snprintf(out_label, max_len, "%s", entry->d_name);
            decode_udev_name(out_label);
            break;
        }
    }
    closedir(dir);
}

static int fetch_disks(DiskInfo **disks_out) {
    FILE *f = fopen("/proc/mounts", "r");
    if (!f) return 0;

    char line[512];
    int count = 0;
    DiskInfo *disks = NULL;

    while (fgets(line, sizeof(line), f)) {
        char dev[256], mount[256], fstype[64];
        if (sscanf(line, "%255s %255s %63s", dev, mount, fstype) == 3) {
            if (strncmp(dev, "/dev/", 5) == 0 && !strstr(dev, "loop")) {
                struct statvfs vfs;
                if (statvfs(mount, &vfs) == 0 && vfs.f_blocks > 0) {
                    disks = realloc(disks, (count + 1) * sizeof(DiskInfo));
                    DiskInfo *d = &disks[count++];
                    memset(d, 0, sizeof(DiskInfo));

                    char label[128] = "";
                    get_disk_label(dev, label, sizeof(label));

                    if (label[0] == '\0') {
                        if (strcmp(mount, "/") == 0) snprintf(label, sizeof(label), "ROOT");
                        else {
                            const char *last_slash = strrchr(mount, '/');
                            if (last_slash && strlen(last_slash + 1) > 0) snprintf(label, sizeof(label), "%s", last_slash + 1);
                            else snprintf(label, sizeof(label), "%s", dev);
                        }
                    }

                    snprintf(d->name, sizeof(d->name), "%s", dev);
                    snprintf(d->label, sizeof(d->label), "%s", label);
                    snprintf(d->mountpoint, sizeof(d->mountpoint), "%s", mount);
                    snprintf(d->filesystem, sizeof(d->filesystem), "%s", fstype);

                    d->total_bytes = (unsigned long long)vfs.f_blocks * vfs.f_frsize;
                    d->used_bytes = (unsigned long long)(vfs.f_blocks - vfs.f_bfree) * vfs.f_frsize;
                }
            }
        }
    }
    fclose(f);

    *disks_out = disks;
    return count;
}

typedef struct {
    char name[128];
    char type[32];
    unsigned long long total_bytes;
} PhysicalDiskInfo;

static int fetch_physical_disks(PhysicalDiskInfo **pdisks_out) {
    DIR *dir = opendir("/sys/block");
    if (!dir) return 0;

    struct dirent *entry;
    int count = 0;
    PhysicalDiskInfo *pdisks = NULL;

    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.') continue;
        if (strncmp(entry->d_name, "sd", 2) == 0 || strncmp(entry->d_name, "nvme", 4) == 0 ||
            strncmp(entry->d_name, "zram", 4) == 0 || strncmp(entry->d_name, "mmcblk", 6) == 0) {

            char path[256], buf[128];
            snprintf(path, sizeof(path), "/sys/block/%s/size", entry->d_name);
            if (!read_sys_file(path, buf, sizeof(buf))) continue;

            pdisks = realloc(pdisks, (count + 1) * sizeof(PhysicalDiskInfo));
            PhysicalDiskInfo *p = &pdisks[count++];
            memset(p, 0, sizeof(PhysicalDiskInfo));

            p->total_bytes = strtoull(buf, NULL, 10) * 512ULL;

            snprintf(path, sizeof(path), "/sys/block/%s/device/model", entry->d_name);
            if (!read_sys_file(path, p->name, sizeof(p->name))) snprintf(p->name, sizeof(p->name), "%s", entry->d_name);

            if (strncmp(entry->d_name, "nvme", 4) == 0) snprintf(p->type, sizeof(p->type), "NVMe");
            else if (strncmp(entry->d_name, "zram", 4) == 0) snprintf(p->type, sizeof(p->type), "Virtual");
            else snprintf(p->type, sizeof(p->type), "ATA/SATA");
        }
    }
    closedir(dir);

    *pdisks_out = pdisks;
    return count;
}

typedef struct {
    double read_bytes_sec;
    double write_bytes_sec;
} DiskIo;

static unsigned long long prev_disk_read_bytes = 0;
static unsigned long long prev_disk_write_bytes = 0;

static void fetch_disk_io(double interval_sec, DiskIo *io) {
    FILE *f = fopen("/proc/diskstats", "r");
    if (!f) return;

    char line[256];
    unsigned long long total_read_sectors = 0, total_write_sectors = 0;

    while (fgets(line, sizeof(line), f)) {
        char dev[64];
        unsigned long long r_sec = 0, w_sec = 0;
        if (sscanf(line, "%*d %*d %s %*u %*u %llu %*u %*u %*u %llu", dev, &r_sec, &w_sec) == 3) {
            if (strncmp(dev, "sd", 2) == 0 || strncmp(dev, "nvme", 4) == 0) {
                total_read_sectors += r_sec;
                total_write_sectors += w_sec;
            }
        }
    }
    fclose(f);

    unsigned long long curr_read_bytes = total_read_sectors * 512ULL;
    unsigned long long curr_write_bytes = total_write_sectors * 512ULL;

    if (prev_disk_read_bytes > 0 && interval_sec > 0) {
        io->read_bytes_sec = (curr_read_bytes - prev_disk_read_bytes) / interval_sec;
        io->write_bytes_sec = (curr_write_bytes - prev_disk_write_bytes) / interval_sec;
    }
    prev_disk_read_bytes = curr_read_bytes;
    prev_disk_write_bytes = curr_write_bytes;
}

typedef struct {
    int enabled;
    char type[32];
    char name[128];
    char local_ip[64];
    int signal_pct;
    double freq_ghz;
    int channel;
    double rx_bytes_sec;
    double tx_bytes_sec;
} NetworkInfo;

static unsigned long long prev_net_rx_bytes = 0;
static unsigned long long prev_net_tx_bytes = 0;

typedef enum {
    HW_TYPE_VIRTUAL = 0,
    HW_TYPE_WIFI,
    HW_TYPE_ETHERNET
} HwIfaceType;

static HwIfaceType get_iface_hw_type(const char *ifname) {
    char path[256];
    struct stat st;

    snprintf(path, sizeof(path), "/sys/class/net/%s/wireless", ifname);
    if (stat(path, &st) == 0) return HW_TYPE_WIFI;

    snprintf(path, sizeof(path), "/sys/class/net/%s/phy80211", ifname);
    if (stat(path, &st) == 0) return HW_TYPE_WIFI;

    if (strncmp(ifname, "wl", 2) == 0) return HW_TYPE_WIFI;

    snprintf(path, sizeof(path), "/sys/class/net/%s/device", ifname);
    if (stat(path, &st) == 0) return HW_TYPE_ETHERNET;

    return HW_TYPE_VIRTUAL;
}

static int find_wireless_interface(char *out_iface, size_t max_len) {
    DIR *dir = opendir("/sys/class/net");
    if (!dir) return 0;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.') continue;
        if (get_iface_hw_type(entry->d_name) == HW_TYPE_WIFI) {
            snprintf(out_iface, max_len, "%s", entry->d_name);
            closedir(dir);
            return 1;
        }
    }
    closedir(dir);
    return 0;
}

static void fetch_network(double interval_sec, NetworkInfo *net) {
    memset(net, 0, sizeof(NetworkInfo));

    struct ifaddrs *ifaddr, *ifa;
    char active_if[64] = "";
    HwIfaceType active_hw_type = HW_TYPE_VIRTUAL;

    if (getifaddrs(&ifaddr) == 0) {
        for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr && ifa->ifa_addr->sa_family == AF_INET && !(ifa->ifa_flags & IFF_LOOPBACK)) {
                HwIfaceType hw_type = get_iface_hw_type(ifa->ifa_name);
                if (hw_type == HW_TYPE_VIRTUAL) continue;

                struct sockaddr_in *pAddr = (struct sockaddr_in *)ifa->ifa_addr;
                if (active_if[0] == '\0' || hw_type == HW_TYPE_WIFI) {
                    snprintf(net->local_ip, sizeof(net->local_ip), "%s/24", inet_ntoa(pAddr->sin_addr));
                    snprintf(active_if, sizeof(active_if), "%s", ifa->ifa_name);
                    active_hw_type = hw_type;
                }
            }
        }
        freeifaddrs(ifaddr);
    }

    int is_wifi = 0;
    int sock = socket(AF_INET, SOCK_DGRAM, 0);

    if (active_if[0] != '\0') {
        net->enabled = 1;
        if (active_hw_type == HW_TYPE_WIFI && sock >= 0) {
            struct iwreq wrq;
            memset(&wrq, 0, sizeof(wrq));
            snprintf(wrq.ifr_name, sizeof(wrq.ifr_name), "%s", active_if);

            char essid[IW_ESSID_MAX_SIZE + 1] = {0};
            wrq.u.essid.pointer = essid;
            wrq.u.essid.length = IW_ESSID_MAX_SIZE + 1;

            if (ioctl(sock, SIOCGIWESSID, &wrq) == 0) {
                is_wifi = 1;
                snprintf(net->type, sizeof(net->type), "Wifi");
                snprintf(net->name, sizeof(net->name), "%s", (wrq.u.essid.flags && essid[0] != '\0') ? essid : "Disconnected");
            }
        }

        if (!is_wifi) {
            snprintf(net->type, sizeof(net->type), "Ethernet");
            snprintf(net->name, sizeof(net->name), "Ethernet");
        }
    } else {
        snprintf(net->local_ip, sizeof(net->local_ip), "0.0.0.0");
        char wl_if[64] = "";
        if (find_wireless_interface(wl_if, sizeof(wl_if))) {
            snprintf(net->type, sizeof(net->type), "Wifi");
            if (sock >= 0) {
                struct ifreq ifr;
                memset(&ifr, 0, sizeof(ifr));
                snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "%s", wl_if);
                if (ioctl(sock, SIOCGIFFLAGS, &ifr) == 0 && (ifr.ifr_flags & IFF_UP)) {
                    snprintf(net->name, sizeof(net->name), "Disconnected");
                    net->enabled = 1;
                } else {
                    snprintf(net->name, sizeof(net->name), "Off");
                    net->enabled = 0;
                }
            } else {
                snprintf(net->name, sizeof(net->name), "Off");
                net->enabled = 0;
            }
        } else {
            snprintf(net->type, sizeof(net->type), "None");
            snprintf(net->name, sizeof(net->name), "Disconnected");
            net->enabled = 0;
        }
    }

    if (is_wifi && active_if[0] != '\0') {
        if (sock >= 0) {
            struct iwreq wrq;
            memset(&wrq, 0, sizeof(wrq));
            snprintf(wrq.ifr_name, sizeof(wrq.ifr_name), "%s", active_if);

            if (ioctl(sock, SIOCGIWFREQ, &wrq) == 0) {
                double freq_hz = wrq.u.freq.m;
                for (int i = 0; i < wrq.u.freq.e; i++) freq_hz *= 10.0;
                double freq_mhz = freq_hz / 1e6;
                net->freq_ghz = freq_hz / 1e9;

                if (freq_mhz >= 2412 && freq_mhz <= 2484) net->channel = (freq_mhz == 2484) ? 14 : (int)((freq_mhz - 2407) / 5);
                else if (freq_mhz >= 5150 && freq_mhz <= 5885) net->channel = (int)((freq_mhz - 5000) / 5);
                else if (freq_mhz >= 5925 && freq_mhz <= 7115) net->channel = (int)((freq_mhz - 5950) / 5);
            }
        }

        FILE *fw = fopen("/proc/net/wireless", "r");
        if (fw) {
            char line[256];
            while (fgets(line, sizeof(line), fw)) {
                if (strstr(line, active_if)) {
                    double link_qual = 0;
                    char *colon = strchr(line, ':');
                    if (colon) {
                        sscanf(colon + 1, "%*s %lf", &link_qual);
                        net->signal_pct = (int)((link_qual / 70.0) * 100.0);
                        if (net->signal_pct > 100) net->signal_pct = 100;
                    }
                    break;
                }
            }
            fclose(fw);
        }
    }

    if (sock >= 0) close(sock);

    if (active_if[0] != '\0') {
        FILE *fn = fopen("/proc/net/dev", "r");
        if (fn) {
            char line[256];
            unsigned long long curr_rx = 0, curr_tx = 0;
            while (fgets(line, sizeof(line), fn)) {
                if (strstr(line, active_if)) {
                    sscanf(line, "%*s %llu %*d %*d %*d %*d %*d %*d %*d %llu", &curr_rx, &curr_tx);
                    break;
                }
            }
            fclose(fn);

            if (prev_net_rx_bytes > 0 && interval_sec > 0) {
                net->rx_bytes_sec = (curr_rx - prev_net_rx_bytes) / interval_sec;
                net->tx_bytes_sec = (curr_tx - prev_net_tx_bytes) / interval_sec;
            }
            prev_net_rx_bytes = curr_rx;
            prev_net_tx_bytes = curr_tx;
        }
    }
}

typedef struct {
    char battery_pct[16];
    char health_pct[16];
    char state[32];
    int on_battery;
    double power_w;
} PowerInfo;

static void fetch_power(PowerInfo *p) {
    memset(p, 0, sizeof(PowerInfo));
    DIR *dir = opendir("/sys/class/power_supply");
    if (!dir) {
        snprintf(p->battery_pct, sizeof(p->battery_pct), "inf");
        snprintf(p->health_pct, sizeof(p->health_pct), "inf");
        snprintf(p->state, sizeof(p->state), "PSU");
        p->on_battery = 0;
        return;
    }

    struct dirent *entry;
    int found_bat = 0;
    while ((entry = readdir(dir)) != NULL) {
        if (strncmp(entry->d_name, "BAT", 3) == 0) {
            found_bat = 1;
            char path[256], buf[64];
            snprintf(path, sizeof(path), "/sys/class/power_supply/%s/capacity", entry->d_name);
            if (read_sys_file(path, buf, sizeof(buf))) snprintf(p->battery_pct, sizeof(p->battery_pct), "%s%%", buf);

            snprintf(path, sizeof(path), "/sys/class/power_supply/%s/status", entry->d_name);
            if (read_sys_file(path, buf, sizeof(buf))) {
                snprintf(p->state, sizeof(p->state), "%s", buf);
                p->on_battery = (strcmp(buf, "Discharging") == 0);
            }

            snprintf(path, sizeof(path), "/sys/class/power_supply/%s/power_now", entry->d_name);
            if (read_sys_file(path, buf, sizeof(buf))) {
                p->power_w = atof(buf) / 1000000.0;
            }

            snprintf(p->health_pct, sizeof(p->health_pct), "100%%");
            break;
        }
    }
    closedir(dir);

    if (!found_bat) {
        snprintf(p->battery_pct, sizeof(p->battery_pct), "inf");
        snprintf(p->health_pct, sizeof(p->health_pct), "inf");
        snprintf(p->state, sizeof(p->state), "PSU");
        p->on_battery = 0;
    }
}

// ---------------------------------------------------------------------
// Process Stats Tracking
// ---------------------------------------------------------------------
typedef struct {
    unsigned int pid;
    unsigned long total_proc_ticks;
} CpuSnap;

static CpuSnap *prev_proc_cpu_snaps = NULL;
static int prev_proc_cpu_count = 0;
static int prev_proc_cpu_capacity = 0;

static CpuSnap *next_proc_cpu_snaps = NULL;
static int next_proc_cpu_count = 0;
static int next_proc_cpu_capacity = 0;

typedef struct {
    unsigned int pid;
    unsigned long long vram_bytes;
    GpuProcType type;
    unsigned int gpu_util_pct;
    unsigned int mem_util_pct;
    unsigned int enc_util_pct;
    unsigned int dec_util_pct;

    unsigned long long prev_gfx_ns;
    unsigned long long prev_compute_ns;
    unsigned long long prev_enc_ns;
    unsigned long long prev_dec_ns;
} GpuProcInfo;

static GpuProcInfo *gpu_procs = NULL;
static int gpu_proc_count = 0;
static int gpu_proc_capacity = 0;

static unsigned long get_prev_proc_ticks(unsigned int pid) {
    for (int i = 0; i < prev_proc_cpu_count; i++) {
        if (prev_proc_cpu_snaps[i].pid == pid) return prev_proc_cpu_snaps[i].total_proc_ticks;
    }
    return 0;
}

static int get_or_create_gpu_proc(unsigned int pid) {
    for (int i = 0; i < gpu_proc_count; i++) {
        if (gpu_procs[i].pid == pid) return i;
    }
    if (gpu_proc_count >= gpu_proc_capacity) {
        int new_cap = (gpu_proc_capacity == 0) ? 256 : gpu_proc_capacity * 2;
        GpuProcInfo *tmp = realloc(gpu_procs, new_cap * sizeof(GpuProcInfo));
        if (!tmp) return -1;
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

static int pid_alive(unsigned int pid) {
    return kill((pid_t)pid, 0) == 0 || errno != ESRCH;
}

static void evict_dead_gpu_procs(void) {
    int write_idx = 0;
    for (int i = 0; i < gpu_proc_count; i++) {
        if (pid_alive(gpu_procs[i].pid)) {
            if (write_idx != i) gpu_procs[write_idx] = gpu_procs[i];
            write_idx++;
        }
    }
    gpu_proc_count = write_idx;
}

static void fetch_nvidia_gpu_procs(nvmlDevice_t device) {
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
    if (!infos) return;

    if (p_nvmlDeviceGetGraphicsRunningProcesses(device, &count, infos) == NVML_SUCCESS) {
        for (unsigned int i = 0; i < count; i++) {
            int idx = get_or_create_gpu_proc(infos[i].pid);
            if (idx != -1) {
                gpu_procs[idx].vram_bytes = infos[i].usedGpuMemory;
                gpu_procs[idx].type |= PROC_TYPE_GRAPHICS;
            }
        }
    }

    count = 1024;
    if (p_nvmlDeviceGetComputeRunningProcesses(device, &count, infos) == NVML_SUCCESS) {
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
    nvmlProcessUtilizationSample_t *util_samples = malloc(util_count * sizeof(nvmlProcessUtilizationSample_t));
    if (util_samples) {
        if (p_nvmlDeviceGetProcessUtilization(device, util_samples, &util_count, last_seen_nvml_ts) == NVML_SUCCESS) {
            unsigned long long max_ts = last_seen_nvml_ts;

            for (unsigned int i = 0; i < util_count; i++) {
                get_or_create_gpu_proc(util_samples[i].pid);
            }

            int cap = gpu_proc_capacity;
            unsigned int *sum_sm = calloc(cap > 0 ? cap : 1, sizeof(unsigned int));
            unsigned int *sum_mem = calloc(cap > 0 ? cap : 1, sizeof(unsigned int));
            unsigned int *sum_enc = calloc(cap > 0 ? cap : 1, sizeof(unsigned int));
            unsigned int *sum_dec = calloc(cap > 0 ? cap : 1, sizeof(unsigned int));
            unsigned int *sample_counts = calloc(cap > 0 ? cap : 1, sizeof(unsigned int));

            if (sum_sm && sum_mem && sum_enc && sum_dec && sample_counts) {
                for (unsigned int i = 0; i < util_count; i++) {
                    int idx = get_or_create_gpu_proc(util_samples[i].pid);
                    if (idx != -1 && idx < cap) {
                        sum_sm[idx] += util_samples[i].smUtil;
                        sum_mem[idx] += util_samples[i].memUtil;
                        sum_enc[idx] += util_samples[i].encUtil;
                        sum_dec[idx] += util_samples[i].decUtil;
                        sample_counts[idx]++;
                    }
                    if (util_samples[i].timeStamp > max_ts) {
                        max_ts = util_samples[i].timeStamp;
                    }
                }

                for (int i = 0; i < gpu_proc_count; i++) {
                    if (i < cap && sample_counts[i] > 0) {
                        gpu_procs[i].gpu_util_pct = sum_sm[i] / sample_counts[i];
                        gpu_procs[i].mem_util_pct = sum_mem[i] / sample_counts[i];
                        gpu_procs[i].enc_util_pct = sum_enc[i] / sample_counts[i];
                        gpu_procs[i].dec_util_pct = sum_dec[i] / sample_counts[i];
                    }
                }
            }

            free(sum_sm);
            free(sum_mem);
            free(sum_enc);
            free(sum_dec);
            free(sample_counts);

            last_seen_nvml_ts = max_ts;
        }
        free(util_samples);
    }
}

typedef struct {
    unsigned long long vram_bytes;
    GpuProcType type;
    unsigned long long gfx_ns;
    unsigned long long compute_ns;
    unsigned long long enc_ns;
    unsigned long long dec_ns;
} AmdFdinfoData;

static void scan_amd_fdinfo(unsigned int pid, AmdFdinfoData *out) {
    memset(out, 0, sizeof(AmdFdinfoData));
    char fdinfo_dir[256];
    snprintf(fdinfo_dir, sizeof(fdinfo_dir), "/proc/%u/fdinfo", pid);
    DIR *dir = opendir(fdinfo_dir);
    if (!dir) return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.') continue;
        char filepath[512];
        snprintf(filepath, sizeof(filepath), "%s/%s", fdinfo_dir, entry->d_name);
        FILE *f = fopen(filepath, "r");
        if (!f) continue;

        char line[256];
        int is_amdgpu = 0;
        unsigned long long vram_kb = 0, gfx_ns = 0, compute_ns = 0, enc_ns = 0, dec_ns = 0;

        while (fgets(line, sizeof(line), f)) {
            if (strncmp(line, "drm-driver:", 11) == 0 && strstr(line, "amdgpu")) is_amdgpu = 1;
            else if (strncmp(line, "drm-memory-vram:", 16) == 0) sscanf(line, "drm-memory-vram:\t%llu", &vram_kb);
            else if (strncmp(line, "drm-engine-gfx:", 15) == 0) sscanf(line, "drm-engine-gfx:\t%llu", &gfx_ns);
            else if (strncmp(line, "drm-engine-compute:", 19) == 0) sscanf(line, "drm-engine-compute:\t%llu", &compute_ns);
            else if (strncmp(line, "drm-engine-enc:", 15) == 0 || strncmp(line, "drm-engine-vce:", 15) == 0) sscanf(line, "%*s\t%llu", &enc_ns);
            else if (strncmp(line, "drm-engine-dec:", 15) == 0 || strncmp(line, "drm-engine-uvd:", 15) == 0 || strncmp(line, "drm-engine-vcn:", 15) == 0) sscanf(line, "%*s\t%llu", &dec_ns);
        }
        fclose(f);

        if (is_amdgpu) {
            out->vram_bytes += vram_kb * 1024;
            out->gfx_ns += gfx_ns;
            out->compute_ns += compute_ns;
            out->enc_ns += enc_ns;
            out->dec_ns += dec_ns;
            if (gfx_ns > 0) out->type |= PROC_TYPE_GRAPHICS;
            if (compute_ns > 0) out->type |= PROC_TYPE_COMPUTE;
        }
    }
    closedir(dir);
}

static void fetch_amd_gpu_procs(unsigned long long interval_ns) {
    evict_dead_gpu_procs();
    DIR *dir = opendir("/proc");
    if (!dir) return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (!isdigit(entry->d_name[0])) continue;
        unsigned int pid = (unsigned int)atoi(entry->d_name);

        AmdFdinfoData amd_data;
        scan_amd_fdinfo(pid, &amd_data);

        if (amd_data.vram_bytes > 0 || amd_data.type != PROC_TYPE_NONE) {
            int idx = get_or_create_gpu_proc(pid);
            if (idx != -1) {
                gpu_procs[idx].vram_bytes = amd_data.vram_bytes;
                gpu_procs[idx].type = amd_data.type;

                if (interval_ns > 0) {
                    unsigned long long total_engine_delta = 0;
                    if (gpu_procs[idx].prev_gfx_ns > 0 && amd_data.gfx_ns >= gpu_procs[idx].prev_gfx_ns) {
                        total_engine_delta += (amd_data.gfx_ns - gpu_procs[idx].prev_gfx_ns);
                    }
                    if (gpu_procs[idx].prev_compute_ns > 0 && amd_data.compute_ns >= gpu_procs[idx].prev_compute_ns) {
                        total_engine_delta += (amd_data.compute_ns - gpu_procs[idx].prev_compute_ns);
                    }

                    unsigned int util = (unsigned int)((total_engine_delta * 100ULL) / interval_ns);
                    gpu_procs[idx].gpu_util_pct = (util > 100) ? 100 : util;

                    if (gpu_procs[idx].prev_enc_ns > 0 && amd_data.enc_ns >= gpu_procs[idx].prev_enc_ns) {
                        gpu_procs[idx].enc_util_pct = (unsigned int)(((amd_data.enc_ns - gpu_procs[idx].prev_enc_ns) * 100ULL) / interval_ns);
                    }
                    if (gpu_procs[idx].prev_dec_ns > 0 && amd_data.dec_ns >= gpu_procs[idx].prev_dec_ns) {
                        gpu_procs[idx].dec_util_pct = (unsigned int)(((amd_data.dec_ns - gpu_procs[idx].prev_dec_ns) * 100ULL) / interval_ns);
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

static void get_gpu_info_for_pid(unsigned int pid,
                                 unsigned long long *vram_bytes,
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

static void get_process_cmdline(int pid, char *out_buf, size_t max_len, const char *fallback) {
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
        snprintf(out_buf, max_len, "[%s]", fallback);
        return;
    }

    out_buf[bytes_read] = '\0';
    for (size_t i = 0; i < bytes_read - 1; i++) {
        if (out_buf[i] == '\0') out_buf[i] = ' ';
    }
}

static const char *get_proc_type_str(GpuProcType type) {
    switch (type) {
        case PROC_TYPE_GRAPHICS: return "GFX";
        case PROC_TYPE_COMPUTE:  return "COMP";
        case PROC_TYPE_BOTH:     return "BOTH";
        default:                 return "N/A";
    }
}

// ---------------------------------------------------------------------
// Print Unified JSON Output
// ---------------------------------------------------------------------
static void print_unified_json(SystemMeta *meta, CpuInfo *cpu, GpuInfo *gpus,
                               int gpu_count, MemInfo *mem, DiskInfo *disks,
                               int disk_count, PhysicalDiskInfo *pdisks,
                               int pdisk_count, DiskIo *dio, NetworkInfo *net,
                               PowerInfo *power,
                               unsigned long long system_ticks_delta,
                               int num_cores) {
    printf("{");

    // OS
    printf("\"os\":{\"username\":\""); print_json_escaped(meta->username);
    printf("\",\"hostname\":\""); print_json_escaped(meta->hostname);
    printf("\",\"name\":\""); print_json_escaped(meta->os_name);
    printf("\",\"arch\":\""); print_json_escaped(meta->arch);
    printf("\",\"kernel\":\""); print_json_escaped(meta->kernel);
    printf("\",\"uptime\":%.0f,\"wm\":\"%s\"},", meta->uptime_sec, meta->wm);

    // Board
    printf("\"board\":{\"model\":\""); print_json_escaped(meta->board_name); printf("\"},");

    // CPU
    printf("\"cpu\":{\"model\":\""); print_json_escaped(cpu->model);
    printf("\",\"cores\":%d,\"threads\":%d,\"cur_freq_mhz\":%.0f,\"max_freq_mhz\":%.0f,\"temp_c\":%.1f,\"power_w\":%.1f,\"power_max_w\":%.1f,\"rapl_restricted\":%s,\"total_usage_pct\":%.1f,\"core_usage_pct\":[",
           cpu->cores, cpu->threads, cpu->cur_freq_mhz, cpu->max_freq_mhz, cpu->temp_c, cpu->power_w, cpu->power_max_w,
           cpu->rapl_restricted ? "true" : "false", cpu->total_usage_pct);
    if (cpu->core_usage_pct && cpu->num_core_stats > 0) {
        for (int i = 0; i < cpu->num_core_stats; i++) {
            printf("%.1f%s", cpu->core_usage_pct[i], (i == cpu->num_core_stats - 1) ? "" : ",");
        }
    }
    printf("]},");

    // GPUs
    printf("\"gpus\":[");
    for (int i = 0; i < gpu_count; i++) {
        printf("{\"name\":\""); print_json_escaped(gpus[i].name);
        printf("\",\"type\":\"%s\",\"cur_freq_mhz\":%.0f,\"max_freq_mhz\":%.0f,\"cur_mem_freq_mhz\":%.0f,\"max_mem_freq_mhz\":%.0f,\"temp_c\":%.1f,\"power_cur_w\":%.1f,\"power_max_w\":%.1f,\"gpu_util_pct\":%u,\"mem_util_pct\":%u,\"enc_util_pct\":%u,\"dec_util_pct\":%u,\"cores\":%u,\"vram_total_bytes\":%llu,\"vram_used_bytes\":%llu}%s",
               gpus[i].type, gpus[i].cur_freq_mhz, gpus[i].max_freq_mhz,
               gpus[i].cur_mem_freq_mhz, gpus[i].max_mem_freq_mhz,
               gpus[i].temp_c, gpus[i].power_cur_w, gpus[i].power_max_w,
               gpus[i].gpu_util_pct, gpus[i].mem_util_pct, gpus[i].enc_util_pct, gpus[i].dec_util_pct,
               gpus[i].cores, gpus[i].vram_total_bytes, gpus[i].vram_used_bytes,
               (i == gpu_count - 1) ? "" : ",");
    }
    printf("],");

    // Memory
    printf("\"memory\":{\"ram_total_bytes\":%llu,\"ram_used_bytes\":%llu,\"swap_total_bytes\":%llu,\"swap_used_bytes\":%llu},",
           mem->ram_total_bytes, mem->ram_used_bytes, mem->swap_total_bytes, mem->swap_used_bytes);

    // Disks
    printf("\"disks\":[");
    for (int i = 0; i < disk_count; i++) {
        printf("{\"name\":\""); print_json_escaped(disks[i].name);
        printf("\",\"label\":\""); print_json_escaped(disks[i].label);
        printf("\",\"mountpoint\":\""); print_json_escaped(disks[i].mountpoint);
        printf("\",\"filesystem\":\""); print_json_escaped(disks[i].filesystem);
        printf("\",\"total_bytes\":%llu,\"used_bytes\":%llu}%s",
               disks[i].total_bytes, disks[i].used_bytes, (i == disk_count - 1) ? "" : ",");
    }
    printf("],");

    // Physical Disks
    printf("\"physical_disks\":[");
    for (int i = 0; i < pdisk_count; i++) {
        printf("{\"name\":\""); print_json_escaped(pdisks[i].name);
        printf("\",\"type\":\"%s\",\"total_bytes\":%llu}%s",
               pdisks[i].type, pdisks[i].total_bytes, (i == pdisk_count - 1) ? "" : ",");
    }
    printf("],");

    // IO, Power & Net
    printf("\"disk_io\":{\"read_bytes_sec\":%.0f,\"write_bytes_sec\":%.0f},", dio->read_bytes_sec, dio->write_bytes_sec);
    printf("\"power\":{\"battery_pct\":\"%s\",\"health_pct\":\"%s\",\"state\":\"%s\",\"on_battery\":%s,\"power_w\":%.1f},",
           power->battery_pct, power->health_pct, power->state, power->on_battery ? "true" : "false", power->power_w);
    printf("\"network\":{\"enabled\":%s,\"type\":\"%s\",\"name\":\"%s\",\"local_ip\":\"%s\",\"signal_pct\":%d,\"freq_ghz\":%.1f,\"channel\":%d},",
           net->enabled ? "true" : "false", net->type, net->name, net->local_ip, net->signal_pct, net->freq_ghz, net->channel);
    printf("\"network_io\":{\"rx_bytes_sec\":%.0f,\"tx_bytes_sec\":%.0f},", net->rx_bytes_sec, net->tx_bytes_sec);

    // Process Info Meta
    const char *vendor_str = (active_gpu_vendor == GPU_VENDOR_NVIDIA) ? "NVIDIA"
                           : (active_gpu_vendor == GPU_VENDOR_AMD)    ? "AMD"
                                                                      : "None";
    printf("\"gpu_available\":%s,\"gpu_vendor\":\"%s\",\"processes\":[", gpu_available ? "true" : "false", vendor_str);

    // Scan Processes
    DIR *dir = opendir("/proc");
    next_proc_cpu_count = 0;
    int printed_json_count = 0;

    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (!isdigit(entry->d_name[0])) continue;

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
                        if (comm_len > 255) comm_len = 255;
                        strncpy(comm, open_paren + 1, comm_len);
                        comm[comm_len] = '\0';
                        sscanf(close_paren + 2, "%*c %*d %*d %*d %*d %*d %*u %*u %*u %*u %*u %lu %lu", &utime, &stime);
                    }
                }
                fclose(fstat);
            } else continue;

            get_process_cmdline(pid, cmdline, sizeof(cmdline), comm);

            snprintf(path, sizeof(path), "/proc/%d/statm", pid);
            FILE *fstatm = fopen(path, "r");
            if (fstatm) { fscanf(fstatm, "%*d %ld", &rss_pages); fclose(fstatm); }

            unsigned long total_proc_ticks = utime + stime;

            if (next_proc_cpu_count >= next_proc_cpu_capacity) {
                int new_cap = (next_proc_cpu_capacity == 0) ? 256 : next_proc_cpu_capacity * 2;
                CpuSnap *tmp = realloc(next_proc_cpu_snaps, new_cap * sizeof(CpuSnap));
                if (tmp) { next_proc_cpu_snaps = tmp; next_proc_cpu_capacity = new_cap; }
            }

            if (next_proc_cpu_count < next_proc_cpu_capacity) {
                next_proc_cpu_snaps[next_proc_cpu_count].pid = pid;
                next_proc_cpu_snaps[next_proc_cpu_count].total_proc_ticks = total_proc_ticks;
                next_proc_cpu_count++;
            }

            double cpu_pct = 0.0;
            if (system_ticks_delta > 0) {
                unsigned long prev_proc_ticks = get_prev_proc_ticks(pid);
                if (prev_proc_ticks > 0 && total_proc_ticks >= prev_proc_ticks) {
                    cpu_pct = ((double)(total_proc_ticks - prev_proc_ticks) / system_ticks_delta) * 100.0 * num_cores;
                }
            }

            long page_size_kb = sysconf(_SC_PAGESIZE) / 1024;
            double ram_mb = (rss_pages * page_size_kb) / 1024.0;

            unsigned long long vram_bytes = 0;
            GpuProcType gpu_type = PROC_TYPE_NONE;
            unsigned int gpu_util = 0, mem_util = 0, enc_util = 0, dec_util = 0;

            if (gpu_available) {
                get_gpu_info_for_pid(pid, &vram_bytes, &gpu_type, &gpu_util, &mem_util, &enc_util, &dec_util);
            }
            double vram_mb = vram_bytes / (1024.0 * 1024.0);

            int worth_printing = (ram_mb > 0.1 || cpu_pct > 0.1) ||
                                 (gpu_available && (vram_mb > 0.0 || gpu_type != PROC_TYPE_NONE || gpu_util > 0 || mem_util > 0 || enc_util > 0 || dec_util > 0));

            if (worth_printing) {
                if (printed_json_count > 0) printf(",");
                printf("{\"pid\":%d,\"name\":\"", pid);
                print_json_escaped(comm);
                printf("\",\"cmdline\":\"");
                print_json_escaped(cmdline);
                printf("\",\"cpu_pct\":%.1f,\"ram_mb\":%.2f", cpu_pct, ram_mb);
                if (gpu_available) {
                    printf(",\"gpu_type\":\"%s\",\"vram_mb\":%.2f,\"sm_pct\":%u,\"mem_pct\":%u,\"enc_pct\":%u,\"dec_pct\":%u",
                           get_proc_type_str(gpu_type), vram_mb, gpu_util, mem_util, enc_util, dec_util);
                }
                printf("}");
                printed_json_count++;
            }
        }
        closedir(dir);
    }
    printf("]}\n");

    if (prev_proc_cpu_capacity < next_proc_cpu_count) {
        CpuSnap *tmp = realloc(prev_proc_cpu_snaps, next_proc_cpu_count * sizeof(CpuSnap));
        if (tmp) { prev_proc_cpu_snaps = tmp; prev_proc_cpu_capacity = next_proc_cpu_count; }
    }
    if (prev_proc_cpu_snaps) {
        memcpy(prev_proc_cpu_snaps, next_proc_cpu_snaps, sizeof(CpuSnap) * next_proc_cpu_count);
        prev_proc_cpu_count = next_proc_cpu_count;
    }

    fflush(stdout);
}

// ---------------------------------------------------------------------
// Main Loop
// ---------------------------------------------------------------------
int main(int argc, char *argv[]) {
    int interval_ms = 1000;
    if (argc > 1) interval_ms = atoi(argv[1]);
    if (interval_ms <= 0) interval_ms = 1000;

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    int num_cores = (int)sysconf(_SC_NPROCESSORS_ONLN);
    init_gpu_system();

    struct timespec prev_time, curr_time;
    clock_gettime(CLOCK_MONOTONIC, &prev_time);

    while (keep_running) {
        usleep(interval_ms * 1000);

        clock_gettime(CLOCK_MONOTONIC, &curr_time);
        double interval_sec = (curr_time.tv_sec - prev_time.tv_sec) + (curr_time.tv_nsec - prev_time.tv_nsec) / 1e9;
        unsigned long long interval_ns = (unsigned long long)(interval_sec * 1e9);
        prev_time = curr_time;

        SystemMeta meta;
        CpuInfo cpu;
        GpuInfo *gpus = NULL;
        MemInfo mem;
        DiskInfo *disks = NULL;
        PhysicalDiskInfo *pdisks = NULL;
        DiskIo dio = {0};
        NetworkInfo net;
        PowerInfo power;
        unsigned long long system_ticks_delta = 0;

        // 1. Synchronized CPU & System Tick Delta Sampling
        fetch_system_meta(&meta);
        fetch_cpu_info(&cpu, interval_sec, &system_ticks_delta);

        // 2. Synchronized GPU System & GPU Process Sampling (sampled back-to-back)
        int gpu_count = fetch_system_gpus(&gpus);
        if (active_gpu_vendor == GPU_VENDOR_NVIDIA) {
            fetch_nvidia_gpu_procs(nvml_device_0);
        } else if (active_gpu_vendor == GPU_VENDOR_AMD) {
            fetch_amd_gpu_procs(interval_ns);
        }

        // 3. Memory, Disks, Network, and Power
        fetch_memory(&mem);
        int disk_count = fetch_disks(&disks);
        int pdisk_count = fetch_physical_disks(&pdisks);
        fetch_disk_io(interval_sec, &dio);
        fetch_network(interval_sec, &net);
        fetch_power(&power);

        // 4. Output Unified JSON
        print_unified_json(&meta, &cpu, gpus, gpu_count, &mem, disks, disk_count, pdisks, pdisk_count, &dio, &net, &power, system_ticks_delta, num_cores);

        free(cpu.core_usage_pct);
        free(gpus);
        free(disks);
        free(pdisks);
    }

    if (active_gpu_vendor == GPU_VENDOR_NVIDIA && p_nvmlShutdown) p_nvmlShutdown();
    if (nvml_handle) dlclose(nvml_handle);

    free(prev_sys_cpu_ticks);
    free(gpu_procs);
    free(prev_proc_cpu_snaps);
    free(next_proc_cpu_snaps);

    return 0;
}
