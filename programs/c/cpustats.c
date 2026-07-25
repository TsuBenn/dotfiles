#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

#define MAX_CORES 64

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

int main(int argc, char *argv[]) {
    int interval_ms = 1000; // Default: 1000ms (1 second)

    // Check if the user passed a custom interval argument
    if (argc > 1) {
        interval_ms = atoi(argv[1]);
        if (interval_ms < 50) {
            fprintf(stderr, "Warning: Interval too small. Setting minimum to 50ms.\n");
            interval_ms = 50;
        }
    }

    // Convert milliseconds to seconds and nanoseconds for nanosleep
    struct timespec sleep_time;
    sleep_time.tv_sec = interval_ms / 1000;
    sleep_time.tv_nsec = (interval_ms % 1000) * 1000000L;

    CPUData prev[MAX_CORES] = {0};
    CPUData curr[MAX_CORES] = {0};
    int core_count = 0;

    read_cpu_data(prev, &core_count);

    while (1) {
        nanosleep(&sleep_time, NULL);
        read_cpu_data(curr, &core_count);

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

        printf("]}\n");
        fflush(stdout);

        memcpy(prev, curr, sizeof(CPUData) * core_count);
    }

    return 0;
}
