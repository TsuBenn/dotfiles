#include <stdio.h>

int main() {

    char s[100];

    int a=0, c=0, inword=0;

    fgets(s, sizeof(s), stdin);

    for (int i = 0; s[i] != '\0'; i++) {
        if (!inword && s[i] != ' ') {
            inword = 1;
            if (s[i] == 'a' || s[i] == 'A') {
                a++;
            }
        } else if (s[i] == ' ') {
            inword = 0;
        }
        c++;
    }

    printf("\nOUTPUT:\n");
    if (a > 0) {
        printf("%d",a);
    } else {
        printf("%d",c-1);
    }

}
