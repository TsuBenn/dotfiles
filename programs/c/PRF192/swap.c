#include <stdio.h>

void swap(double *a, double *b) {
    double temp = *a;
    *a = *b;
    *b = temp;
}

int main() {

    double a, b;

    printf("INPUT:\n");

    scanf("%lf%lf",&a,&b);

    swap(&a,&b);

    printf("\nOUTPUT:\n%.2lf %.2lf", a, b);

}

