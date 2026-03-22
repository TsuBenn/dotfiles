#include <stdio.h>

int main() {

    char s[100], f[100];
    int in_word = 0, count, buffer_index=0, check = 0;
    char buffer[100];

    fgets(s, sizeof(s), stdin);
    fgets(f, sizeof(f), stdin);

    for (int i = 0; s[i] != '\0'; i++) {
        if (s[i] >= 'A' && s[i] <= 'Z') {
            s[i] += 32;
        } else if (s[i] == '\n') {
            s[i] = '\0';
        }
    }
    for (int i = 0; f[i] != '\0'; i++) {
        if (f[i] >= 'A' && f[i] <= 'Z') {
            f[i] += 32;
        } else if (f[i] == '\n') {
            f[i] = '\0';
        }
    }

    for (int i = 0;; i++) {
        if (s[i] == ' ' || s[i] == '\0') {
            buffer[buffer_index] = s[i];
            buffer_index = 0;
            in_word = 0;
            for (int j = 0; f[j] != '\0'; j++) {
                if (buffer[j] == ' ') {
                    check = 0;
                    break;
                }
                if (f[j] == buffer[j]) {
                    check = 1;
                } else {
                    check = 0;
                    break;
                }
            }
            if (check) {
                check = 0;
                count++;
            }
            if (s[i] == '\0') {
                break;
            }
            continue;
        }
        if (!in_word && s[i] != ' ') {
            in_word = 1;
        }
        if (in_word) {
            buffer[buffer_index++] = s[i];
        }
    }

    printf("%d", count);

}
