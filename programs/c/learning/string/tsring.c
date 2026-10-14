#include <errno.h>
#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdarg.h>

#include "tsring.h"

int check_buf(string_t* buf) {
  if (!buf) {
    buf = string_new(64);
  }
  if (!buf) {
    return 0;
  }
  return 1;
}

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
  return string_reserve(str, string_new_capacity(str->cap, new_size));
}

int string_reserve(string_t *str, size_t new_capacity) {
  if (new_capacity <= str->cap) {
    return 1;
  }
  if (new_capacity > SIZE_MAX - 1) {
    fprintf(stderr, "string_reserve (new_capacity: How did we get here?!)");
    return 0;
  }
  char *new_buf = realloc(str->buf, sizeof(char) * (new_capacity + 1));
  if (!new_buf) {
    perror("string_reserve (new_buf: realloc)");
    return 0;
  }
  str->buf = new_buf;
  str->cap = new_capacity;
  return 1;
}

string_t *string_from_buf(char *buf, size_t size) {
  if (*buf == '\0' || size == 0) {
    free(buf);
    return string_new(8);
  }
  string_t *new_string = malloc(sizeof(string_t));
  if (!new_string) {
    perror("string_from_buf (new_string: malloc)");
    free(buf);
    return NULL;
  }
  new_string->buf = buf;
  new_string->buf[size] = '\0';
  new_string->len = size;
  new_string->cap = size;

  return new_string;
}

string_t *string_new(size_t init_cap) {
  char *new_buf = malloc(sizeof(char) * (init_cap + 1));
  if (!new_buf) {
    perror("string_from (new_buf: malloc)");
    return NULL;
  }

  string_t *new_string = malloc(sizeof(string_t));
  if (!new_string) {
    perror("string_from (new_string: malloc)");
    free(new_buf);
    return NULL;
  }

  new_string->buf = new_buf;
  new_string->buf[0] = '\0';
  new_string->len = 0;
  new_string->cap = init_cap;

  return new_string;
}

string_t *string_from(const char *str) {
  size_t new_len = strlen(str);
  string_t* new_string = string_new(new_len);
  if (!new_string) {
    return NULL;
  }
  memcpy(new_string->buf, str, new_len);
  new_string->len = new_len;
  return new_string;
}

void string_free(string_t *string) {
  if (!string) {
    return;
  }
  free(string->buf);
  free(string);
}

void string_debug(const string_t *str) {
  printf("string ->\n%s\nlen -> %zu\ncapacity -> %zu\n\n", str->buf, str->len,
         str->cap);
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

int string_push(string_t *str, const char *other_str, size_t other_len) {
  size_t new_len = str->len + other_len;
  if (new_len > str->cap) {
    if (!string_expand_capacity(str, new_len)) {
      return 0;
    }
  }
  memcpy(str->buf + str->len, other_str, other_len + 1);
  str->len = new_len;
  return 1;
}

int string_push_string(string_t *str, const string_t *other_str) {
  return string_push(str, other_str->buf, other_str->len);
}

int string_push_str(string_t *str, const char *other_str) {
  return string_push(str, other_str, strlen(other_str));
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
    return string_new(0);
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

static int string_insert(string_t *str, const char* other_str, const size_t other_len, size_t position) {
  if (position > str->len) {
    return 0;
  }
  size_t new_len = str->len + other_len;
  if (new_len > str->cap) {
    if (!string_expand_capacity(str, new_len)) {
      return 0;
    }
  }
  memmove(str->buf + position + other_len, str->buf + position,
          str->len - position + 1);
  memcpy(str->buf + position, other_str, other_len);
  str->len = new_len;
  return 1;
}

int string_insert_string(string_t *str, const string_t *other_str, size_t position) {
  return string_insert(str, other_str->buf, other_str->len, position);
}

int string_insert_str(string_t *str, const char *other_str, size_t position) {
  return string_insert(str, other_str, strlen(other_str), position);
}

string_t *string_clone(const string_t *str) { return string_from(str->buf); }

int string_path_join(string_t *str, const char *other_str, const size_t other_len) {
  if (other_len == 0) {
    return 0;
  }

  int str_has_slash = str->len > 0 && str->buf[str->len - 1] == '/';
  int other_has_slash = other_len > 0 && other_str[0] == '/';

  const char *tail = other_str;
  size_t tail_len = other_len;
  int need_slash = 0;

  if (str_has_slash && other_has_slash) {
    tail++;
    tail_len--;
  } else if (!str_has_slash && !other_has_slash) {
    need_slash = 1;
  }

  size_t new_len = str->len + need_slash + tail_len;
  if (new_len > str->cap) {
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

int string_path_join_string(string_t *str, const string_t *other_str) {
  return string_path_join(str, other_str->buf, other_str->len);
}

int string_path_join_str(string_t *str, const char *other_str) {
  return string_path_join(str, other_str, strlen(other_str));
}

string_t *string_path_filename(const string_t *str) {
  if (str->len == 0) {
    return string_new(0);
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
    return string_new(0);
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
    return string_new(0);
  }
  if (str->buf[str->len - 1] == '/') {
    return NULL;
  }
  size_t dot = string_get_dot_position(str);
  if (dot == str->len) {
    return string_new(0);
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

  string_t *extension = has_dot ? string_new(0) : string_from(".");
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

int string_contains_str(const string_t *str, const char *pat, size_t *match_postion) {
  char *substring = strstr(str->buf, pat);
  if (substring && match_postion) {
    *match_postion = substring - str->buf;
  }
  return substring != NULL;
}

string_t *string_read_from_file(const char *file_path, string_t* buf) {
  if (!check_buf(buf)) {
    return NULL;
  }

  FILE *f = fopen(file_path, "r");
  if (!f) {
    return NULL;
  }

  fseek(f, 0, SEEK_END);
  long len = ftell(f);
  rewind(f);

  if (len < 0) {
    fclose(f);
    return NULL;
  }

  if (!string_reserve(buf, len)) {
    fclose(f);
    return NULL;
  }

  size_t read_bytes = fread(buf->buf, 1, len, f);
  if (read_bytes != (size_t)len) {
    free(buf);
    fclose(f);
    return NULL;
  }

  buf->buf[len] = '\0';
  fclose(f);

  return buf;
}

string_t *string_read_line(const string_t *str, string_t *buf, size_t *offset, int ignore_empty) {
  return string_read_delimiter(str, buf, offset, "\n", ignore_empty);
}

string_t *string_read_line_str(const char *str, string_t *buf, size_t *offset, int ignore_empty) {
  return string_read_delimiter_str(str, strlen(str), buf, offset, "\n", ignore_empty);
}

string_t *string_read_delimiter(const string_t *str, string_t *buf, size_t *offset, char* delimiter, int ignore_empty) {
  return string_read_delimiter_str(str->buf, str->len, buf, offset, delimiter, ignore_empty);
}

string_t *string_read_delimiter_str(const char *str, size_t str_len, string_t *buf, size_t *offset, char* delimiter, int ignore_empty) {
  if (!check_buf(buf)) {
    return NULL;
  }
  if (!offset || *offset >= str_len || *delimiter == '\0') {
    return NULL;
  }

  if (ignore_empty) {
    while (*offset < str_len) {
      int is_delim = 0;
      for (size_t d = 0; delimiter[d] != '\0'; d++) {
        if (str[*offset] == delimiter[d]) {
          is_delim = 1;
          break;
        }
      }
      if (!is_delim) break;
      (*offset)++;
    }
  }

  int end_of_string = 0;
  size_t trailing_empty = 0;

  for (size_t i = 0;; i++) {

    if (str[i + *offset] == '\0') {
      if (i == 0) {
        return NULL;
      }
      end_of_string = 1;
      goto read_line;
    }

    for (size_t d = 0; delimiter[d] != '\0'; d++) {
      if (str[i + *offset] == delimiter[d]) {
        trailing_empty++;
        if (ignore_empty) {
          while (i + trailing_empty + *offset < str_len) {
            int is_delim = 0;
            for (size_t d = 0; delimiter[d] != '\0'; d++) {
              if (str[i + trailing_empty + *offset] == delimiter[d]) {
                is_delim = 1;
                break;
              }
            }
            if (!is_delim) break;
            trailing_empty++;
          }
        }
        goto read_line;
      }
    }

    continue;

  read_line:
    if (!string_reserve(buf, i + 1)) {
      return NULL;
    }
    buf->len = i;
    memcpy(buf->buf, (char *)str + *offset, i);
    buf->buf[i] = '\0';
    *offset += i + trailing_empty - end_of_string;
    return buf;
  }
}

string_t *string_read_stream(FILE *stream, string_t* buf, char delimiter) {
   if (!check_buf(buf)) {
     return NULL;
   }
   if (stream == stdin) {
     fprintf(stderr, "string_read_stream: Cannot read from STDIN stream, use `string_read_input()` instead.");
     return NULL;
   }

   if (!check_buf(buf)) {
     return NULL;
   }

   size_t buf_size = 256;
   char temp_buf[buf_size];

   while (1) {
     size_t bytes_read = fread(temp_buf, 1, buf_size-1, stream);
     if (bytes_read == 0) {
       if (feof(stream) || ferror(stream)) {
         return NULL;
       }
       break;
     }

     char* found = memchr(temp_buf, delimiter, bytes_read);

     if (found) {
       found[1] = '\0';

       long offset = temp_buf + bytes_read - found;
       fseek(stream, -offset + 1, SEEK_CUR);

       string_clear(buf);
       if (!string_push_str(buf, temp_buf)) {
         return NULL;
       }
       break;
     } else {
       temp_buf[bytes_read] = '\0';
       string_clear(buf);
       if (!string_push_str(buf, temp_buf)) {
         return NULL;
       }
       if (bytes_read < buf_size-1) {
         break;
       }
     }
   }
   return buf;
}

string_t* string_read_input(string_t* buf) {
   if (!check_buf(buf)) {
     return NULL;
   }

   size_t buf_size = 256;
   char temp_buf[buf_size];
   string_clear(buf);

   while (fgets(temp_buf, buf_size, stdin) != NULL) {
     if (!string_push_str(buf, temp_buf)) {
       return NULL;
     }
     if (memchr(temp_buf, '\n',buf_size)) {
       break;
     }
   }

   string_remove_back(buf, 1);
   return buf;
}

int string_parse_int(const string_t *str, int *out) {
  long parsed_long = strtol(str->buf, NULL, 0);
  if (errno != 0) {
    return 0;
  }
  if (parsed_long > INT_MAX) {
    return INT_MAX;
  }
  if (parsed_long < INT_MIN) {
    return INT_MIN;
  }

  if (out) *out = (int) parsed_long;

  return 1;
}

int string_parse_long(const string_t *str, long *out) {
  long parsed_long = strtol(str->buf, NULL, 0);
  if (errno != 0) {
    return 0;
  }
  if (out) *out = parsed_long;
  return 1;
}

int string_parse_float(const string_t *str, float *out) {
  float parsed_float = strtof(str->buf, NULL);
  if (errno != 0) {
    return 0;
  }
  if (out) *out = parsed_float;
  return 1;
}

int string_parse_double(const string_t *str, double *out) {
  double parsed_double = strtod(str->buf, NULL);
  if (errno != 0) {
    return 0;
  }
  if (out) *out = parsed_double;
  return 1;
}

int string_starts_with(const string_t *str, const char* pat) {
  return memcmp(str->buf, pat, strlen(pat)) == 0;
}

int string_ends_with(const string_t *str, const char* pat) {
  size_t pat_len = strlen(pat);
  return memcmp((char*)str->buf+str->len-pat_len, pat, pat_len) == 0;
}

void string_trim(string_t *str) {
  size_t start = 0;
  size_t end = 0;

  for (size_t i = 0; i <= str->len; i++) {
    if (i == str->len) {
      string_clear(str);
      return;
    }
    if (str->buf[i] != ' ' && str->buf[i] != '\n') {
      start = i;
      break;
    }
  }

  for (size_t i = 1; i <= str->len; i++) {
    if (str->buf[str->len - i] != ' ' && str->buf[str->len - i] != '\n') {
      end = str->len - i + 1;
      break;
    }
  }

  str->len = end - start;
  str->buf[end] = '\0';
  memmove(str->buf, str->buf + start, str->len + 1);
}

static int string_replace(string_t *str, const char* pat, const char* replacement, size_t rep_len, size_t *match) {
  size_t tmp_match = 0;
  if (!match) {
    match = &tmp_match;
  }
  size_t pat_len = strlen(pat);
  if (!string_contains_str(str, pat, match)) {
    return 1;
  }
  size_t new_len = str->len - pat_len + rep_len;
  if (!string_reserve(str, new_len)) {
    return 0;
  }
  memmove((char*)str->buf + *match + rep_len, str->buf + *match + pat_len, str->len - *match - pat_len + 1);
  memcpy((char*)str->buf + *match, replacement, rep_len);
  str->len = new_len;
  *match += rep_len;
  return 1;
}

int string_replace_str(string_t *str, const char* pat, const char* replacement, size_t *match) {
  return string_replace(str, pat, replacement, strlen(replacement), match);
}

int string_replace_string(string_t *str, const char* pat, const string_t* replacement, size_t* match) {
  return string_replace(str, pat, replacement->buf, replacement->len, match);
}

int string_join_string(string_t *str, const string_t* other_str, const char* separator) {
  int separator_len = strlen(separator);
  int new_len = str->len + separator_len + other_str->len;
  if (!string_reserve(str, new_len)) {
    return 0;
  }
  if (!string_push_str(str, separator)) return 0;
  if (!string_push_string(str, other_str)) return 0;
  return 1;
}

int string_join_str(string_t *str, const char* other_str, const char* separator) {
  int separator_len = strlen(separator);
  int new_len = str->len + separator_len + strlen(other_str);
  if (!string_reserve(str, new_len)) {
    return 0;
  }
  string_push_str(str, separator);
  string_push_str(str, other_str);
  return 1;
}

void string_to_lowercase(string_t *str) {
  for (size_t i = 0; i < str->len; i++) {
    if (str->buf[i] >= 65 && str->buf[i] <= 90) {
      str->buf[i] += 32;
    }
  }
}

void string_to_uppercase(string_t *str) {
  for (size_t i = 0; i < str->len; i++) {
    if (str->buf[i] >= 97 && str->buf[i] <= 122) {
      str->buf[i] -= 32;
    }
  }
}

int str_is_empty(const char* str) {
  return *str == '\0';
}

int string_is_empty(const string_t* str) {
  return str->len == 0;
}

static int string_copy(string_t* str, const char* other_str, size_t other_len) {
  if (!string_reserve(str, other_len)) {
    return 0;
  }
  memcpy(str->buf, other_str, other_len + 1);
  str->len = other_len;
  return 1;
}

int string_copy_str(string_t* str, const char* other_str) {
  return string_copy(str, other_str, strlen(other_str));
}

int string_copy_string(string_t* str, const string_t* other_str) {
  return string_copy(str, other_str->buf, other_str->len);
}

string_t* string_format(const char* format, string_t* buf,...) {
  if (check_buf(buf)) {
    return NULL;
  }

  va_list args;

  va_start(args, buf);

  int format_len = strlen(format);

  string_copy_str(buf, format);
  if (!buf) {
    return NULL;
  }

  size_t offset = 0;
  while(string_contains_str(buf, "%", &offset));

  va_end(args);
  return buf;
}
