#include <stdio.h>

int main() {

    int n, sum;
    scanf("%d", &n);

    for (int i = 0; i < n; i++) {
        int tmp;
        scanf("%d", &tmp);

        if (tmp%2 != 0) {
            sum += tmp;
        }

    }

    if (sum > 0) {
        printf("\nOUTPUT:\n%d",sum);
    } else {
        printf("\nThere are no ood numbers in the %d element", n);
    }

}

