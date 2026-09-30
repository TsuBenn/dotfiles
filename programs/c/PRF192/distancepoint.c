#include <stdio.h>

int main() {

    typedef struct {
        int x;
        int y;
    } Point;

    Point points[5];
    int max = 0;
    int max_point = 0;

    for (int i = 0; i < 5; i++) {
        int x;
        int y;
        scanf("%d%d",&x, &y);
        points[i].x = x;
        points[i].y = y;
        if (max < x + y) {
            max = x + y;
            max_point = i;
        }
    }

    printf("(%d,%d)",points[max_point].x,points[max_point].y);

}
