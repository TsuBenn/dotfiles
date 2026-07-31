#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <ctype.h>
#include <unistd.h>
#include <time.h>
#include <nvml.h>

#define MAX_PROCS 4096
#define SAMPLE_INTERVAL_MS 500 // 500ms sampling window for CPU %

typedef struct {
    int pid;
    char name[256];
    long rss_bytes;
    unsigned long long utime;
    unsigned long long stime;
    double cpu_util_percent;
    unsigned long long vram_bytes;
    unsigned int gpu_util_percent;
} ProcessInfo;

typedef struct {
    int pid;
    unsigned long long vram_bytes;
    unsigned int gpu_util;
} GpuProcInfo;

// Get total system CPU ticks to calculate total CPU capacity over interval
unsigned long long get_system_cpu_ticks() {
    FILE *f = fopen("/proc/stat", "r");
    if (!f) return 0;

    char label[16];
    unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
    if (fscanf(f, "%s %llu %llu %llu %llu %llu %llu %llu %llu",
               label, &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal) < 9) {
        fclose(f);
        return 0;
    }
    fclose(f);

    return user + nice + system + idle + iowait + irq + softirq + steal;
}

// Read CPU ticks (utime + stime), RSS memory, and name for a PID
int get_proc_sys_stats(ProcessInfo *proc) {
    char path[128];

    // 1. Read process name from /proc/[pid]/comm
    snprintf(path, sizeof(path), "/proc/%d/comm", proc->pid);
    FILE *f_comm = fopen(path, "r");
    if (!f_comm) return -1;
    if (fscanf(f_comm, "%255s", proc->name) != 1) {
        fclose(f_comm);
        return -1;
    }
    fclose(f_comm);

    // 2. Read RSS memory from /proc/[pid]/statm
    snprintf(path, sizeof(path), "/proc/%d/statm", proc->pid);
    FILE *f_statm = fopen(path, "r");
    if (!f_statm) return -1;
    long dummy, pages;
    if (fscanf(f_statm, "%ld %ld", &dummy, &pages) == 2) {
        proc->rss_bytes = pages * sysconf(_SC_PAGESIZE);
    } else {
        proc->rss_bytes = 0;
    }
    fclose(f_statm);

    // 3. Read utime (field 14) and stime (field 15) from /proc/[pid]/stat
    snprintf(path, sizeof(path), "/proc/%d/stat", proc->pid);
    FILE *f_stat = fopen(path, "r");
    if (!f_stat) return -1;

    // Skip first 13 fields to get to utime and stime
    char buf[1024];
    if (fgets(buf, sizeof(buf), f_stat)) {
        char *ptr = strrchr(buf, ')'); // Process comm can contain spaces/parens, skip past last ')'
        if (ptr) {
            int field = 3;
            char *token = strtok(ptr + 2, " ");
            while (token && field <= 15) {
                if (field == 14) proc->utime = strtoull(token, NULL, 10);
                if (field == 15) proc->stime = strtoull(token, NULL, 10);
                token = strtok(NULL, " ");
                field++;
            }
        }
    }
    fclose(f_stat);

    return 0;
}

// Fetch active GPU context list via NVML
int fetch_gpu_active_map(nvmlDevice_t device, GpuProcInfo gpu_map[], int *gpu_count) {
    *gpu_count = 0;
    unsigned int info_count = 128;
    nvmlProcessInfo_t infos[128];

    // Compute processes (Ollama, PyTorch, CUDA)
    if (nvmlDeviceGetComputeRunningProcesses(device, &info_count, infos) == NVML_SUCCESS) {
        for (unsigned int i = 0; i < info_count; i++) {
            gpu_map[*gpu_count].pid = infos[i].pid;
            gpu_map[*gpu_count].vram_bytes = infos[i].usedGpuMemory;
            gpu_map[*gpu_count].gpu_util = 0;
            (*gpu_count)++;
        }
    }

    // Graphics processes (Hyprland, Web Browsers, Games)
    info_count = 128;
    if (nvmlDeviceGetGraphicsRunningProcesses(device, &info_count, infos) == NVML_SUCCESS) {
        for (unsigned int i = 0; i < info_count; i++) {
            int exists = 0;
            for (int j = 0; j < *gpu_count; j++) {
                if (gpu_map[j].pid == (int)infos[i].pid) {
                    gpu_map[j].vram_bytes += infos[i].usedGpuMemory;
                    exists = 1;
                    break;
                }
            }
            if (!exists) {
                gpu_map[*gpu_count].pid = infos[i].pid;
                gpu_map[*gpu_count].vram_bytes = infos[i].usedGpuMemory;
                gpu_map[*gpu_count].gpu_util = 0;
                (*gpu_count)++;
            }
        }
    }

    // Per-process SM GPU % Utilization
    unsigned int sample_count = 128;
    nvmlProcessUtilizationSample_t samples[128];
    if (nvmlDeviceGetProcessUtilization(device, samples, &sample_count, 0) == NVML_SUCCESS) {
        for (unsigned int i = 0; i < sample_count; i++) {
            for (int j = 0; j < *gpu_count; j++) {
                if (gpu_map[j].pid == (int)samples[i].pid) {
                    gpu_map[j].gpu_util = samples[i].smUtil;
                    break;
                }
            }
        }
    }

    return 0;
}

// Collect initial process list snapshot
int snapshot_processes(ProcessInfo procs[], int *proc_count) {
    DIR *proc_dir = opendir("/proc");
    if (!proc_dir) return -1;

    struct dirent *entry;
    *proc_count = 0;

    while ((entry = readdir(proc_dir)) != NULL && *proc_count < MAX_PROCS) {
        if (entry->d_type == DT_DIR && isdigit(entry->d_name[0])) {
            int pid = atoi(entry->d_name);
            procs[*proc_count].pid = pid;
            procs[*proc_count].vram_bytes = 0;
            procs[*proc_count].gpu_util_percent = 0;
            procs[*proc_count].cpu_util_percent = 0.0;

            if (get_proc_sys_stats(&procs[*proc_count]) == 0) {
                (*proc_count)++;
            }
        }
    }

    closedir(proc_dir);
    return 0;
}

int main() {
    nvmlDevice_t device = NULL;
    int nvml_initialized = 0;

    // Try initializing NVML (soft fallback if GPU isn't present/supported)
    if (nvmlInit() == NVML_SUCCESS) {
        if (nvmlDeviceGetHandleByIndex(0, &device) == NVML_SUCCESS) {
            nvml_initialized = 1;
        }
    }

    long num_cores = sysconf(_SC_NPROCESSORS_ONLN);

    // Snapshot 1: CPU Ticks & Processes
    ProcessInfo t1_procs[MAX_PROCS];
    int t1_count = 0;
    unsigned long long sys_cpu_t1 = get_system_cpu_ticks();
    snapshot_processes(t1_procs, &t1_count);

    // Sleep interval to measure CPU clock delta
    usleep(SAMPLE_INTERVAL_MS * 1000);

    // Snapshot 2: CPU Ticks & Processes
    ProcessInfo t2_procs[MAX_PROCS];
    int t2_count = 0;
    unsigned long long sys_cpu_t2 = get_system_cpu_ticks();
    snapshot_processes(t2_procs, &t2_count);

    unsigned long long sys_cpu_delta = sys_cpu_t2 - sys_cpu_t1;

    // Fetch NVML GPU Process map
    GpuProcInfo gpu_map[256];
    int gpu_count = 0;
    if (nvml_initialized) {
        fetch_gpu_active_map(device, gpu_map, &gpu_count);
    }

    // Merge metrics into JSON array
    printf("[\n");
    int printed_first = 0;

    for (int i = 0; i < t2_count; i++) {
        // Calculate CPU % by matching PID from t1 and t2
        double cpu_percent = 0.0;
        if (sys_cpu_delta > 0) {
            for (int j = 0; j < t1_count; j++) {
                if (t1_procs[j].pid == t2_procs[i].pid) {
                    unsigned long long proc_ticks_delta =
                        (t2_procs[i].utime + t2_procs[i].stime) - (t1_procs[j].utime + t1_procs[j].stime);
                    cpu_percent = ((double)proc_ticks_delta / (double)sys_cpu_delta) * 100.0 * num_cores;
                    break;
                }
            }
        }
        t2_procs[i].cpu_util_percent = cpu_percent;

        // Attach NVML GPU/VRAM stats if PID exists in GPU active map
        for (int k = 0; k < gpu_count; k++) {
            if (gpu_map[k].pid == t2_procs[i].pid) {
                t2_procs[i].vram_bytes = gpu_map[k].vram_bytes;
                t2_procs[i].gpu_util_percent = gpu_map[k].gpu_util;
                break;
            }
        }

        if (printed_first) printf(",\n");
        printed_first = 1;

        printf("  {\n");
        printf("    \"pid\": %d,\n", t2_procs[i].pid);
        printf("    \"name\": \"%s\",\n", t2_procs[i].name);
        printf("    \"cpu_util_percent\": %.2f,\n", t2_procs[i].cpu_util_percent);
        printf("    \"ram_bytes\": %ld,\n", t2_procs[i].rss_bytes);
        printf("    \"vram_bytes\": %llu,\n", t2_procs[i].vram_bytes);
        printf("    \"gpu_util_percent\": %u\n", t2_procs[i].gpu_util_percent);
        printf("  }");
    }

    printf("\n]\n");

    if (nvml_initialized) {
        nvmlShutdown();
    }

    return 0;
}
