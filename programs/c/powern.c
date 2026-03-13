#include <stdio.h>

int main() {

    int n, i=0, digit[10], res=0;

    scanf("%d", &n);

    while (n > 0) {
        digit[i++] = n%10;
        n /= 10;
    }

    for (int j = 0; j < i; j++) {
        int init = digit[j];
        for (int k = 0; k < i-1; k++) {
            digit[j] *= init;
        }
        res += digit[j];
    }

    printf("OUTPUT:\n%d",res);

}

