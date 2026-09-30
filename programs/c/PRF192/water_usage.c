#include <stdio.h>

int main() {

    double water_usage, sum;

    scanf("%lf",&water_usage);

    if (water_usage >= 8) {
        sum = 5 * 3000 + 4 * 5000 + (water_usage - 9) * 7000;
    }
    else if (water_usage >= 5) {
        sum = 5 * 3000 + (water_usage - 5) * 5000;
    }
    else {
        sum = water_usage * 3000;
    }

    printf("OUTPUT:\n%.2lf", sum);

}
