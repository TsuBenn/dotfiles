#include <stdio.h>

int main() {

    int n;

    scanf("%d",&n);

    int arr[n];
    int even[n], index = 0;

    for (int i = 0; i < n; i++) {
        scanf("%d", &arr[i]);
    }

    for (int i = 0; i < n-1; i++) {
        for (int j = 0; j < n-1-i; j++) {
            if (arr[j] > arr[j+1]) {
                int tmp = arr[j];
                arr[j] = arr[j+1];
                arr[j+1] = tmp;
            }
        }
    }

    printf("\nOUPUT:\n");
    for (int i = 0; i < n; i++) {
        if (arr[i]%2==0) printf("%d\n", arr[i]);
    }

}

