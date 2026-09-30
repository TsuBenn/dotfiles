#include <stdio.h>

int main() {

    int matrix[9];

    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            scanf("%d", &matrix[j*3+i]);
        }
    }

    printf("\n");

    for (int i = 0; i < 9; i++) {
        printf("%d ", matrix[i]);
        if ((i+1)%3==0) printf("\n");
    }

}

