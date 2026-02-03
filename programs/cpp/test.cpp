#include <stdio.h>


int F(int n) {
    if (n == 0) return 0;
    if (n == 1) return 1;
    return F(n-1) + F(n-2);
}

int sum(int a, int b) {
    return a + b;
}

int sum(int a, int b, int c) {
    return a + b + c;
}



int main() {

    printf("%d", sum(5, 5, 5));

    return 0;
}

