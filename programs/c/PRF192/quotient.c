#include <stdio.h>
#include <stdlib.h>

int main() {

    int num1 ,num2;

    printf("INPUT\n");
    scanf("%d%d",&num1,&num2);

    printf("\nOUTPUT:\n");
    if (num2 == 0) {
        printf("Division by zero is not allowed");
    } else {
        printf("%d", num1/num2);
    }

}

