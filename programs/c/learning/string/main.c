#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct String {
    char* buf;
    size_t len;
    size_t capacity;
} string_t;

size_t string_new_capacity(size_t current, size_t target) {
  size_t new = current;
  if (new == 0) {
    new = 8;
  }
  while (new < target) {
    new *= 2;
  }
  return new;
}


int string_expand_capacity(string_t* str, size_t new_size) {
  size_t new_capacity = string_new_capacity(str->capacity, new_size);
  char* new_buf = realloc(str->buf, sizeof(char)*(new_capacity+1));
  if (!new_buf) {
      perror("string_push_string (new_buf: realloc)");
      return 0;
  }
  str->buf = new_buf;
  str->capacity = new_capacity;
  return 1;
}

string_t* string_from(const char* string) {
  size_t new_len = strlen(string);
  size_t init_capacity = string_new_capacity(0, new_len);

  char* new_buf = malloc(sizeof(char) * init_capacity+1);
  if (!new_buf) {
    perror("string_from (new_buf: malloc)");
    return NULL;
  }
  strcpy(new_buf, string);

  string_t *new_string = malloc(sizeof(string_t));
  if (!new_string) {
    perror("string_from (new_string: malloc)");
    free(new_buf);
    return NULL;
  }

  new_string->buf = new_buf;
  new_string->len = new_len;
  new_string->capacity = init_capacity;

  return new_string;
}

string_t* string_new(void) {
    return string_from("");
}

void string_free(string_t* string) {
  if (!string) {
    return;
  }
  free(string->buf);
  free(string);
}

void string_debug(const string_t* str) {
    printf("------------------------------------------\nString:\n\"%s\"\n\nLength: %zu\nCapacity: %zu\n------------------------------------------\n\n", str->buf, str->len, str->capacity);
}

int string_eq(const string_t* str, const string_t* other_str) {
  if (str->len != other_str->len) {
    return 0;
  }
  return strcmp(str->buf, other_str->buf) == 0;
}

void string_clear(string_t* str) {
  if (str->len == 0) {
    return;
  }
  str->buf[0] = '\0';
  str->len = 0;
}

int string_push_string(string_t* str, const string_t* other_str) {
    size_t new_len = str->len + other_str->len;
    if (new_len > str->capacity) {
      if (!string_expand_capacity(str, new_len)) {
        return 0;
      }
    }
    memcpy(str->buf + str->len, other_str->buf, other_str->len + 1);
    str->len = new_len;
    return 1;
}

int string_push_str(string_t* str, const char* other_str) {
    size_t new_len = str->len + strlen(other_str);
    if (new_len > str->capacity) {
      if (!string_expand_capacity(str, new_len)) {
        return 0;
      }
    }
    memcpy(str->buf + str->len, other_str, strlen(other_str) + 1);
    str->len = new_len;
    return 1;
}

int string_remove_back(string_t* str, size_t size) {
  if (str->len < size) {
    return 0;
  }
  size_t new_len = str->len - size;
  str->buf[new_len] = '\0';
  str->len = new_len;
  return 1;
}

int string_remove_front(string_t* str, size_t size) {
  if (str->len < size) {
    return 0;
  }
  size_t new_len = str->len - size;
  memcpy(str->buf, str->buf + size, new_len+1);
  str->len = new_len;
  return 1;
}

string_t* string_slice(const string_t* str, size_t start, size_t end) {
  if (end > str->len) end = str->len;
  if (start >= end) {
    return string_new();
  }
  size_t sliced_len = end-start;
  char* sliced_buf = malloc(sliced_len + 1);
  if (!sliced_buf) {
    perror("string_slice (sliced_buf: malloc)");
    return NULL;
  }
  memcpy(sliced_buf, str->buf + start, sliced_len);
  sliced_buf[sliced_len] = '\0';
  string_t* sliced_string = string_from(sliced_buf);
  free(sliced_buf);
  return sliced_string;
}

int string_insert(string_t* str, const string_t* other_str, size_t position) {
  if (position > str->len) {
    return 0;
  }
  size_t new_len = str->len + other_str->len;
  if (new_len > str->capacity) {
      if (!string_expand_capacity(str, new_len)) {
        return 0;
      }
  }
  memmove(str->buf + position + other_str->len, str->buf + position, str->len - position + 1);
  memcpy(str->buf + position, other_str->buf, other_str->len);
  str->len = new_len;
  return 1;
}

string_t* string_clone(const string_t* str) {
  return string_from(str->buf);
}

int string_path_join(string_t* str, const string_t* other_str) {
  if (other_str->len == 0) {
    return 0;
  }
  if (str->len == 0) {
    goto add_slash;
  }
  if (
    (str->buf[str->len-1] == '/' && other_str->buf[0] != '/') ||
    (str->buf[str->len-1] != '/' && other_str->buf[0] == '/')
  ) {
    return string_push_string(str, other_str);
  } else if (str->buf[str->len-1] == '/' && other_str->buf[0] == '/') {
    string_remove_back(str, 1);
    return string_push_string(str, other_str);
  } else {
    add_slash:
    if (!string_push_str(str, "/")) {
      return 0;
    }
    return string_push_string(str, other_str);
  }
}

int main() {

  string_t* str = string_from("0123456789");
  string_t* to_insert = string_from("bruh");

  string_insert(str, to_insert, 9);

  string_debug(str);

  string_free(str);
  string_free(to_insert);

  return 0;
}
