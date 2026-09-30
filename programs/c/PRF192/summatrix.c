#include <stdio.h>

int main() {

    int sum;

    for (int i = 0; i < 9; i++) {
        int temp;
        scanf("%d", &temp);
        if (i != 4) {
            sum += temp;
        }
    }

    printf("%d",sum);

}

