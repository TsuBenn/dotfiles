#include <stdio.h>


int main() {

    int n;

    scanf("%d", &n);

    int arr[n];

    for (int i = 0; i < n; i++) {
        scanf("%d",&arr[i]);
    }

    for (int sorted = 0; sorted < n;) {
        for (int i = 0; i < n; i++) {
            if (arr[i+1] < arr[i]) {
                int temp = arr[i];
                arr[i] = arr[i+1];
                arr[i+1] = temp;
                sorted = 0;
                continue;
            }
            sorted += 1;
        }
    }

    if (n%2==0) {
        printf("%.2f", (float) (arr[(int)(n/2.0)]+arr[(int)(n/2.0-1)])/2.0);
    } else {
        printf("%.2f", (float) arr[(int) ((n-1)/2.0)]);
    }

    return 0;
}

