#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    int capacity = 2;
    int size = 0;
    int *data = malloc(capacity * sizeof(int));
    if (data == NULL) {
        return 1;
    }

    for (int i = 0; i < 5; i ++) {
        if (size == capacity) {
            int new_capacity = capacity * 2;
            int *tmp = realloc(data, new_capacity * sizeof(int));
            if (tmp == NULL) {
                free(data);
                return 1;
            }
            data = tmp;
            capacity = new_capacity;
        }
        data[size] = i * 10;
        size++;
    }

    for (int i = 0; i < size; i++) {
        printf("%d\n", data[i]);
    }

    free(data);
    return 0;
}
