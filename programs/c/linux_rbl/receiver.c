#define _GNU_SOURCE // Required for CPU affinity macros
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <sched.h>

// Global variables so both the signal handler and threads can see them
volatile sig_atomic_t signal_flag = 0; 
struct timespec signal_handled_time;

// 1. THE SIGNAL HANDLER
// When the OS delivers a signal, it interrupts a thread and runs this function.
void sigusr1_handler(int sig) {
    // Record the exact time the signal was handled
    clock_gettime(CLOCK_MONOTONIC, &signal_handled_time);
    
    // Set a flag to tell the worker threads "Hey! A signal arrived!"
    signal_flag = 1;
}

// 2. THE WORKER THREAD FUNCTION
void* worker_function(void* arg) {
    int thread_id = *(int*)arg;
    
    // Infinite loop doing dummy math
    while (1) {
        volatile int dummy = 0;
        for (int i = 0; i < 10000; i++) {
            dummy += i;
        }
        
        // Check if the signal handler set the flag
        if (signal_flag == 1) {
            struct timespec current_time;
            clock_gettime(CLOCK_MONOTONIC, &current_time);
            
            // Calculate the delay in microseconds
            long delay_microseconds = (current_time.tv_sec - signal_handled_time.tv_sec) * 1000000 
                                    + (current_time.tv_nsec - signal_handled_time.tv_nsec) / 1000;
            
            printf("Thread %d noticed the signal! Delay: %ld microseconds\n", thread_id, delay_microseconds);
            
            // Reset the flag
            signal_flag = 0;
        }
    }
    return NULL;
}

int main() {
    // SETUP SIGNAL HANDLER (Same as before)
    struct sigaction sa;
    sa.sa_handler = sigusr1_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGUSR1, &sa, NULL); 

    // SETUP CPU AFFINITY (Same as before)
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(0, &cpuset);
    pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset);

    // Create 4 worker threads (Same as before)
    pthread_t threads[4];
    int thread_args[4] = {1, 2, 3, 4};

    for (int i = 0; i < 4; i++) {
        pthread_create(&threads[i], NULL, worker_function, &thread_args[i]);
        pthread_setaffinity_np(threads[i], sizeof(cpu_set_t), &cpuset);
    }

    printf("Receiver process started. PID: %d\n", getpid());
    printf("Main thread is now doing heavy math. Waiting for signals...\n");

    // CHANGED: Main thread now does heavy math to compete for CPU time!
    while (1) {
        volatile int dummy = 0;
        for (int i = 0; i < 100000; i++) {
            dummy += i;
        }
    }

    return 0;
}
