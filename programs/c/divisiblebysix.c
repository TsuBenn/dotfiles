#include <stdio.h>

int main() {

    int n;

    scanf("%d", &n);

    int arr[n];

    for (int i = 0; i < n; i++) {
        scanf("%d", &arr[i]);
    }

    for (int i = 0; i < n; i++) {
        if (arr[i]%6==0) {
            printf("Yes ");
        } else {
            printf("No ");
        }
    }

    return 0;
}

