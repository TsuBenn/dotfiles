#include <iostream>

using namespace std;

class Vector2d {
public:

    float x , y;

    Vector2d() {
        x = 0;
        y = 0;
    }

    Vector2d(const float x, const float y) {
        this->x = x;
        this->y = y;
    }

    Vector2d operator+(const Vector2d &other) const {
        return Vector2d(x + other.x, y + other.y);
    }

    Vector2d operator-(const Vector2d &other) const {
        return Vector2d(x - other.x, y - other.y);
    }

    Vector2d operator*(const float scalar) const {
        return Vector2d(x*scalar , y*scalar);
    }

    bool operator==(const Vector2d &other) const {
        return x == other.x && y == other.y;
    }

    Vector2d& operator=(const Vector2d &other) {
        x = other.x;
        y = other.y;
        return *this;
    }

    // Prefix-increment ++a
    Vector2d& operator++() {
        x += 1;
        y += 1;
        return *this;
    }

    // Postfix-increment a++
    Vector2d operator++(int) {
        Vector2d result = *this;
        x += 1;
        y += 1;
        return result;
    }

    friend istream& operator>>(istream &is, Vector2d &vector) {
        cout << "x: ";
        is >> vector.x;
        cout << "y: ";
        is >> vector.y;
        return cin;
    }

    friend ostream& operator<<(ostream &os, const Vector2d &vector) {
        os << "(" << vector.x << "," << vector.y << ")";
        return cout;
    }


};

int main() {

    Vector2d a(5, 10);

    Vector2d b(6,  7);

    a = b;

    cout << a << endl;

    Vector2d c;

    cin >> c;

    cout << c << endl;

    return 0;

}
