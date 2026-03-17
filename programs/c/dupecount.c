#include <stdio.h>

int main() {
    int n, arr[100];
    scanf("%d",&n);

    for (int i = 0; i < n; i++) {
        scanf("%d",&arr[i]);
    }

    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n-1-i; j++) {
            if (arr[j] > arr[j+1]) {
                int tmp = arr[j];
                arr[j] = arr[j+1];
                arr[j+1] = tmp;
            }
        }
    }

    printf("\nOUTPUT:\n");
    char curr = 0;
    int count = 0;
    for (int i = 0; i < n; i++) {
        if (arr[i] != curr) {
            if (count == 2) {
                printf("%d\n", curr);
            }
            curr = arr[i];
            count = 1;
        } else {
            count++;
        }
    }
    if (count == 2) {
        printf("%d\n", curr);
    }

}

