#include <security/pam_appl.h>
#include <security/pam_misc.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// PAM conversation callback
int my_conv(int num_msg, const struct pam_message **msg,
            struct pam_response **resp, void *appdata_ptr) {
    
    struct pam_response *reply = calloc(num_msg, sizeof(struct pam_response));
    if (reply == NULL) return PAM_BUF_ERR;

    for (int i = 0; i < num_msg; i++) {
        if (msg[i]->msg_style == PAM_PROMPT_ECHO_OFF) {
            reply[i].resp = strdup((char *)appdata_ptr);
            reply[i].resp_retcode = 0;
        }
    }
    *resp = reply;
    return PAM_SUCCESS;
}

int check_password(const char *username, const char *password) {
    pam_handle_t *pamh = NULL;
    struct pam_conv local_conversation = { my_conv, (void *)password };

    int retval = pam_start("login", username, &local_conversation, &pamh);
    if (retval == PAM_SUCCESS) {
        retval = pam_authenticate(pamh, 0);
    }
    pam_end(pamh, retval);

    return (retval == PAM_SUCCESS) ? 1 : 0;
}

int main() {
    // 1. Get current system user once at startup
    const char *user = getenv("USER");
    if (user == NULL) user = getlogin();
    if (user == NULL) {
        printf("0\n");
        fflush(stdout);
        return 1;
    }

    char pass[256];

    // 2. Continuous Loop: Keep running until stdin is closed (EOF)
    // This happens automatically if the UI application crashes or closes its write pipe.
    while (explicit_bzero(pass, sizeof(pass)), fgets(pass, sizeof(pass), stdin) != NULL) {
        
        // Strip trailing newlines cleanly
        pass[strcspn(pass, "\n")] = 0;
        pass[strcspn(pass, "\r")] = 0;

        // Skip empty lines (e.g. accidental extra newlines sent down the pipe)
        if (strlen(pass) == 0) {
            continue;
        }

        // 3. Authenticate and respond
        if (check_password(user, pass)) {
            printf("1\n");
        } else {
            printf("0\n");
        }

        // 4. Force stdout to flush immediately so the UI application gets the result right away
        fflush(stdout);

        // Security: Clear the buffer immediately before looping back for the next input
        explicit_bzero(pass, sizeof(pass));
    }

    return 0;
}
