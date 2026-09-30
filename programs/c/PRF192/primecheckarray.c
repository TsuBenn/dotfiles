#include <stdio.h>

int isPrime(int n) {
    if (n<2) return 0;
    for (int i = 2; i*i <= n; i++) {
        if (n%i==0) {
            return 0;
        }
    }
    return 1;
}

int main() {

    int n, prime_count;

    printf("INPUT:\n");

    scanf("%d",&n);

    for (int i = 0; i < n; i++) {
        int num;
        scanf("%d", &num);
        if (isPrime(num) == 1) {
            prime_count++;
        }
    }

    printf("\nOUTPUT:\n%d", prime_count);


}

