#include <stdio.h>
#include <stdlib.h>

typedef struct String {
    char* buf;
    size_t len;
    size_t capacity;
} string_t;

string_t* string_from(char* init_string) {
    string_t* new_string = malloc(sizeof(string_t));
    new_string->buf = init_string;
    new_string->len = 0;
    new_string->capacity = 0;
    return new_string;
}

string_t* string_new() {
    return string_from("");
}

int main() {
    string_t *str = string_new();

    printf("%s", str->buf);
    return 0;
}
