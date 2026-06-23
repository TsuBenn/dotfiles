#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>

// This is the function that each thread will run.
// A thread function must return a void pointer and take a void pointer as an argument.
void* worker_function(void* arg) {
    // We cast the void pointer back to an integer pointer, then dereference it to get the ID.
    int thread_id = *(int*)arg;
    
    printf("Hello from Thread %d! I am now running.\n", thread_id);
    
    // Simulate some work by sleeping for 1 second
    sleep(1);
    
    printf("Thread %d is done working and will now exit.\n", thread_id);
    
    // We must return something when the thread finishes. NULL is fine for now.
    return NULL;
}

int main() {
    // We will create 2 threads. We need arrays to store their IDs and their arguments.
    pthread_t threads[2];
    int thread_args[2] = {1, 2}; // Arguments to pass to each thread
    
    printf("Main program started. Creating threads...\n");

    // Loop to create the threads
    for (int i = 0; i < 2; i++) {
        // pthread_create does the magic:
        // &threads[i]      -> Where to store the thread ID
        // NULL             -> Default thread attributes (we don't need special settings)
        // worker_function  -> The function the thread should run
        // &thread_args[i]  -> The argument to pass to the function
        int result = pthread_create(&threads[i], NULL, worker_function, &thread_args[i]);
        
        // Always check if thread creation failed!
        if (result != 0) {
            printf("Error: Failed to create thread %d\n", i);
            return 1;
        }
    }

    printf("Main program is waiting for threads to finish...\n");

    // Loop to wait for the threads to finish
    for (int i = 0; i < 2; i++) {
        // pthread_join blocks the main program until the specified thread finishes.
        // NULL means we don't care about the return value of the thread right now.
        pthread_join(threads[i], NULL);
    }

    printf("All threads finished. Main program exiting.\n");
    return 0;
}
