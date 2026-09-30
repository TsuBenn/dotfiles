#include <stdio.h>

int main() {

    int x, n, sum=0;

    scanf("%d%d",&x,&n);

    for (int i = 1; i <= n; i++) {
        int pow = 1;
        for (int j = 0; j < i; j++) {
            pow *= x;
        }
        sum += pow;
    }

    printf("\nOUTPUT:\n%d", sum);

}

