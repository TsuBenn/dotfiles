#include <stdio.h>

#define s scanf
#define p printf

int main() {

    int a, b, c;
    s("%d%d%d",&a,&b,&c);

    p("\nOUTPUT:\n%.2f",(a+b)*c/2.0);

}

