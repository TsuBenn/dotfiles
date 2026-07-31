#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <ctype.h>
#include <stdbool.h>

#define MAX_PROCS 1024
#define PATH_MAX_LEN 512
#define COMM_MAX_LEN 256

typedef struct {
    int pid;
    char name[COMM_MAX_LEN];
    unsigned long long utime;
    unsigned long long stime;
    double cpu_usage;
    double gpu_usage;
    unsigned long long ram_bytes;
    unsigned long long vram_bytes;
} ProcessInfo;

typedef struct {
    ProcessInfo procs[MAX_PROCS];
    int count;
    unsigned long long total_system_time;
} ProcessSnapshot;

static ProcessSnapshot prev_snapshot = {0};

static inline unsigned long long get_total_cpu_time(void) __attribute__((always_inline));
static inline unsigned long long get_total_cpu_time(void) {
    FILE *fp = fopen("/proc/stat", "r");
    if (!fp) return 0;

    char line[256];
    if (!fgets(line, sizeof(line), fp)) {
        fclose(fp);
        return 0;
    }
    fclose(fp);

    unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
    if (sscanf(line, "cpu %llu %llu %llu %llu %llu %llu %llu %llu",
               &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal) < 8) {
        return 0;
    }

    return user + nice + system + idle + iowait + irq + softirq + steal;
}

static inline unsigned long long get_proc_ram_bytes(int pid) __attribute__((always_inline));
static inline unsigned long long get_proc_ram_bytes(int pid) {
    char path[PATH_MAX_LEN];
    snprintf(path, sizeof(path), "/proc/%d/statm", pid);
    FILE *fp = fopen(path, "r");
    if (!fp) return 0;

    unsigned long size, resident;
    if (fscanf(fp, "%lu %lu", &size, &resident) != 2) {
        fclose(fp);
        return 0;
    }
    fclose(fp);

    static long page_size = 0;
    if (page_size == 0) {
        page_size = sysconf(_SC_PAGESIZE);
        if (page_size <= 0) page_size = 4096;
    }
    return (unsigned long long)resident * page_size;
}

static void update_gpu_and_vram_via_smi(ProcessSnapshot *snap) __attribute__((hot));
static void update_gpu_and_vram_via_smi(ProcessSnapshot *snap) {
    // 1. Fetch GPU compute utilization (%) per PID via nvidia-smi pmon
    FILE *fp_gpu = popen("nvidia-smi pmon -c 1 -s u 2>/dev/null", "r");
    if (fp_gpu) {
        char line[256];
        while (fgets(line, sizeof(line), fp_gpu)) {
            if (line[0] == '#' || line[0] == '\n') continue;
            int idx, pid;
            char type[16], sm_str[16];
            if (sscanf(line, "%d %d %15s %15s", &idx, &pid, type, sm_str) >= 4) {
                if (pid <= 0) continue;
                double sm_val = (sm_str[0] != '-') ? atof(sm_str) : 0.0;
                for (int i = 0; i < snap->count; i++) {
                    if (snap->procs[i].pid == pid) {
                        snap->procs[i].gpu_usage = sm_val;
                        break;
                    }
                }
            }
        }
        pclose(fp_gpu);
    }

    // 2. Fetch exact VRAM usage for ALL (C + G) processes directly from nvidia-smi table
    FILE *fp_vram = popen("nvidia-smi 2>/dev/null", "r");
    if (fp_vram) {
        char line[256];
        bool in_process_table = false;

        while (fgets(line, sizeof(line), fp_vram)) {
            if (strstr(line, "Processes:")) {
                in_process_table = true;
                continue;
            }
            if (!in_process_table) continue;

            char *mib_ptr = strstr(line, "MiB");
            if (!mib_ptr) continue;

            // Extract VRAM (digits right before "MiB")
            char *p = mib_ptr - 1;
            while (p > line && isspace((unsigned char)*p)) p--;
            while (p > line && isdigit((unsigned char)*p)) p--;
            unsigned long long vram_mb = strtoull(p + 1, NULL, 10);

            // Extract PID by anchoring on Type column ('G', 'C', or 'C+G')
            int pid = 0;
            char *type_ptr = strstr(line, " G ");
            if (!type_ptr) type_ptr = strstr(line, " C ");
            if (!type_ptr) type_ptr = strstr(line, " C+G ");

            if (type_ptr) {
                char *pid_p = type_ptr - 1;
                while (pid_p > line && isspace((unsigned char)*pid_p)) pid_p--;
                while (pid_p > line && isdigit((unsigned char)*pid_p)) pid_p--;
                pid = atoi(pid_p + 1);
            }

            if (pid > 0) {
                for (int i = 0; i < snap->count; i++) {
                    if (snap->procs[i].pid == pid) {
                        snap->procs[i].vram_bytes = vram_mb * 1024ULL * 1024ULL;
                        break;
                    }
                }
            }
        }
        pclose(fp_vram);
    }
}

static void capture_snapshot(ProcessSnapshot *snap) __attribute__((hot));
static void capture_snapshot(ProcessSnapshot *snap) {
    snap->count = 0;
    snap->total_system_time = get_total_cpu_time();

    DIR *dir = opendir("/proc");
    if (!dir) return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL && snap->count < MAX_PROCS) {
        if (!isdigit((unsigned char)entry->d_name[0])) continue;

        int pid = atoi(entry->d_name);
        char stat_path[PATH_MAX_LEN];
        snprintf(stat_path, sizeof(stat_path), "/proc/%d/stat", pid);

        FILE *fp = fopen(stat_path, "r");
        if (!fp) continue;

        char buffer[1024];
        if (!fgets(buffer, sizeof(buffer), fp)) {
            fclose(fp);
            continue;
        }
        fclose(fp);

        char *open_paren = strchr(buffer, '(');
        char *close_paren = strrchr(buffer, ')');
        if (!open_paren || !close_paren || open_paren >= close_paren) continue;

        ProcessInfo *proc = &snap->procs[snap->count];
        proc->pid = pid;

        int name_len = close_paren - open_paren - 1;
        if (name_len >= COMM_MAX_LEN) name_len = COMM_MAX_LEN - 1;
        memcpy(proc->name, open_paren + 1, name_len);
        proc->name[name_len] = '\0';

        unsigned long long utime = 0, stime = 0;
        sscanf(close_paren + 2, "%*c %*d %*d %*d %*d %*d %*u %*u %*u %*u %*u %llu %llu", &utime, &stime);

        proc->utime = utime;
        proc->stime = stime;
        proc->ram_bytes = get_proc_ram_bytes(pid);
        proc->vram_bytes = 0;
        proc->cpu_usage = 0.0;
        proc->gpu_usage = 0.0;

        snap->count++;
    }
    closedir(dir);

    update_gpu_and_vram_via_smi(snap);
}

static inline ProcessInfo *find_proc_by_pid(ProcessSnapshot *snap, int pid) __attribute__((always_inline));
static inline ProcessInfo *find_proc_by_pid(ProcessSnapshot *snap, int pid) {
    for (int i = 0; i < snap->count; i++) {
        if (snap->procs[i].pid == pid) return &snap->procs[i];
    }
    return NULL;
}

static void calculate_cpu_usage(ProcessSnapshot *curr, ProcessSnapshot *prev) __attribute__((hot));
static void calculate_cpu_usage(ProcessSnapshot *curr, ProcessSnapshot *prev) {
    if (prev->total_system_time == 0) return;

    unsigned long long system_delta = curr->total_system_time - prev->total_system_time;
    if (system_delta == 0) return;

    static long num_cores = 0;
    if (num_cores == 0) {
        num_cores = sysconf(_SC_NPROCESSORS_ONLN);
        if (num_cores < 1) num_cores = 1;
    }

    for (int i = 0; i < curr->count; i++) {
        ProcessInfo *c = &curr->procs[i];
        ProcessInfo *p = find_proc_by_pid(prev, c->pid);

        if (p) {
            unsigned long long proc_delta = (c->utime + c->stime) - (p->utime + p->stime);
            c->cpu_usage = ((double)proc_delta / (double)system_delta) * 100.0 * num_cores;
        }
    }
}

static int compare_cpu(const void *a, const void *b) {
    double diff = ((ProcessInfo *)b)->cpu_usage - ((ProcessInfo *)a)->cpu_usage;
    return (diff > 0) - (diff < 0);
}

static int compare_gpu(const void *a, const void *b) {
    const ProcessInfo *pa = (const ProcessInfo *)a;
    const ProcessInfo *pb = (const ProcessInfo *)b;

    double gpu_diff = pb->gpu_usage - pa->gpu_usage;
    if (gpu_diff != 0.0) {
        return (gpu_diff > 0) - (gpu_diff < 0);
    }

    long long vram_diff = (long long)pb->vram_bytes - (long long)pa->vram_bytes;
    return (vram_diff > 0) - (vram_diff < 0);
}

static int compare_ram(const void *a, const void *b) {
    long long diff = (long long)((ProcessInfo *)b)->ram_bytes - (long long)((ProcessInfo *)a)->ram_bytes;
    return (diff > 0) - (diff < 0);
}

static int compare_vram(const void *a, const void *b) {
    long long diff = (long long)((ProcessInfo *)b)->vram_bytes - (long long)((ProcessInfo *)a)->vram_bytes;
    return (diff > 0) - (diff < 0);
}

static void emit_json_frame(ProcessSnapshot *curr, ProcessSnapshot *prev, int top_n,
                            double cpu_spike_thresh, double ram_thresh_mb,
                            double gpu_spike_thresh, double vram_thresh_mb,
                            long num_cores) {
    static ProcessInfo sorted_cpu[MAX_PROCS];
    static ProcessInfo sorted_gpu[MAX_PROCS];
    static ProcessInfo sorted_ram[MAX_PROCS];
    static ProcessInfo sorted_vram[MAX_PROCS];

    memcpy(sorted_cpu, curr->procs, sizeof(ProcessInfo) * curr->count);
    memcpy(sorted_gpu, curr->procs, sizeof(ProcessInfo) * curr->count);
    memcpy(sorted_ram, curr->procs, sizeof(ProcessInfo) * curr->count);
    memcpy(sorted_vram, curr->procs, sizeof(ProcessInfo) * curr->count);

    qsort(sorted_cpu, curr->count, sizeof(ProcessInfo), compare_cpu);
    qsort(sorted_gpu, curr->count, sizeof(ProcessInfo), compare_gpu);
    qsort(sorted_ram, curr->count, sizeof(ProcessInfo), compare_ram);
    qsort(sorted_vram, curr->count, sizeof(ProcessInfo), compare_vram);

    printf("{");
    printf("\"core_count\":%ld,", num_cores);

    // 1. top_cpu
    printf("\"top_cpu\":[");
    int limit_cpu = curr->count < top_n ? curr->count : top_n;
    for (int i = 0; i < limit_cpu; i++) {
        printf("{\"pid\":%d,\"name\":\"%s\",\"cpu\":%.1f}",
               sorted_cpu[i].pid, sorted_cpu[i].name, sorted_cpu[i].cpu_usage);
        if (i < limit_cpu - 1) printf(",");
    }
    printf("],");

    // 2. top_gpu
    printf("\"top_gpu\":[");
    int limit_gpu = curr->count < top_n ? curr->count : top_n;
    for (int i = 0; i < limit_gpu; i++) {
        printf("{\"pid\":%d,\"name\":\"%s\",\"gpu\":%.1f}",
               sorted_gpu[i].pid, sorted_gpu[i].name, sorted_gpu[i].gpu_usage);
        if (i < limit_gpu - 1) printf(",");
    }
    printf("],");

    // 3. top_ram
    printf("\"top_ram\":[");
    int limit_ram = curr->count < top_n ? curr->count : top_n;
    for (int i = 0; i < limit_ram; i++) {
        double ram_mb = (double)sorted_ram[i].ram_bytes / (1024.0 * 1024.0);
        printf("{\"pid\":%d,\"name\":\"%s\",\"ram_mb\":%.1f}",
               sorted_ram[i].pid, sorted_ram[i].name, ram_mb);
        if (i < limit_ram - 1) printf(",");
    }
    printf("],");

    // 4. top_vram
    printf("\"top_vram\":[");
    int limit_vram = curr->count < top_n ? curr->count : top_n;
    for (int i = 0; i < limit_vram; i++) {
        double vram_mb = (double)sorted_vram[i].vram_bytes / (1024.0 * 1024.0);
        printf("{\"pid\":%d,\"name\":\"%s\",\"vram_mb\":%.1f}",
               sorted_vram[i].pid, sorted_vram[i].name, vram_mb);
        if (i < limit_vram - 1) printf(",");
    }
    printf("],");

    // 5. cpu_spikes
    printf("\"cpu_spikes\":[");
    bool first = true;
    for (int i = 0; i < curr->count; i++) {
        ProcessInfo *c = &curr->procs[i];
        ProcessInfo *p = find_proc_by_pid(prev, c->pid);
        double prev_cpu = p ? p->cpu_usage : 0.0;
        double delta_cpu = c->cpu_usage - prev_cpu;

        if (delta_cpu >= cpu_spike_thresh) {
            if (!first) printf(",");
            printf("{\"pid\":%d,\"name\":\"%s\",\"delta_cpu\":%.1f}", c->pid, c->name, delta_cpu);
            first = false;
        }
    }
    printf("],");

    // 6. ram_spikes
    printf("\"ram_spikes\":[");
    first = true;
    for (int i = 0; i < curr->count; i++) {
        ProcessInfo *c = &curr->procs[i];
        ProcessInfo *p = find_proc_by_pid(prev, c->pid);
        double prev_ram_mb = p ? (double)p->ram_bytes / (1024.0 * 1024.0) : 0.0;
        double curr_ram_mb = (double)c->ram_bytes / (1024.0 * 1024.0);
        double delta_ram = curr_ram_mb - prev_ram_mb;

        if (delta_ram >= ram_thresh_mb) {
            if (!first) printf(",");
            printf("{\"pid\":%d,\"name\":\"%s\",\"delta_ram_mb\":%.1f}", c->pid, c->name, delta_ram);
            first = false;
        }
    }
    printf("],");

    // 7. gpu_spikes
    printf("\"gpu_spikes\":[");
    first = true;
    for (int i = 0; i < curr->count; i++) {
        ProcessInfo *c = &curr->procs[i];
        ProcessInfo *p = find_proc_by_pid(prev, c->pid);
        double prev_gpu = p ? p->gpu_usage : 0.0;
        double delta_gpu = c->gpu_usage - prev_gpu;

        if (delta_gpu >= gpu_spike_thresh) {
            if (!first) printf(",");
            printf("{\"pid\":%d,\"name\":\"%s\",\"delta_gpu\":%.1f}", c->pid, c->name, delta_gpu);
            first = false;
        }
    }
    printf("],");

    // 8. vram_spikes
    printf("\"vram_spikes\":[");
    first = true;
    for (int i = 0; i < curr->count; i++) {
        ProcessInfo *c = &curr->procs[i];
        ProcessInfo *p = find_proc_by_pid(prev, c->pid);
        double prev_vram_mb = p ? (double)p->vram_bytes / (1024.0 * 1024.0) : 0.0;
        double curr_vram_mb = (double)c->vram_bytes / (1024.0 * 1024.0);
        double delta_vram = curr_vram_mb - prev_vram_mb;

        if (delta_vram >= vram_thresh_mb) {
            if (!first) printf(",");
            printf("{\"pid\":%d,\"name\":\"%s\",\"delta_vram_mb\":%.1f}", c->pid, c->name, delta_vram);
            first = false;
        }
    }
    printf("]}\n");
    fflush(stdout);
}

int main(int argc, char *argv[]) {
    int top_n = 5;
    double cpu_spike_thresh = 40.0;
    double ram_spike_thresh = 500.0;
    double gpu_spike_thresh = 30.0;
    double vram_spike_thresh = 500.0;
    int interval_ms = 1000;

    if (argc > 1) top_n = atoi(argv[1]);
    if (argc > 2) cpu_spike_thresh = atof(argv[2]);
    if (argc > 3) ram_spike_thresh = atof(argv[3]);
    if (argc > 4) gpu_spike_thresh = atof(argv[4]);
    if (argc > 5) vram_spike_thresh = atof(argv[5]);
    if (argc > 6) interval_ms = atoi(argv[6]);

    if (interval_ms < 100) interval_ms = 100;

    useconds_t sleep_us = (useconds_t)interval_ms * 1000;

    long num_cores = sysconf(_SC_NPROCESSORS_ONLN);
    if (num_cores < 1) num_cores = 1;

    static ProcessSnapshot current_snapshot;

    while (1) {
        capture_snapshot(&current_snapshot);
        calculate_cpu_usage(&current_snapshot, &prev_snapshot);

        if (prev_snapshot.total_system_time != 0) {
            emit_json_frame(&current_snapshot, &prev_snapshot, top_n,
                            cpu_spike_thresh, ram_spike_thresh,
                            gpu_spike_thresh, vram_spike_thresh,
                            num_cores);
        }

        prev_snapshot = current_snapshot;
        usleep(sleep_us);
    }

    return 0;
}
