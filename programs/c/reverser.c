#include <stdio.h>
#include <string.h>

int main() {

    char str[100];

    printf("INPUT:\n");
    fgets(str, sizeof(str), stdin);

    int size = strlen(str)-1, vowels=0;
    char rstr[100];

    rstr[size] = '\0';

    for (int i = 0; i < size; i++) {
        switch (str[i]) {
            case 'a': case 'i': case 'u': case 'e': case 'o': case 'A': case 'I': case 'U': case 'E': case 'O': vowels++; break;
        }
        rstr[i] = str[size - i - 1];
    }

    char nospace[100];
    int j = 0;
    for (int i = 0; i < size; i++) {
        if (rstr[i] == ' ') {continue;}
        nospace[j++] = rstr[i];
    }

    printf("OUTPUT:\nVowels: %d\n%s", vowels, nospace);

}

