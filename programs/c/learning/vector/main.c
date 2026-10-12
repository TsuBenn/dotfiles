#include "vec.h"
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#define loop(range) for(size_t i = 0; i < range; i++)

int main() {
    vec_t* vec = vec_new_t(int);

    vec_resize(vec, 10, NULL);
    // loop(10) {
    //     int x = i;
    //     *vec_get_t(vec, i, int) = x;
    // }

    vec_t* vec1 = vec_new_t(int);

    for (size_t i = 0; i < vec->len; i++) {
        printf("[%d]\n", *vec_get_t(vec, i, int));
    }
    printf("Vector length          : %zu\n", vec->len);
    printf("Vector capacity        : %zu\n", vec->capacity);
    printf("Vector allocation count: %zu\n", vec->alloc_count);

    vec_free(vec);
    vec_free(vec1);
    return 0;
}
