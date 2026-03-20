#include <stdio.h>

int main() {

    int a, b;

    scanf("%d%d",&a, &b);

    printf("\nOUTPUT:\n");
    for (int i = a>b ? a : b; i > 0; i--) {
        if (a%i==0 && b%i==0) {
            printf("%d",i);
            break;
        }
    }

}

