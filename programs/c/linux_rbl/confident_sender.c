#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>

struct SharedData {
    volatile int signal_flag;
    struct timespec send_time;
};

int main() {
    shm_unlink("/rbl_shared_mem"); 
    int shm_fd = shm_open("/rbl_shared_mem", O_CREAT | O_RDWR, 0666);
    if (shm_fd == -1) {
        perror("Failed to create shared memory");
        return 1;
    }
    
    ftruncate(shm_fd, sizeof(struct SharedData));
    
    struct SharedData* shared_data = mmap(NULL, sizeof(struct SharedData), 
                                          PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
    
    shared_data->signal_flag = 0;

    printf("Confident Sender started. Shared memory created.\n");
    printf("Waiting 5 seconds for you to start the receiver in another terminal...\n");
    sleep(5); 

    printf("Sending events...\n");

    for (int i = 0; i < 20; i++) {
        // Record exact time we "send" the event
        clock_gettime(CLOCK_MONOTONIC, &shared_data->send_time);
        
        // Set the flag
        shared_data->signal_flag = 1;
        
        // Sleep 5ms
        usleep(5000);
        
        // CHANGED: We no longer reset the flag here. The Receiver does it.
    }

    printf("Sender finished. Cleaning up shared memory.\n");
    
    // Give receiver a second to finish printing
    sleep(1);
    
    // Clean up
    munmap(shared_data, sizeof(struct SharedData));
    close(shm_fd);
    shm_unlink("/rbl_shared_mem");
    
    return 0;
}
