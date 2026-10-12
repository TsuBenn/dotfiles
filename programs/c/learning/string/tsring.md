This file is a merged representation of the entire codebase, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
```
core_test.c
main.c
Makefile
tsring.c
tsring.h
```

# Files

## File: Makefile
```makefile
CC = gcc
CFLAGS = -Wall -Wextra -g -fsanitize=address,undefined

all: build/main build/core_test

build/main: main.c tsring.c tsring.h
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ main.c tsring.c

build/core_test: core_test.c tsring.c tsring.h
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ core_test.c tsring.c

main: build/main
	./build/main

test: all
	./build/main
	./build/core_test

clean:
	rm -rf build

.PHONY: all test clean
```

## File: tsring.c
```c
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
  for (int i = 0;;i++) {
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
```

## File: tsring.h
```c
#ifndef TSRING_H
#define TSRING_H

#include <stddef.h>

typedef struct String {
    char* buf;
    size_t len;
    size_t capacity;
} string_t;

/**
 * Prints the string along with its metadata for debug purposes.
 */
void string_debug(const string_t* str);

/**
 * Creates a new string by copying `string`.
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t* string_from(const char* string);

/**
 * Creates a new string from an allocated `buf` with provided `size`.
 *
 * The caller are responsible of providing the correct `size`, representing the allocated memory size for `buf`.
 * The returned `string_t` will take ownership the `buf` provided.
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t* string_from_buf(char* buf, size_t size);

/**
 * Creates a new empty string.
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t* string_new(void);

/**
 * Free a string.
 *
 * Safe to call with `NULL`. The pointer must not be used afterwards.
 */
void string_free(string_t *string);

/**
 * Reserve a certain amount of capacity of a `str`.
 *
 * If `new_capacity` is `<= str->capacity`, nothing will happens and the function will return true.
 *
 * Returns `1` on success, returns `0` if allocation fails (`str` is left unchanged).
 */
int string_reserve(string_t* str, size_t new_capacity);

/**
 * Comparing 2 strings.
 * Returns `1` if equal, returns `0` if not.
 */
int string_eq_string(const string_t* str, const string_t* other_str);

/**
 * Comparing a strings with a char* string.
 * Returns `1` if equal, returns `0` if not.
 */
int string_eq_str(const string_t* str, const char* other_str);

/**
 * Clearing a string content.
 * This action will not shrink the string's capacity.
 */
void string_clear(string_t* str);

/**
 * Append `other_str` to the end of `str`.
 *
 * Returns `1` on success, returns `0` if allocation (capacity expansion) fails (`str` is left unchanged).
 */
int string_push_string(string_t* str, const string_t* other_str);

/**
 * Append `other_str` (a char*) to the end of `str`.
 *
 * Returns `1` on success, returns `0` if allocation (capacity expansion) fails (`str` is left unchanged).
 */
int string_push_str(string_t* str, const char* other_str);

/**
 * Insert `other_str` into `str` at `position`.
 *
 * Returns `1` on success, returns `0` if allocation (capacity expansion) fails (`str` is left unchanged) or `position` > `str->len`.
 */
int string_insert(string_t* str, const string_t* other_str, size_t position);

/**
 * Remove `size` amount of character at the back of the string.
 *
 * Returns `1` on success, returns `0` if `size` > `str->len`.
 *
 * This action will not shrink the string's capacity.
 */
int string_remove_back(string_t* str, size_t size);

/**
 * Remove `size` amount of character at the front of the string.
 *
 * Returns `1` on success, returns `0` if `size` > `str->len`.
 *
 * This action will not shrink the string's capacity.
 */
int string_remove_front(string_t* str, size_t size);

/**
 * Create a new string by slicing the provided string from `start` position to `end` position.
 * `start` is included and `end` is excluded.
 *
 * Returns `NULL` if allocation fails, returns an empty string if start >= end.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t* string_slice(const string_t* str, size_t start, size_t end);

/**
 * Cloning an existing string into a new string.
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t* string_clone(const string_t* str);

/**
 * Joining `other_str` into `str` as path.
 *
 * Returns `1` on success, returns `0` if `other_str` is empty or allocation (capacity expansion) fails (`str` is left unchanged).
 */
int string_path_join(string_t* str, const string_t* other_str);

/**
 * Gets the last component of a path (the file or directory name).
 *
 * A single trailing slash is ignored, and "/" is returned as "/".
 *
 * Examples:
 *     "a/b/c.txt"  ->  "c.txt",
 *     "a/b/"       ->  "b",
 *     "c.txt"      ->  "c.txt",
 *     "/"          ->  "/",
 *     ""           ->  ""
 *
 * Assumes a normalized path: repeated trailing slashes ("a//") are not handled.
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with string_free().
 */
 string_t* string_path_filename(const string_t* str);

/**
 * Removes the extension from a path, keeping the directories.
 *
 * The extension starts at the last dot in the last component and runs to the
 * end, so multi-dot extensions are not removed entirely.
 *
 * - A leading dot is part of the name, not an extension (".bashrc" is unchanged).
 * - Dots in directory names are ignored ("a.b/c" is unchanged).
 * - "." and ".." are returned unchanged.
 * - A path ending in '/' has no file name, so it is returned unchanged.
 *
 * Examples:
 *     "a/b.txt"           ->  "a/b",
 *     "archive.tar.gz"    ->  "archive",
 *     "report.final.pdf"  ->  "report",
 *     ".bashrc.bak"       ->  ".bashrc",
 *     "a.b/c"             ->  "a.b/c",
 *     "a/b/"              ->  "a/b/"
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
 string_t* string_path_stem(const string_t* str);

/**
 * Gets the extension of a path, no dot included.
 *
 * The extension starts at the last dot in the last component and runs to the end.
 *
 * Returns an empty string if no extension were found.
 * Returns `NULL` if allocation fails or provided path is a directory.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
 string_t* string_path_get_extension(const string_t* str);

/**
 * Add extension to a path
 *
 * If the provided extension has a leading dot, it will be safely handled.
 * Path that already have the same extension as the provided one will stay unchanged.
 * Path that has a different extension will have the provided one appended at the end.
 *
 * Returns `1` on success, returns `0` if allocation (capacity expansion) fails (`str` is left unchanged) or provided path is a directory.
 */
 int string_path_add_extension(string_t* str,const char* ext);

/**
 * Check whether `str` contains `pat` as a substring.
 *
 * If found, the position where the first match occured will be assigned to `match_position`
 * `match_position` can be NULL if the caller isn't planning on using the value.
 *
 * Returns `1` on found, returns `0` if not.
 */
 int string_contains_string(const string_t* str, const string_t* pat, size_t *match_position);

/**
 * Check whether `str` contains `pat` as a substring.
 *
 * If found, the position where the first match occured will be assigned to `match_position`
 * `match_position` can be NULL if the caller isn't planning on using the value.
 *
 * Returns `1` on found, returns `0` if not.
 */
 int string_contains_str(const string_t* str, const char* pat, size_t *match_position);

/**
 * Read from a file and returns a `string_t` pointer containing the file's content
 *
 * Returns NULL if read from file fails.
 */
 string_t* string_read_from_file(const char* file_path);

/**
 * Read a line starting at `offset` from `str` and store it in `buf`.
 *
 * `buf` will be overriden on success and will have its capacity expands when read line is longer than `buf->capacity`.
 *
 * `offset` will be updated to the index after the next occurence of `\n` or at the next occurance of `\0` if end of string is reached.
 *
 * Returns `buf` on success.
 *
 * Returns NULL when end of `str` occured while no character is read or allocation fails on `buf` (`buf` is left unchanged) or `offset == NULL`.
 */
 string_t* string_read_line(const string_t* str, string_t* buf, size_t* offset);

/**
 * Turns all character within the alphabet into lowercase.
 *
 * This function will modify `str`, use `string_clone()` if the caller wants a non-destructive `to_lowercase()` operation
 */
 void string_to_lowercase(string_t* str);

/**
 * Turns all character within the alphabet into uppercase.
 *
 * This function will modify `str`, use `string_clone()` if the caller wants a non-destructive `to_uppercase()` operation
 */
 void string_to_uppercase(string_t* str);

#endif
```
