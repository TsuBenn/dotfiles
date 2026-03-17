#include <stdio.h>

int main() {

    char str[100];

    fgets(str, sizeof(str), stdin);

    char chr;

    scanf("%c",&chr);

    printf("\nOUTPUT:\n");
    for (int i = 0; str[i] != '\0'; i++) {
        if (chr == str[i]) {
            printf("%d ", i);
        }
    }

}

