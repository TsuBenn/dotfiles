#include <stdio.h>

int main() {

    char c = 'A';
    int n;

    scanf("%d",&n);

    printf("\nOUTPUT:\n");
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (j<=n-1-i) {
                printf("%c ", c);
                c += 1;
            } else printf("  ");
        }
        printf("\n");
    }

}

