#include <stdio.h>

int main() {

    char t;
    int d;
    float sum=0;

    scanf("%c%d", &t, &d);

    if (t == 'E') {
        sum += 3;
    } else if (t == 'L') {
        sum += 6;
    }

    if (d-10 > 0) {
        sum += (d-10)*1;
        d -= d-10;
    }
    if (d-5 > 0) {
        sum += (d-5)*1.25;
        d -= d-5;
    }
    if (d > 0) {
        sum += d*1.5;
    }

    printf("%.2f", sum);

    return 0;
}

