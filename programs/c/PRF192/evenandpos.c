#include <stdio.h>

int main() {

    int n[5], count = 0;

    for (int i = 0; i < 5; i++) {
        scanf("%d",&n[i]);
        if (n[i]%2 == 0 && n[i] > 0) {
            count++;
        }
    }

    printf("\nOUTPUT:\n%d", count);

}

