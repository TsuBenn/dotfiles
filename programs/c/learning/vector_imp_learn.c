#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int *data;
    int size;
    int capacity;
} Vector;

int vec_init(Vector *v) {
    v->size = 0;
    v->capacity = 2;
    v->data = malloc(sizeof(int) * v->capacity);
    return v->data != NULL;
}

int vec_push(Vector *v, int value) {
    if (v->size == v->capacity) {
        int new_capacity = v->capacity * 2;
        int *new_data = realloc(v->data, new_capacity * sizeof(int));
        if (new_data == NULL) {
            free(v->data);
            return 0;
        }
        v->data = new_data;
        v->capacity = new_capacity;
    }
    v->data[v->size] = value;
    v->size++;
    return 1;
}

void vec_free(Vector *v) {
    free(v->data);
    v->data = NULL;
    v->size = 0;
    v->capacity = 0;
}

int main() {
    Vector v;
    if (!vec_init(&v)) {
        printf("Something wrong with the init function!");
        return 1;
    }

    for (int i = 1; i <= 5; i++) {
        if (!vec_push(&v, i * 10)) {
            printf("Something wrong with the push function!");
            return 1;
        }
    }

    for (int i = 0; i < v.size; i++) {
        printf("%d\n", v.data[i]);
    }

    vec_free(&v);

    return 0;
}
