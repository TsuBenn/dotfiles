#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <sched.h>

// Global variables
volatile sig_atomic_t signal_flag = 0; 
struct timespec signal_handled_time;
pthread_t threads[4]; // Global so the forwarder can access it

// Handler for the Worker Threads
void worker_signal_handler(int sig) {
    // This thread was woken up! Set the flag.
    signal_flag = 1;
}

// Handler for the Main Thread (Receives from the Sender)
void main_signal_handler(int sig) {
    // Record the time the signal arrived
    clock_gettime(CLOCK_MONOTONIC, &signal_handled_time);
    
    // UNCONFIDENT SENDER LOGIC: Forward the signal to ALL worker threads!
    for (int i = 0; i < 4; i++) {
        pthread_kill(threads[i], SIGUSR2);
    }
}

void* worker_function(void* arg) {
    int thread_id = *(int*)arg;
    
    while (1) {
        // Same dummy math as confident receiver
        volatile int dummy = 0;
        for (int i = 0; i < 10000; i++) {
            dummy += i;
        }
        
        // Check if the signal handler set the flag
        if (signal_flag == 1) {
            struct timespec current_time;
            clock_gettime(CLOCK_MONOTONIC, &current_time);
            
            long delay_microseconds = (current_time.tv_sec - signal_handled_time.tv_sec) * 1000000 
                                    + (current_time.tv_nsec - signal_handled_time.tv_nsec) / 1000;
            
            printf("Thread %d noticed the event! Delay: %ld microseconds\n", thread_id, delay_microseconds);
            
            // Reset the flag
            signal_flag = 0;
        }
    }
    return NULL;
}

int main() {
    // Setup SIGUSR1 to go to the main handler
    struct sigaction sa_main;
    sa_main.sa_handler = main_signal_handler;
    sigemptyset(&sa_main.sa_mask);
    sa_main.sa_flags = 0;
    sigaction(SIGUSR1, &sa_main, NULL); 

    // Setup SIGUSR2 to go to the worker handler
    struct sigaction sa_worker;
    sa_worker.sa_handler = worker_signal_handler;
    sigemptyset(&sa_worker.sa_mask);
    sa_worker.sa_flags = 0;
    sigaction(SIGUSR2, &sa_worker, NULL); 

    // Pin to Core 0 (Same as before)
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(0, &cpuset);
    pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset);

    int thread_args[4] = {1, 2, 3, 4};

    for (int i = 0; i < 4; i++) {
        pthread_create(&threads[i], NULL, worker_function, &thread_args[i]);
        pthread_setaffinity_np(threads[i], sizeof(cpu_set_t), &cpuset);
    }

    printf("Unconfident Receiver started. PID: %d\n", getpid());
    printf("Main thread doing heavy math. Waiting for signals...\n");

    // Same dummy math as confident receiver
    while (1) {
        volatile int dummy = 0;
        for (int i = 0; i < 100000; i++) {
            dummy += i;
        }
    }

    return 0;
}
