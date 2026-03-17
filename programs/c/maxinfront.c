#include <stdio.h>

int main() {

    int n, r = 0, a = 0, b = 1;

    scanf("%d",&n);

    for (int i = n; i > 0;) {
        if (i%10 < a) {
            b *= 10;
            r = r*10 + i%10;
        } else {
            r = ((r/b) + i%10*(r > 0 ? 10 : 1))*b;
        }
        a = i%10;
        i /= 10;
    }
    if (r < 100) {
        r *= 10;
    }
    printf("%d",r);

}

