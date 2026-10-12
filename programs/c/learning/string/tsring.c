#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tsring.h"

static size_t string_new_capacity(size_t current, size_t target) {
  size_t new = current;
  if (new == 0) {
    new = 8;
  }
  while (new < target) {
    if (new > SIZE_MAX / 2) {
      return 0;
    }
    new *= 2;
  }
  return new;
}

static int string_expand_capacity(string_t *str, size_t new_size) {
  return string_reserve(str, string_new_capacity(str->capacity, new_size));
}

int string_reserve(string_t* str, size_t new_capacity) {
  if (new_capacity <= str->capacity) {
    return 1;
  }
  if (new_capacity > SIZE_MAX - 1) {
    fprintf(stderr, "string_reserve (new_capacity: Capacity too large!)");
    return 0;
  }
  char *new_buf = realloc(str->buf, sizeof(char) * (new_capacity + 1));
  if (!new_buf) {
    perror("string_reserve (new_buf: realloc)");
    return 0;
  }
  str->buf = new_buf;
  str->capacity = new_capacity;
  return 1;
}

string_t *string_from_buf(char *buf, size_t size) {
  if (*buf == '\0' || size == 0) {
    free(buf);
    return string_new();
  }
  string_t *new_string = malloc(sizeof(string_t));
  if (!new_string) {
    perror("string_from_buf (new_string: malloc)");
    return NULL;
  }
  new_string->buf = buf;
  new_string->buf[size] = '\0';
  new_string->len = size;
  new_string->capacity = size;

  return new_string;
}

string_t *string_from(const char *string) {
  size_t new_len = strlen(string);
  size_t init_capacity = string_new_capacity(0, new_len);

  char *new_buf = malloc(sizeof(char) * (init_capacity + 1));
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

string_t *string_new(void) { return string_from(""); }

void string_free(string_t *string) {
  if (!string) {
    return;
  }
  free(string->buf);
  free(string);
}

void string_debug(const string_t *str) {
  printf("string ->\n%s\nlen -> %zu\ncapacity -> %zu\n\n", str->buf, str->len,
         str->capacity);
}

int string_eq_string(const string_t *str, const string_t *other_str) {
  if (str->len != other_str->len) {
    return 0;
  }
  return strcmp(str->buf, other_str->buf) == 0;
}

int string_eq_str(const string_t *str, const char *other_str) {
  if (str->len != strlen(other_str)) {
    return 0;
  }
  return strcmp(str->buf, other_str) == 0;
}

void string_clear(string_t *str) {
  if (str->len == 0) {
    return;
  }
  str->buf[0] = '\0';
  str->len = 0;
}

int string_push_string(string_t *str, const string_t *other_str) {
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

int string_push_str(string_t *str, const char *other_str) {
  size_t other_len = strlen(other_str);
  size_t new_len = str->len + other_len;
  if (new_len > str->capacity) {
    if (!string_expand_capacity(str, new_len)) {
      return 0;
    }
  }
  memcpy(str->buf + str->len, other_str, other_len + 1);
  str->len = new_len;
  return 1;
}

int string_remove_back(string_t *str, size_t size) {
  if (str->len < size) {
    return 0;
  }
  size_t new_len = str->len - size;
  str->buf[new_len] = '\0';
  str->len = new_len;
  return 1;
}

int string_remove_front(string_t *str, size_t size) {
  if (str->len < size) {
    return 0;
  }
  size_t new_len = str->len - size;
  memmove(str->buf, str->buf + size, new_len + 1);
  str->len = new_len;
  return 1;
}

string_t *string_slice(const string_t *str, size_t start, size_t end) {
  if (end > str->len)
    end = str->len;
  if (start >= end) {
    return string_new();
  }
  size_t sliced_len = end - start;
  char *sliced_buf = malloc(sizeof(char) * (sliced_len + 1));
  if (!sliced_buf) {
    perror("string_slice (sliced_buf: malloc)");
    return NULL;
  }
  memcpy(sliced_buf, str->buf + start, sliced_len);
  sliced_buf[sliced_len] = '\0';
  string_t *sliced_string = string_from(sliced_buf);
  free(sliced_buf);
  return sliced_string;
}

int string_insert(string_t *str, const string_t *other_str, size_t position) {
  if (position > str->len) {
    return 0;
  }
  size_t new_len = str->len + other_str->len;
  if (new_len > str->capacity) {
    if (!string_expand_capacity(str, new_len)) {
      return 0;
    }
  }
  memmove(str->buf + position + other_str->len, str->buf + position,
          str->len - position + 1);
  memcpy(str->buf + position, other_str->buf, other_str->len);
  str->len = new_len;
  return 1;
}

string_t *string_clone(const string_t *str) { return string_from(str->buf); }

int string_path_join(string_t *str, const string_t *other_str) {
  if (other_str->len == 0) {
    return 0;
  }

  int str_has_slash = str->len > 0 && str->buf[str->len - 1] == '/';
  int other_has_slash = other_str->len > 0 && other_str->buf[0] == '/';

  const char *tail = other_str->buf;
  size_t tail_len = other_str->len;
  int need_slash = 0;

  if (str_has_slash && other_has_slash) {
    tail++;
    tail_len--;
  } else if (!str_has_slash && !other_has_slash) {
    need_slash = 1;
  }

  size_t new_len = str->len + need_slash + tail_len;
  if (new_len > str->capacity) {
    if (!string_expand_capacity(str, new_len)) {
      return 0;
    }
  }

  size_t pos = str->len;
  if (need_slash) {
    str->buf[pos++] = '/';
  }

  memcpy(str->buf + pos, tail, tail_len + 1);
  str->len = new_len;
  return 1;
}

string_t *string_path_filename(const string_t *str) {
  if (str->len == 0) {
    return string_new();
  }
  if (str->len == 1 && str->buf[0] == '/')
    return string_from("/");
  int is_dir = str->buf[str->len - 1] == '/';
  size_t end = str->len - is_dir;
  size_t start = end;
  for (size_t i = 1; i <= end; i++) {
    if (str->buf[end - i] == '/') {
      break;
    }
    start--;
  }
  return string_slice(str, start, end);
}

static size_t string_get_dot_position(const string_t *str) {
  size_t end = str->len;
  size_t dot = end;
  for (size_t i = 1; i <= end; i++) {
    if (str->buf[end - i] == '.' && end - i > 0 &&
        str->buf[end - i - 1] != '/' && str->buf[end - i - 1] != '.') {
      dot = end - i;
      break;
    }
    if (str->buf[end - i] == '/') {
      break;
    }
  }
  return dot;
}

string_t *string_path_stem(const string_t *str) {
  if (str->len == 0) {
    return string_new();
  }
  if (str->len == 1 && str->buf[0] == '/')
    return string_from("/");
  if (str->buf[str->len - 1] == '/') {
    return string_clone(str);
  }
  size_t dot = string_get_dot_position(str);
  return string_slice(str, 0, dot);
}

string_t *string_path_get_extension(const string_t *str) {
  if (str->len == 0) {
    return string_new();
  }
  if (str->buf[str->len - 1] == '/') {
    return NULL;
  }
  size_t dot = string_get_dot_position(str);
  if (dot == str->len) {
    return string_new();
  }
  return string_from(str->buf + dot + 1);
}

int string_path_add_extension(string_t *str, const char *ext) {
  int ok = 0;
  string_t *str_ext = string_path_get_extension(str);
  if (!str_ext) {
    return 0;
  }

  int has_dot = ext[0] == '.';

  string_t *extension = has_dot ? string_new() : string_from(".");
  if (!extension) {
    string_free(str_ext);
    return 0;
  }

  if (!string_push_str(extension, ext)) {
    ok = 0;
    goto cleanup;
  }


  if ((has_dot && strcmp(str_ext->buf, ext + 1) == 0) ||
      (!has_dot && strcmp(str_ext->buf, ext) == 0)) {
    ok = 1;
    goto cleanup;
  }

  ok = string_push_string(str, extension);

cleanup:
  string_free(str_ext);
  string_free(extension);
  return ok;
}

int string_contains_string(const string_t *str, const string_t *pat, size_t *match_postion) {
  return string_contains_str(str, pat->buf, match_postion);
}

int string_contains_str(const string_t *str, const char* pat, size_t *match_postion) {
  char* substring = strstr(str->buf, pat);
  if (substring && match_postion) {
    *match_postion = substring - str->buf;
  }
  return substring != NULL;
}

string_t* string_read_from_file(const char* file_path) {
  FILE *f = fopen(file_path, "r");
  if (!f) {
    perror("string_read_from_file (f: fopen)");
    return NULL;
  }

  fseek(f, 0, SEEK_END);
  long len = ftell(f);
  rewind(f);

  if (len < 0) {
    fclose(f);
    fprintf(stderr, "string_read_from_file (l < 0)");
    return NULL;
  }

  char* buf = malloc(len+1);
  if (!buf) {
    fclose(f);
    fprintf(stderr, "string_read_from_file (buf: malloc)");
    return NULL;
  }

  size_t read_bytes = fread(buf, 1, len, f);
  if (read_bytes != (size_t)len) {
    free(buf);
    fclose(f);
    fprintf(stderr, "string_read_from_file (read_bytes: fread)");
    return NULL;
  }

  buf[len] = '\0';
  fclose(f);

  return string_from_buf(buf, (size_t) len);
}

string_t* string_read_line(const string_t* str, string_t* buf, size_t* offset) {
  int end_of_string = 0;
  for (size_t i = 0;;i++) {
    if (str->buf[i+*offset] == '\0') {
      if (i == 0) {
        return NULL;
      }
      end_of_string = 1;
      goto read_line;
    }
    if (str->buf[i+*offset] == '\n') {
      if (i == 0) {
        string_clear(buf);
        *offset += 1;
        return buf;
      }
      goto read_line;
    }
    continue;
    read_line:
    if (!string_reserve(buf, i + 1)) {
      return NULL;
    }
    buf->len = i;
    memcpy(buf->buf, (char *)str->buf + *offset, i);
    buf->buf[i] = '\0';
    *offset += i+1-end_of_string;
    return buf;
  }
}

void string_to_lowercase(string_t* str) {
  for (size_t i = 0; i < str->len; i++) {
    if (str->buf[i] >= 65 && str->buf[i] <= 90 ) {
      str->buf[i] += 32;
    }
  }
}

void string_to_uppercase(string_t* str) {
  for (size_t i = 0; i < str->len; i++) {
    if (str->buf[i] >= 97 && str->buf[i] <= 122) {
      str->buf[i] -= 32;
    }
  }
}

