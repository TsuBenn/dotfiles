#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <ctype.h>
#include <signal.h>
#include <time.h>
#include <sys/types.h>
#include <nvml.h>

static volatile int running = 1;

typedef struct {
    int pid;
    char comm[256];
    unsigned long long utime;
    unsigned long long stime;
    unsigned long rss_kb;
    unsigned long long vram_bytes;
} ProcSample;

void handle_signal(int sig) {
    (void)sig;
    running = 0;
}

unsigned long long get_system_total_ticks(void) {
    FILE *fp = fopen("/proc/stat", "r");
    if (!fp) return 0;

    char line[256];
    if (!fgets(line, sizeof(line), fp)) { fclose(fp); return 0; }
    fclose(fp);

    unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
    sscanf(line, "cpu %llu %llu %llu %llu %llu %llu %llu %llu",
           &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal);

    return user + nice + system + idle + iowait + irq + softirq + steal;
}

int get_proc_info(int pid, ProcSample *sample) {
    char path[64];
    snprintf(path, sizeof(path), "/proc/%d/stat", pid);

    FILE *fp = fopen(path, "r");
    if (!fp) return 0;

    char buf[1024];
    if (fgets(buf, sizeof(buf), fp)) {
        fclose(fp);

        char *start_comm = strchr(buf, '(');
        char *end_comm = strrchr(buf, ')');

        if (start_comm && end_comm && end_comm > start_comm) {
            sample->pid = pid;
            size_t comm_len = end_comm - start_comm - 1;
            if (comm_len > 255) comm_len = 255;
            strncpy(sample->comm, start_comm + 1, comm_len);
            sample->comm[comm_len] = '\0';

            long rss_pages;
            sscanf(end_comm + 2,
                   "%*c %*d %*d %*d %*d %*d %*u %*u %*u %*u %*u "
                   "%llu %llu %*d %*d %*d %*d %*d %*d %*llu %*llu %ld",
                   &sample->utime, &sample->stime, &rss_pages);

            long page_size_kb = sysconf(_SC_PAGESIZE) / 1024;
            sample->rss_kb = rss_pages * page_size_kb;
            return 1;
        }
    } else {
        fclose(fp);
    }
    return 0;
}

void attach_nvml_vram(ProcSample *samples, int sample_count) {
    nvmlDevice_t device;
    if (nvmlDeviceGetHandleByIndex(0, &device) != NVML_SUCCESS) return;

    unsigned int info_count = 0;
    nvmlDeviceGetComputeRunningProcesses(device, &info_count, NULL);
    if (info_count == 0) return;

    nvmlProcessInfo_t *infos = malloc(sizeof(nvmlProcessInfo_t) * info_count);
    if (!infos) return;

    if (nvmlDeviceGetComputeRunningProcesses(device, &info_count, infos) == NVML_SUCCESS) {
        for (unsigned int i = 0; i < info_count; i++) {
            for (int j = 0; j < sample_count; j++) {
                if (samples[j].pid == (int)infos[i].pid) {
                    samples[j].vram_bytes = infos[i].usedGpuMemory;
                    break;
                }
            }
        }
    }
    free(infos);
}

int main(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handle_signal;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);

    int nvml_available = (nvmlInit() == NVML_SUCCESS);
    int num_cores = sysconf(_SC_NPROCESSORS_ONLN);

    // CSV Header
    printf("timestamp,pid,comm,cpu_percent,ram_kb,vram_mb\n");
    fflush(stdout);

    while (running) {
        time_t now = time(NULL);
        unsigned long long sys_total_1 = get_system_total_ticks();

        DIR *dir = opendir("/proc");
        if (!dir) break;

        struct dirent *entry;
        ProcSample samples[2048];
        int count = 0;

        while ((entry = readdir(dir)) != NULL && count < 2048) {
            if (isdigit(entry->d_name[0])) {
                int pid = atoi(entry->d_name);
                if (get_proc_info(pid, &samples[count])) {
                    samples[count].vram_bytes = 0;
                    count++;
                }
            }
        }
        closedir(dir);

        if (nvml_available) {
            attach_nvml_vram(samples, count);
        }

        sleep(1);

        unsigned long long sys_total_2 = get_system_total_ticks();
        unsigned long long sys_delta = sys_total_2 - sys_total_1;

        for (int i = 0; i < count; i++) {
            ProcSample second_sample;
            if (get_proc_info(samples[i].pid, &second_sample)) {
                unsigned long long proc_delta = (second_sample.utime + second_sample.stime) -
                                                 (samples[i].utime + samples[i].stime);

                float cpu_percent = 0.0f;
                if (sys_delta > 0) {
                    cpu_percent = ((float)proc_delta / sys_delta) * 100.0f * num_cores;
                }

                // Filtering: skip idle background noise
                if (cpu_percent > 0.5f || samples[i].vram_bytes > 0) {
                    printf("%ld,%d,%s,%.1f,%lu,%llu\n",
                           now,
                           samples[i].pid,
                           samples[i].comm,
                           cpu_percent,
                           samples[i].rss_kb,
                           samples[i].vram_bytes / (1024 * 1024));
                }
            }
        }
        fflush(stdout); // Keep line stream responsive
    }

    if (nvml_available) {
        nvmlShutdown();
    }

    return 0;
}
