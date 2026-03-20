#include <stdio.h>

int main() {

    int x, y, maxX = 0, maxY = 0;

    for (int i = 0; i < 5; i++) {
        scanf("%d%d", &x, &y);

        if (x > maxX) {
            maxX = x;
            maxY = y;
        }
    }

    printf ("\nOUTPUT:\nMax X: Point(%d,%d)",maxX,maxY);

}

