#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>
#include <sched.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>

struct SharedData {
    volatile int signal_flag;
    struct timespec send_time;
};

void* worker_function(void* arg) {
    int thread_id = *(int*)arg;
    
    // CHANGED: Open as O_RDWR (Read/Write) so we can reset the flag!
    int shm_fd = shm_open("/rbl_shared_mem", O_RDWR, 0666);
    if (shm_fd == -1) {
        perror("Failed to open shared memory");
        return NULL;
    }
    
    // CHANGED: Map it with PROT_WRITE as well
    struct SharedData* shared_data = mmap(NULL, sizeof(struct SharedData), 
                                          PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
    
    while (1) {
        // Do dummy math
        volatile int dummy = 0;
        for (int i = 0; i < 10000; i++) {
            dummy += i;
        }
        
        // THE CONFIDENT RECEIVER: Check the shared memory directly!
        if (shared_data->signal_flag == 1) {
            
            // CHANGED: Immediately set the flag to 0 so we don't process it twice!
            shared_data->signal_flag = 0;
            
            struct timespec current_time;
            clock_gettime(CLOCK_MONOTONIC, &current_time);
            
            // Calculate delay
            long delay_microseconds = (current_time.tv_sec - shared_data->send_time.tv_sec) * 1000000 
                                    + (current_time.tv_nsec - shared_data->send_time.tv_nsec) / 1000;
            
            printf("Thread %d noticed the event! Delay: %ld microseconds\n", thread_id, delay_microseconds);
        }
    }
    return NULL;
}

int main() {
    // Pin main thread to Core 0
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(0, &cpuset);
    pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset);

    // Create 4 worker threads
    pthread_t threads[4];
    int thread_args[4] = {1, 2, 3, 4};

    for (int i = 0; i < 4; i++) {
        pthread_create(&threads[i], NULL, worker_function, &thread_args[i]);
        pthread_setaffinity_np(threads[i], sizeof(cpu_set_t), &cpuset);
    }

    printf("Confident Receiver started. PID: %d\n", getpid());
    printf("Main thread doing heavy math. Waiting for shared memory updates...\n");

    // Main thread does heavy math to compete for CPU
    while (1) {
        volatile int dummy = 0;
        for (int i = 0; i < 100000; i++) {
            dummy += i;
        }
    }

    return 0;
}
