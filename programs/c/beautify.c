#include <stdio.h>

int main() {
    char str[] = "@hello student 2024         semeter!";
    int in_word = 0;

    for (int i=0; str[i]!='\0';i++) {
        if ((str[i] >= 'a' && str[i] <= 'z' ) || (str[i] >= 'A' && str[i] <= 'Z')) {
            if (!in_word) {
                in_word = 1;
                if (str[i] >= 'a' && str[i] <= 'z' ) {
                    str[i] -= 32;
                }
            } else if (str[i] >= 'A' && str[i] <= 'Z' ) {
                str[i] += 32;
            }
            continue;
        }
        if (str[i] == ' ' && in_word) {
            in_word = 0;
            continue;
        } else {
            str[i] = '#';
            continue;
        }
        str[i] = '#';
    }

    for (int i=0; str[i]!='\0';i++) {
        if (str[i] != '#') {
            printf("%c", str[i]);
        }
    }

    return 0;
}

