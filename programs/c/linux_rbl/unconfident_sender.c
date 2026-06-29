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
    
    printf("Unconfident Sender started. Sending SIGUSR1 to PID %d every 5ms...\n", target_pid);
    printf("Press Ctrl+C to stop.\n");

    for (int i = 0; i < 20; i++) {
        kill(target_pid, SIGUSR1);
        usleep(5000); 
    }

    printf("Sender finished sending signals.\n");
    return 0;
}
