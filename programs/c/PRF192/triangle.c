#include <stdio.h>

int main() {

    int n;

    scanf("%d",&n);

    printf("\nOUTPUT:\n");
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (j == n-1 - i || i == n-1 || j == n-1) {
                printf("x");
            } else printf(" ");
        }
        printf("\n");
    }

}
