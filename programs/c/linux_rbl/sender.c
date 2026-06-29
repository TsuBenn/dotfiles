#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <time.h>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage: %s <PID of Receiver>\n", argv[0]);
        return 1;
    }

    int target_pid = atoi(argv[1]);
    
    printf("Sender started. Sending SIGUSR1 to PID %d every 5ms...\n", target_pid);
    printf("Press Ctrl+C to stop.\n");

    // Send 20 signals total
    for (int i = 0; i < 20; i++) {
        // Send the signal
        kill(target_pid, SIGUSR1);
        
        // Sleep for 5 milliseconds (5000 microseconds)
        usleep(5000); 
    }

    printf("Sender finished sending signals.\n");
    return 0;
}
