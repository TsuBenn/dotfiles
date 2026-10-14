#include <iostream>

using namespace std;

int fun(int x) {
    if (x < 2) return 1;
    return (x-1)*fun(x-1);
}

int main() {
    cout << fun(3)+fun(4);
    return 0;
}
