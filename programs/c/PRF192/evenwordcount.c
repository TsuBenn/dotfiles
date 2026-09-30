#include <stdio.h>

int main() {

    char string[100];
    int in_string = 0, word_count = 0, char_count = 0;

    fgets(string, sizeof(string), stdin);

    for (int i = 0; i < 100 && string[i] != '\0'; i++) {
        if (string[i] == ' ') {
            if (char_count%2==0 && char_count > 0) {
                word_count++;
            }
            char_count = 0;
            continue;
        }
        char_count++;
    }

    if (char_count > 0) {
        word_count++;
    }

    printf("\nOUTPUT:\n%d",word_count);

}

