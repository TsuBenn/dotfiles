#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <ctype.h>
#include <time.h>
#include <nvml.h>

#define MAX_CORES 64
#define MAX_PROCS 1024
#define HISTORY_LEN 10
#define TOP_N 5

#define SPIKE_MULTIPLIER 4.0
#define CPU_SPIKE_FLOOR 15.0   /* percent */
#define RAM_SPIKE_FLOOR 200.0  /* MB jump worth flagging */
#define GPU_SPIKE_FLOOR 200.0  /* MB jump worth flagging */

/* ─── Per-core CPU (unchanged from original) ──────────────────────────── */

typedef struct {
    unsigned long long idle;
    unsigned long long total;
} CPUData;

void read_cpu_data(CPUData *data, int *core_count) {
    FILE *fp = fopen("/proc/stat", "r");
    if (!fp) {
        perror("Failed to open /proc/stat");
        exit(EXIT_FAILURE);
    }
    char line[256];
    *core_count = 0;
    while (fgets(line, sizeof(line), fp)) {
        if (strncmp(line, "cpu", 3) == 0 && line[3] >= '0' && line[3] <= '9') {
            unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
            sscanf(line, "%*s %llu %llu %llu %llu %llu %llu %llu %llu",
                   &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal);
            data[*core_count].idle = idle + iowait;
            data[*core_count].total = user + nice + system + idle + iowait + irq + softirq + steal;
            (*core_count)++;
            if (*core_count >= MAX_CORES) break;
        }
    }
    fclose(fp);
}

/* ─── Per-process tracking ─────────────────────────────────────────────
 *
 * One entry per pid we've seen. Ring buffers hold recent samples for
 * each metric so we can compute a rolling baseline and flag spikes.
 * `active` is reset to 0 at the start of each poll and set to 1 when
 * we see the pid again — anything left at 0 after the scan is a dead
 * process and gets evicted from the table.
 */

typedef struct {
    int in_use;
    int pid;
    char name[128];

    unsigned long long prev_ticks;
    int has_prev_ticks;

    double cpu_history[HISTORY_LEN];
    double ram_history[HISTORY_LEN];
    double gpu_history[HISTORY_LEN];
    int history_count;   /* how many samples collected so far (caps at HISTORY_LEN) */
    int history_idx;     /* ring buffer write position */

    double last_cpu_pct;
    double last_ram_mb;
    double last_gpu_mb;
    int has_gpu_sample;  /* not every process shows up in the NVML scan */

    int active;          /* seen this poll? used for eviction */
} ProcEntry;

static ProcEntry proc_table[MAX_PROCS];
static int proc_table_count = 0;
static long clock_ticks_per_sec;
static int num_cores_online;

/* Find an existing entry for pid, or create one in a free slot.
 * Linear scan is fine here -- a few hundred processes, once per second,
 * is negligible compared to the /proc file I/O itself. */
static ProcEntry *get_or_create_entry(int pid) {
    for (int i = 0; i < proc_table_count; i++) {
        if (proc_table[i].in_use && proc_table[i].pid == pid) {
            return &proc_table[i];
        }
    }
    for (int i = 0; i < MAX_PROCS; i++) {
        if (!proc_table[i].in_use) {
            memset(&proc_table[i], 0, sizeof(ProcEntry));
            proc_table[i].in_use = 1;
            proc_table[i].pid = pid;
            if (i >= proc_table_count) proc_table_count = i + 1;
            return &proc_table[i];
        }
    }
    return NULL; /* table full -- silently drop, shouldn't happen at MAX_PROCS=1024 */
}

/* Push a new sample into a metric's ring buffer. */
static void push_history(double *hist, int *count, int *idx, double value) {
    hist[*idx] = value;
    *idx = (*idx + 1) % HISTORY_LEN;
    if (*count < HISTORY_LEN) (*count)++;
}

static double history_average(const double *hist, int count) {
    if (count == 0) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < count; i++) sum += hist[i];
    return sum / count;
}

/* Read /proc/[pid]/stat: process name + utime+stime ticks.
 * Returns 1 on success, 0 if the process vanished mid-scan. */
static int read_proc_stat(int pid, char *name_out, size_t name_len, unsigned long long *ticks_out) {
    char path[64];
    snprintf(path, sizeof(path), "/proc/%d/stat", pid);
    FILE *fp = fopen(path, "r");
    if (!fp) return 0;

    char buf[512];
    if (!fgets(buf, sizeof(buf), fp)) { fclose(fp); return 0; }
    fclose(fp);

    /* Name is inside parens and can itself contain spaces/parens,
     * so find the LAST ')' rather than naive whitespace splitting. */
    char *lparen = strchr(buf, '(');
    char *rparen = strrchr(buf, ')');
    if (!lparen || !rparen || rparen < lparen) return 0;

    size_t nlen = (size_t)(rparen - lparen - 1);
    if (nlen >= name_len) nlen = name_len - 1;
    memcpy(name_out, lparen + 1, nlen);
    name_out[nlen] = '\0';

    /* Fields after the ')' are space-separated, state is field 3 (index 0
     * here), utime is field 14 / stime is field 15 -- i.e. offsets 11/12
     * counting from state. */
    char *rest = rparen + 2; /* skip ") " */
    unsigned long long utime = 0, stime = 0;
    int field = 0;
    char *tok = strtok(rest, " ");
    while (tok) {
        if (field == 11) utime = strtoull(tok, NULL, 10);
        if (field == 12) { stime = strtoull(tok, NULL, 10); break; }
        field++;
        tok = strtok(NULL, " ");
    }
    *ticks_out = utime + stime;
    return 1;
}

/* Read /proc/[pid]/status VmRSS line, in MB. Returns -1 if unreadable. */
static double read_proc_rss_mb(int pid) {
    char path[64];
    snprintf(path, sizeof(path), "/proc/%d/status", pid);
    FILE *fp = fopen(path, "r");
    if (!fp) return -1.0;

    char line[256];
    double rss_mb = -1.0;
    while (fgets(line, sizeof(line), fp)) {
        if (strncmp(line, "VmRSS:", 6) == 0) {
            long kb = 0;
            sscanf(line + 6, "%ld", &kb);
            rss_mb = kb / 1024.0;
            break;
        }
    }
    fclose(fp);
    return rss_mb;
}

static double read_mem_total_mb(void) {
    FILE *fp = fopen("/proc/meminfo", "r");
    if (!fp) return 1.0; /* avoid div-by-zero if unreadable */
    char line[256];
    double total_mb = 1.0;
    while (fgets(line, sizeof(line), fp)) {
        if (strncmp(line, "MemTotal:", 9) == 0) {
            long kb = 0;
            sscanf(line + 9, "%ld", &kb);
            total_mb = kb / 1024.0;
            break;
        }
    }
    fclose(fp);
    return total_mb;
}

/* ─── Top-N insertion (fixed-size, no full sort needed) ────────────────
 *
 * Keeps a small sorted-descending array of size TOP_N as we scan.
 * Cheaper than collecting every process then sorting the whole list,
 * since TOP_N is tiny and the insert-and-shift cost per candidate is
 * bounded regardless of how many total processes exist.
 */

typedef struct {
    int pid;
    char name[128];
    double value;
} TopEntry;

static void top_insert(TopEntry *top, int *top_count, int pid, const char *name, double value) {
    if (*top_count < TOP_N) {
        int i = (*top_count)++;
        while (i > 0 && top[i - 1].value < value) {
            top[i] = top[i - 1];
            i--;
        }
        top[i].pid = pid;
        top[i].value = value;
        strncpy(top[i].name, name, sizeof(top[i].name) - 1);
        top[i].name[sizeof(top[i].name) - 1] = '\0';
    } else if (value > top[TOP_N - 1].value) {
        int i = TOP_N - 1;
        while (i > 0 && top[i - 1].value < value) {
            top[i] = top[i - 1];
            i--;
        }
        top[i].pid = pid;
        top[i].value = value;
        strncpy(top[i].name, name, sizeof(top[i].name) - 1);
        top[i].name[sizeof(top[i].name) - 1] = '\0';
    }
}

/* ─── Spike collection ──────────────────────────────────────────────────
 *
 * A spike is: current sample >= baseline * SPIKE_MULTIPLIER AND
 * current sample >= an absolute floor (so a jump from near-zero to
 * near-zero-but-4x doesn't count as noise).
 */

typedef struct {
    int pid;
    char name[128];
    char metric[8]; /* "cpu" | "ram" | "gpu" */
    double value;
    double baseline;
} SpikeEntry;

#define MAX_SPIKES 32
static SpikeEntry spikes[MAX_SPIKES];
static int spike_count = 0;

static void maybe_flag_spike(int pid, const char *name, const char *metric,
                              double value, double baseline, double floor) {
    if (spike_count >= MAX_SPIKES) return;
    if (baseline <= 0.0) return; /* no baseline yet, first sample -- can't be a spike */
    if (value >= baseline * SPIKE_MULTIPLIER && value >= floor) {
        SpikeEntry *s = &spikes[spike_count++];
        s->pid = pid;
        strncpy(s->name, name, sizeof(s->name) - 1);
        s->name[sizeof(s->name) - 1] = '\0';
        strncpy(s->metric, metric, sizeof(s->metric) - 1);
        s->metric[sizeof(s->metric) - 1] = '\0';
        s->value = value;
        s->baseline = baseline;
    }
}

/* Minimal JSON string escaping -- process names are very unlikely to
 * contain quotes/backslashes, but don't emit broken JSON if they do. */
static void print_json_string(const char *s) {
    putchar('"');
    for (const char *p = s; *p; p++) {
        if (*p == '"' || *p == '\\') putchar('\\');
        if ((unsigned char)*p >= 0x20) putchar(*p);
    }
    putchar('"');
}

/* ─── NVML (NVIDIA only) ────────────────────────────────────────────────
 *
 * Gives us a pre-filtered list of {pid, usedGpuMemory} directly from
 * the driver -- no need to check every pid for GPU usage, only the
 * ones the driver already knows are using it.
 */

static int nvml_ready = 0;
static unsigned int nvml_device_count = 0;

static void init_nvml(void) {
    nvmlReturn_t result = nvmlInit();
    if (result != NVML_SUCCESS) {
        fprintf(stderr, "nvml: init failed (%s) -- GPU tracking disabled\n",
                nvmlErrorString(result));
        nvml_ready = 0;
        return;
    }
    if (nvmlDeviceGetCount(&nvml_device_count) != NVML_SUCCESS) {
        nvml_device_count = 0;
    }
    nvml_ready = 1;
}

/* Cross-reference NVML's pid list against proc_table for a display name,
 * update each pid's gpu history + last_gpu_mb, and populate top_gpu. */
static void sample_gpu(TopEntry *top_gpu, int *top_gpu_count) {
    *top_gpu_count = 0;
    if (!nvml_ready) return;

    for (unsigned int i = 0; i < nvml_device_count; i++) {
        nvmlDevice_t device;
        if (nvmlDeviceGetHandleByIndex(i, &device) != NVML_SUCCESS) continue;

        unsigned int info_count = 64;
        nvmlProcessInfo_t infos[64];
        nvmlReturn_t r = nvmlDeviceGetComputeRunningProcesses(device, &info_count, infos);
        if (r != NVML_SUCCESS && r != NVML_ERROR_INSUFFICIENT_SIZE) continue;

        for (unsigned int j = 0; j < info_count && j < 64; j++) {
            int pid = (int)infos[j].pid;
            double vram_mb = infos[j].usedGpuMemory / (1024.0 * 1024.0);

            ProcEntry *e = get_or_create_entry(pid);
            char name_buf[128] = "";
            if (e && e->name[0]) {
                strncpy(name_buf, e->name, sizeof(name_buf) - 1);
            } else {
                unsigned long long dummy_ticks;
                read_proc_stat(pid, name_buf, sizeof(name_buf), &dummy_ticks);
            }

            if (e) {
                e->last_gpu_mb = vram_mb;
                e->has_gpu_sample = 1;
                double baseline = history_average(e->gpu_history, e->history_count);
                push_history(e->gpu_history, &e->history_count, &e->history_idx, vram_mb);
                maybe_flag_spike(pid, name_buf, "gpu", vram_mb, baseline, GPU_SPIKE_FLOOR);
            }

            top_insert(top_gpu, top_gpu_count, pid, name_buf, vram_mb);
        }
    }
}

/* ─── Main per-process scan ─────────────────────────────────────────────
 *
 * Walks /proc for numeric-named directories (each one a live pid),
 * updates CPU%/RAM for each, maintains top-5 tables, and flags spikes.
 * dt is the poll interval in seconds -- since the main loop sleeps a
 * fixed interval before each pass, this is accurate enough without
 * needing a per-pid wall-clock timestamp.
 */

static void scan_processes(double dt, TopEntry *top_cpu, int *top_cpu_count,
                            TopEntry *top_ram, int *top_ram_count) {
    *top_cpu_count = 0;
    *top_ram_count = 0;
    spike_count = 0;

    double mem_total_mb = read_mem_total_mb();

    /* Mark all entries unseen; anything still unseen after the scan
     * is a dead process and gets evicted below. */
    for (int i = 0; i < proc_table_count; i++) {
        proc_table[i].active = 0;
    }

    DIR *dir = opendir("/proc");
    if (!dir) return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (!isdigit((unsigned char)entry->d_name[0])) continue;
        int pid = atoi(entry->d_name);

        char name[128];
        unsigned long long ticks;
        if (!read_proc_stat(pid, name, sizeof(name), &ticks)) continue;

        ProcEntry *e = get_or_create_entry(pid);
        if (!e) continue;
        e->active = 1;
        strncpy(e->name, name, sizeof(e->name) - 1);
        e->name[sizeof(e->name) - 1] = '\0';

        if (e->has_prev_ticks) {
            unsigned long long tick_delta = ticks - e->prev_ticks;
            double cpu_pct = ((double)tick_delta / clock_ticks_per_sec) / dt
                              * 100.0 / num_cores_online;
            if (cpu_pct < 0) cpu_pct = 0;

            double baseline = history_average(e->cpu_history, e->history_count);
            push_history(e->cpu_history, &e->history_count, &e->history_idx, cpu_pct);
            maybe_flag_spike(pid, name, "cpu", cpu_pct, baseline, CPU_SPIKE_FLOOR);

            e->last_cpu_pct = cpu_pct;
            top_insert(top_cpu, top_cpu_count, pid, name, cpu_pct);
        }
        e->prev_ticks = ticks;
        e->has_prev_ticks = 1;

        double rss_mb = read_proc_rss_mb(pid);
        if (rss_mb >= 0) {
            double baseline = history_average(e->ram_history, e->history_count);
            push_history(e->ram_history, &e->history_count, &e->history_idx, rss_mb);
            maybe_flag_spike(pid, name, "ram", rss_mb, baseline, RAM_SPIKE_FLOOR);

            e->last_ram_mb = rss_mb;
            top_insert(top_ram, top_ram_count, pid, name, rss_mb);
        }
    }
    closedir(dir);

    /* Evict dead processes so the table doesn't grow forever as things
     * come and go throughout the day. */
    for (int i = 0; i < proc_table_count; i++) {
        if (proc_table[i].in_use && !proc_table[i].active) {
            proc_table[i].in_use = 0;
        }
    }

    (void)mem_total_mb; /* used by caller for % conversion at print time */
}

/* ─── Output ────────────────────────────────────────────────────────────*/

static void print_top_array(const char *key, TopEntry *arr, int count, const char *unit) {
    printf("\"%s\":[", key);
    for (int i = 0; i < count; i++) {
        printf("{\"pid\":%d,\"name\":", arr[i].pid);
        print_json_string(arr[i].name);
        printf(",\"%s\":%.2f}%s", unit, arr[i].value, (i < count - 1) ? "," : "");
    }
    printf("]");
}

int main(int argc, char *argv[]) {
    int interval_ms = 1000;
    if (argc > 1) {
        interval_ms = atoi(argv[1]);
        if (interval_ms < 50) {
            fprintf(stderr, "Warning: Interval too small. Setting minimum to 50ms.\n");
            interval_ms = 50;
        }
    }

    struct timespec sleep_time;
    sleep_time.tv_sec = interval_ms / 1000;
    sleep_time.tv_nsec = (interval_ms % 1000) * 1000000L;
    double dt = interval_ms / 1000.0;

    clock_ticks_per_sec = sysconf(_SC_CLK_TCK);
    num_cores_online = (int)sysconf(_SC_NPROCESSORS_ONLN);
    if (num_cores_online < 1) num_cores_online = 1;

    init_nvml();

    CPUData prev[MAX_CORES] = {0};
    CPUData curr[MAX_CORES] = {0};
    int core_count = 0;
    read_cpu_data(prev, &core_count);

    /* Prime the per-process tick baseline once before the loop so the
     * very first real sample has something to diff against, same idea
     * as the core baseline above. */
    scan_processes(dt, (TopEntry[TOP_N]){0}, &(int){0}, (TopEntry[TOP_N]){0}, &(int){0});

    while (1) {
        nanosleep(&sleep_time, NULL);
        read_cpu_data(curr, &core_count);

        TopEntry top_cpu[TOP_N] = {0};
        TopEntry top_ram[TOP_N] = {0};
        TopEntry top_gpu[TOP_N] = {0};
        int top_cpu_count = 0, top_ram_count = 0, top_gpu_count = 0;

        double mem_total_mb = read_mem_total_mb();
        scan_processes(dt, top_cpu, &top_cpu_count, top_ram, &top_ram_count);
        sample_gpu(top_gpu, &top_gpu_count);

        printf("{\"count\":%d,\"cores\":[", core_count);
        for (int i = 0; i < core_count; i++) {
            unsigned long long total_diff = curr[i].total - prev[i].total;
            unsigned long long idle_diff = curr[i].idle - prev[i].idle;
            double usage = 0.0;
            if (total_diff > 0) {
                usage = (double)(total_diff - idle_diff) / total_diff * 100.0;
            }
            printf("%.2f%s", usage, (i < core_count - 1) ? "," : "");
        }
        printf("],");

        print_top_array("top_cpu", top_cpu, top_cpu_count, "cpu_pct");
        printf(",");
        printf("\"top_ram\":[");
        for (int i = 0; i < top_ram_count; i++) {
            double pct = (top_ram[i].value / mem_total_mb) * 100.0;
            printf("{\"pid\":%d,\"name\":", top_ram[i].pid);
            print_json_string(top_ram[i].name);
            printf(",\"rss_mb\":%.1f,\"rss_pct\":%.1f}%s",
                   top_ram[i].value, pct, (i < top_ram_count - 1) ? "," : "");
        }
        printf("],");
        print_top_array("top_gpu", top_gpu, top_gpu_count, "vram_mb");
        printf(",");

        printf("\"spikes\":[");
        for (int i = 0; i < spike_count; i++) {
            printf("{\"pid\":%d,\"name\":", spikes[i].pid);
            print_json_string(spikes[i].name);
            printf(",\"metric\":\"%s\",\"value\":%.2f,\"baseline\":%.2f}%s",
                   spikes[i].metric, spikes[i].value, spikes[i].baseline,
                   (i < spike_count - 1) ? "," : "");
        }
        printf("]}\n");

        fflush(stdout);
        memcpy(prev, curr, sizeof(CPUData) * core_count);
    }

    return 0;
}
