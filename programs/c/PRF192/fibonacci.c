#include <stdio.h>

int main() {

    int n, f0=0, f1=1;

    scanf("%d", &n);

    if (n >= 0) {
        printf("0 ");
    }
    if (n >= 1) {
        printf("1 ");
    }
    for (int i = 2; i < n; i++) {
        int now = f0 + f1;
        f0 = f1;
        f1 = now;
        printf("%d ", now);
    }

}

