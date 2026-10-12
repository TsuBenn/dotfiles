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
Makefile
vec_test.c
vec.c
vec.h
```

# Files

## File: Makefile
```makefile
CC = gcc
CFLAGS = -Wall -Wextra -g -fsanitize=address,undefined

all: build/vec_test

build/vec_test: vec.c vec.h vec_test.c
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ vec.c vec_test.c

test: all
	./build/vec_test

clean:
	rm -rf build

.PHONY: all test clean
```

## File: vec_test.c
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "vec.h"

/* Stops the test program immediately. Used only for setup that must not fail. */
#define CHECK(x) do { if (!(x)) { fprintf(stderr, "setup failed: %s (line %d)\n", #x, __LINE__); exit(1); } } while (0)

static int failures = 0;

struct point { int x; int y; };
struct blob  { char data[100]; int id; };

/* ---------- reporting helpers ---------- */

/* Rules that must ALWAYS hold for a valid vec_t, no matter what was done to it. */
static int vec_ok(const char* label, const vec_t* v) {
  if (!v) {
    printf("FAIL %s: vec is NULL\n", label);
    failures++;
    return 0;
  }
  if (v->elem_size == 0) {
    printf("FAIL %s: elem_size is 0\n", label);
    failures++;
    return 0;
  }
  if (v->len > v->capacity) {
    printf("FAIL %s: len %zu is bigger than capacity %zu\n", label, v->len, v->capacity);
    failures++;
    return 0;
  }
  return 1;
}

static void expect_int(const char* label, int got, int want) {
  if (got == want) {
    printf("PASS %s = %d\n", label, got);
  } else {
    printf("FAIL %s: got %d, want %d\n", label, got, want);
    failures++;
  }
}

static void expect_size(const char* label, size_t got, size_t want) {
  if (got == want) {
    printf("PASS %s = %zu\n", label, got);
  } else {
    printf("FAIL %s: got %zu, want %zu\n", label, got, want);
    failures++;
  }
}

static void expect_true(const char* label, int cond) {
  if (cond) {
    printf("PASS %s\n", label);
  } else {
    printf("FAIL %s\n", label);
    failures++;
  }
}

/* Checks a vector of ints against an array: same length, same values, and
 * vec_get(len) must return NULL. */
static void expect_ints(const char* label, const vec_t* v, const int* want, size_t n) {
  if (!vec_ok(label, v)) return;
  if (v->len != n) {
    printf("FAIL %s: len is %zu, want %zu\n", label, v->len, n);
    failures++;
    return;
  }
  for (size_t i = 0; i < n; i++) {
    const int* p = vec_get(v, i);
    if (!p) {
      printf("FAIL %s: vec_get(%zu) returned NULL\n", label, i);
      failures++;
      return;
    }
    if (*p != want[i]) {
      printf("FAIL %s: element %zu is %d, want %d\n", label, i, *p, want[i]);
      failures++;
      return;
    }
  }
  if (vec_get(v, n) != NULL) {
    printf("FAIL %s: vec_get(len) should return NULL\n", label);
    failures++;
    return;
  }
  if (n <= 10) {
    printf("PASS %s = [", label);
    for (size_t i = 0; i < n; i++) {
      if (i) printf(", ");
      printf("%d", want[i]);
    }
    printf("]\n");
  } else {
    printf("PASS %s (len %zu)\n", label, n);
  }
}

static vec_t* make_ints(const int* vals, size_t n) {
  vec_t* v = vec_new(sizeof(int));
  CHECK(v);
  for (size_t i = 0; i < n; i++) {
    CHECK(vec_push(v, &vals[i]));
  }
  return v;
}

/* ---------- new / free ---------- */

static void section_new_free(void) {
  printf("\n-- new / free --\n");

  vec_t* v = vec_new(sizeof(int));
  CHECK(v);
  expect_size("new: len", v->len, 0);
  expect_size("new: elem_size", v->elem_size, sizeof(int));
  expect_true("new: get(0) on an empty vec is NULL", vec_get(v, 0) == NULL);
  vec_free(v);

  vec_free(NULL);
  printf("PASS free(NULL) did not crash\n");

  /* Decision from the header comment, uncomment once you implement it:
   * expect_true("new(0) is refused", vec_new(0) == NULL);
   */
}

/* ---------- push / get ---------- */

static void section_push_get(void) {
  printf("\n-- push / get --\n");

  vec_t* v = vec_new(sizeof(int));
  CHECK(v);
  int a = 10, b = 20, c = 30;
  expect_int("push 10", vec_push(v, &a), 1);
  expect_int("push 20", vec_push(v, &b), 1);
  expect_int("push 30", vec_push(v, &c), 1);
  expect_ints("after 3 pushes", v, (const int[]){10, 20, 30}, 3);

  /* push must COPY the element, not keep the pointer */
  int x = 1;
  vec_t* w = vec_new(sizeof(int));
  CHECK(w);
  CHECK(vec_push(w, &x));
  x = 42;
  expect_ints("push copies its input", w, (const int[]){1}, 1);
  vec_free(w);

  /* writing through the pointer from get changes the vector */
  int* p = vec_get(v, 1);
  CHECK(p);
  *p = 99;
  expect_ints("write through vec_get", v, (const int[]){10, 99, 30}, 3);

  /* out of range */
  expect_true("get(len) is NULL", vec_get(v, 3) == NULL);
  expect_true("get(len + 1) is NULL", vec_get(v, 4) == NULL);
  expect_true("get(huge index) is NULL", vec_get(v, (size_t)-1) == NULL);
  vec_free(v);

  /* growth: many pushes force several reallocations */
  v = vec_new(sizeof(int));
  CHECK(v);
  for (int i = 0; i < 1000; i++) {
    CHECK(vec_push(v, &i));
  }
  expect_size("1000 pushes: len", v->len, 1000);
  int ok = vec_ok("1000 pushes", v);
  for (int i = 0; i < 1000 && ok; i++) {
    const int* q = vec_get(v, (size_t)i);
    if (!q || *q != i) ok = 0;
  }
  expect_true("1000 pushes hold the right values", ok);
  vec_free(v);
}

/* ---------- pop ---------- */

static void section_pop(void) {
  printf("\n-- pop --\n");

  vec_t* v = make_ints((const int[]){1, 2, 3}, 3);
  size_t cap = v->capacity;
  int out = -1;

  expect_int("pop returns", vec_pop(v, &out), 1);
  expect_int("pop copies the last element into out", out, 3);
  expect_ints("after one pop", v, (const int[]){1, 2}, 2);

  expect_int("pop again", vec_pop(v, &out), 1);
  expect_int("pop again: out", out, 2);
  expect_int("pop the last one", vec_pop(v, &out), 1);
  expect_int("pop the last one: out", out, 1);
  expect_ints("popped everything", v, NULL, 0);
  expect_size("pop keeps capacity", v->capacity, cap);

  /* empty vec: refused, out untouched */
  out = -1;
  expect_int("pop on an empty vec returns", vec_pop(v, &out), 0);
  expect_int("pop on an empty vec leaves out alone", out, -1);
  expect_ints("pop on an empty vec leaves it empty", v, NULL, 0);

  /* still usable afterwards */
  int x = 7;
  expect_int("push after emptying", vec_push(v, &x), 1);
  expect_ints("push after emptying result", v, (const int[]){7}, 1);
  vec_free(v);
}

/* ---------- insert ---------- */

static void test_insert(const char* label, const int* base, size_t n, size_t index, int value,
                        int want_ret, const int* want, size_t want_n) {
  vec_t* v = make_ints(base, n);
  int ret = vec_insert(v, index, &value);
  if (ret != want_ret) {
    printf("FAIL %s: returned %d, want %d\n", label, ret, want_ret);
    failures++;
  } else {
    expect_ints(label, v, want, want_n);
  }
  vec_free(v);
}

static void section_insert(void) {
  printf("\n-- insert --\n");

  test_insert("insert at the front", (const int[]){1, 2, 3}, 3, 0, 9, 1, (const int[]){9, 1, 2, 3}, 4);
  test_insert("insert in the middle", (const int[]){1, 2, 3}, 3, 1, 9, 1, (const int[]){1, 9, 2, 3}, 4);
  test_insert("insert at the end (index == len)", (const int[]){1, 2, 3}, 3, 3, 9, 1, (const int[]){1, 2, 3, 9}, 4);
  test_insert("insert past the end is refused", (const int[]){1, 2, 3}, 3, 4, 9, 0, (const int[]){1, 2, 3}, 3);
  test_insert("insert far past the end is refused", (const int[]){1, 2, 3}, 3, 100, 9, 0, (const int[]){1, 2, 3}, 3);
  test_insert("insert into an empty vec", NULL, 0, 0, 9, 1, (const int[]){9}, 1);
  test_insert("insert at 1 in an empty vec is refused", NULL, 0, 1, 9, 0, NULL, 0);
  test_insert("insert before the only element", (const int[]){5}, 1, 0, 9, 1, (const int[]){9, 5}, 2);
  test_insert("insert after the only element", (const int[]){5}, 1, 1, 9, 1, (const int[]){5, 9}, 2);

  /* many inserts at the front: each one shifts everything, and the buffer grows */
  vec_t* v = vec_new(sizeof(int));
  CHECK(v);
  for (int i = 0; i < 500; i++) {
    CHECK(vec_insert(v, 0, &i));
  }
  expect_size("500 inserts at the front: len", v->len, 500);
  int ok = vec_ok("500 inserts at the front", v);
  for (int k = 0; k < 500 && ok; k++) {
    const int* p = vec_get(v, (size_t)k);
    if (!p || *p != 499 - k) ok = 0;
  }
  expect_true("500 inserts at the front are in reverse order", ok);

  /* the same vector, now emptied from the front */
  for (int i = 0; i < 250; i++) {
    CHECK(vec_remove(v, 0));
  }
  expect_size("250 removes at the front: len", v->len, 250);
  ok = vec_ok("250 removes at the front", v);
  for (int k = 0; k < 250 && ok; k++) {
    const int* p = vec_get(v, (size_t)k);
    if (!p || *p != 249 - k) ok = 0;
  }
  expect_true("250 removes at the front keep the right values", ok);
  vec_free(v);
}

/* ---------- remove ---------- */

static void test_remove(const char* label, const int* base, size_t n, size_t index,
                        int want_ret, const int* want, size_t want_n) {
  vec_t* v = make_ints(base, n);
  size_t cap = v->capacity;
  int ret = vec_remove(v, index);
  if (ret != want_ret) {
    printf("FAIL %s: returned %d, want %d\n", label, ret, want_ret);
    failures++;
  } else {
    expect_ints(label, v, want, want_n);
    if (v->capacity != cap) {
      printf("FAIL %s: capacity changed from %zu to %zu\n", label, cap, v->capacity);
      failures++;
    }
  }
  vec_free(v);
}

static void section_remove(void) {
  printf("\n-- remove --\n");

  test_remove("remove the first", (const int[]){1, 2, 3}, 3, 0, 1, (const int[]){2, 3}, 2);
  test_remove("remove the middle", (const int[]){1, 2, 3}, 3, 1, 1, (const int[]){1, 3}, 2);
  test_remove("remove the last", (const int[]){1, 2, 3}, 3, 2, 1, (const int[]){1, 2}, 2);
  test_remove("remove at index == len is refused", (const int[]){1, 2, 3}, 3, 3, 0, (const int[]){1, 2, 3}, 3);
  test_remove("remove far past the end is refused", (const int[]){1, 2, 3}, 3, 100, 0, (const int[]){1, 2, 3}, 3);
  test_remove("remove the only element", (const int[]){5}, 1, 0, 1, NULL, 0);
  test_remove("remove from an empty vec is refused", NULL, 0, 0, 0, NULL, 0);
}

/* ---------- clear ---------- */

static void section_clear(void) {
  printf("\n-- clear --\n");

  vec_t* v = make_ints((const int[]){1, 2, 3}, 3);
  size_t cap = v->capacity;
  vec_clear(v);
  expect_ints("clear", v, NULL, 0);
  expect_size("clear keeps capacity", v->capacity, cap);

  vec_clear(v);
  expect_ints("clear on an already empty vec", v, NULL, 0);

  int x = 7;
  expect_int("push after clear", vec_push(v, &x), 1);
  expect_ints("push after clear result", v, (const int[]){7}, 1);
  vec_free(v);
}

/* ---------- other element types ---------- */

static void expect_point(const char* label, const vec_t* v, size_t i, int x, int y) {
  const struct point* p = vec_get(v, i);
  if (!p) {
    printf("FAIL %s: vec_get(%zu) returned NULL\n", label, i);
    failures++;
  } else if (p->x != x || p->y != y) {
    printf("FAIL %s: element %zu is (%d, %d), want (%d, %d)\n", label, i, p->x, p->y, x, y);
    failures++;
  } else {
    printf("PASS %s: element %zu = (%d, %d)\n", label, i, x, y);
  }
}

static int blob_ok(const struct blob* b, int id) {
  if (!b || b->id != id) return 0;
  for (size_t i = 0; i < sizeof(b->data); i++) {
    if (b->data[i] != (char)('a' + id % 26)) return 0;
  }
  return 1;
}

static void section_other_types(void) {
  printf("\n-- other element types --\n");

  /* char: elem_size 1 */
  vec_t* v = vec_new(sizeof(char));
  CHECK(v);
  for (const char* s = "hello"; *s; s++) {
    CHECK(vec_push(v, s));
  }
  char x = 'X';
  CHECK(vec_insert(v, 2, &x));
  CHECK(vec_remove(v, 0));
  char buf[16] = {0};
  for (size_t i = 0; i < v->len && i < sizeof(buf) - 1; i++) {
    buf[i] = *(const char*)vec_get(v, i);
  }
  expect_size("char vec: len", v->len, 5);
  expect_true("char vec: \"hello\" -> insert X at 2 -> remove front = \"eXllo\"", strcmp(buf, "eXllo") == 0);
  vec_free(v);

  /* struct with two ints: elem_size 8 */
  v = vec_new(sizeof(struct point));
  CHECK(v);
  struct point a = {1, 2}, b = {3, 4}, c = {5, 6}, d = {7, 8};
  CHECK(vec_push(v, &a));
  CHECK(vec_push(v, &b));
  CHECK(vec_push(v, &c));
  CHECK(vec_insert(v, 1, &d));          /* a d b c */
  expect_point("point vec after insert", v, 0, 1, 2);
  expect_point("point vec after insert", v, 1, 7, 8);
  expect_point("point vec after insert", v, 2, 3, 4);
  expect_point("point vec after insert", v, 3, 5, 6);
  CHECK(vec_remove(v, 2));              /* a d c */
  expect_size("point vec after remove: len", v->len, 3);
  expect_point("point vec after remove", v, 2, 5, 6);
  struct point popped = {0, 0};
  expect_int("point vec pop", vec_pop(v, &popped), 1);
  expect_true("point vec pop copies the whole struct", popped.x == 5 && popped.y == 6);
  vec_free(v);

  /* a big struct (not a power of two in size) makes elem_size mistakes obvious */
  v = vec_new(sizeof(struct blob));
  CHECK(v);
  for (int id = 0; id < 50; id++) {
    struct blob blob;
    memset(blob.data, 'a' + id % 26, sizeof(blob.data));
    blob.id = id;
    CHECK(vec_push(v, &blob));
  }
  int ok = 1;
  for (int id = 0; id < 50 && ok; id++) {
    if (!blob_ok(vec_get(v, (size_t)id), id)) ok = 0;
  }
  expect_true("blob vec: 50 pushes hold the right data", ok);

  CHECK(vec_remove(v, 10));
  expect_size("blob vec after remove: len", v->len, 49);
  expect_true("blob vec: element 9 untouched", blob_ok(vec_get(v, 9), 9));
  expect_true("blob vec: element 10 is the old 11", blob_ok(vec_get(v, 10), 11));
  expect_true("blob vec: last element is the old 49", blob_ok(vec_get(v, 48), 49));

  struct blob first;
  memset(first.data, 'a' + 100 % 26, sizeof(first.data));
  first.id = 100;
  CHECK(vec_insert(v, 0, &first));
  expect_true("blob vec: new first element", blob_ok(vec_get(v, 0), 100));
  expect_true("blob vec: old first element moved to 1", blob_ok(vec_get(v, 1), 0));
  expect_true("blob vec: last element after insert", blob_ok(vec_get(v, 49), 49));
  vec_free(v);
}

/* ---------- main ---------- */

int main(void) {
  section_new_free();
  section_push_get();
  section_pop();
  section_insert();
  section_remove();
  section_clear();
  section_other_types();

  /* Dangling pointer: the bug the vec_get comment warns about. Uncomment at the
   * very end (a sanitizer abort stops the whole run) and read what ASan says.
   *
   *   vec_t* v = make_ints((const int[]){1, 2, 3}, 3);
   *   int* p = vec_get(v, 0);
   *   for (int i = 0; i < 1000; i++) vec_push(v, &i);   // realloc moves the buffer
   *   printf("%d\n", *p);                               // p points at the old buffer
   */

  printf("\n%s (%d failure%s)\n", failures ? "SOME TESTS FAILED" : "ALL TESTS PASSED",
         failures, failures == 1 ? "" : "s");
  return failures ? 1 : 0;
}
```

## File: vec.c
```c
#include "vec.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * Capacity expansion can be changed to expand in a certain factor > 1
 * to preserve memory or to minimize reallocations.
 */
static size_t vec_new_capacity(size_t current, size_t target) {
  size_t new = current;
  if (new == 0) {
    new = 8;
  }
  while (new < target) {
    // new += 1.5;
    new *= 2;
  }
  return new;
}

static int vec_expand_capacity(vec_t* vec, size_t target_capacity) {
    size_t new_capacity = vec_new_capacity(vec->capacity, target_capacity);
    void* new_data = realloc(vec->data, vec->elem_size*new_capacity);
    if (!new_data) {
        perror("vec_expand_capacity (new_data: realloc)");
        return 0;
    }
    vec->data = new_data;
    vec->capacity = new_capacity;
    return 1;
}

static void* vec_slot(const vec_t* vec, size_t i) {
    return (char*)vec + i*vec->elem_size;
}

vec_t* vec_new(size_t elem_size) {
    if (elem_size == 0) {
        return NULL;
    }

    vec_t* new_vec = malloc(sizeof(vec_t));
    if (!new_vec) {
        return NULL;
    }

    new_vec->data = NULL;
    new_vec->len = 0;
    new_vec->capacity = 0;
    new_vec->elem_size = elem_size;

    return new_vec;
}

void vec_free(vec_t* vec) {
    if (!vec) {
        return;
    }
    if (vec->data) {
        free(vec->data);
    }
    free(vec);
}

int vec_push(vec_t* vec, const void* elem) {
    if (vec->len + 1 > vec->capacity) {
        if (!vec_expand_capacity(vec, vec->capacity+1)) {
            return 0;
        }
    }
    memcpy(vec_slot(vec, vec->len), elem, vec->elem_size);
    vec->len++;
    return 1;
}

void* vec_get(const vec_t* vec, size_t index) {
    if (index >= vec->len) {
      return NULL;
    }
    return vec_slot(vec, index);
}

int vec_pop(vec_t* vec, void* out) {
    if (vec->len == 0) {
        return 0;
    }
    vec->len--;
    memcpy(out, vec_slot(vec, vec->len), vec->elem_size);
    return 1;
}

int vec_insert(vec_t* vec, size_t index, const void* elem) {
    if (index > vec->len) {
        return 0;
    }
    if (vec->len + 1 > vec->capacity) {
        if (!vec_expand_capacity(vec, vec->capacity+1)) {
            return 0;
        }
    }
    char* insert_addr = vec_slot(vec, index);
    memmove(insert_addr + vec->elem_size, insert_addr, vec->elem_size*(vec->len-index));
    memcpy(insert_addr, elem, vec->elem_size);
    vec->len++;
    return 1;
}

int vec_remove(vec_t* vec, size_t index) {
    if (index >= vec->len || vec->len == 0) {
        return 0;
    }
    char* remove_addr = vec_slot(vec, index);
    memmove(remove_addr, remove_addr + vec->elem_size, vec->elem_size*(vec->len-index-1));
    vec->len--;
    return 1;
}

void vec_clear(vec_t* vec) {
    vec->len = 0;
}
```

## File: vec.h
```c
#ifndef VEC_H
#define VEC_H

#include <stddef.h>

typedef struct Vec {
  void* data;
  size_t len;
  size_t capacity;
  size_t elem_size;
} vec_t;

/**
 * Create a new empty `vec` with specified type size.
 *
 * Returns `NULL` if `elem_size == 0` or allocation fails.
 *
 * The caller owns the result and must free it with `vec_free()`
 */
vec_t* vec_new(size_t elem_size);

/**
 * Free a `vec`.
 *
 * Safe to call with `NULL`. The pointer must not be used afterwards.
 */
void vec_free(vec_t* vec);

/**
 * Push an `elem` to the back of `vec`.
 *
 * Returns 1 on success, returns 0 if allocation fails (`vec` is left unchanged).
 */
int vec_push(vec_t* vec, const void* elem);

/**
 * Remove the last element of `vec` and copies it to `out`.
 *
 * `out` must point to at least `vec->elem_size` bytes.
 *
 * Returns 1 on success, returns 0 if `vec` is empty (`vec` is left unchanged).
 *
 * Capacity of `vec` is unchanged.
 */
int vec_pop(vec_t* vec, void* out);

/**
 * Gets a pointer to an `elem` at `index` from `vec`.
 *
 * Returns `NULL` on invalid access (`index >= vec->len`).
 *
 * The pointer points INSIDE the vector's buffer, it is not a copy.
 * It is only valid until the next call that modifies the vector
 * (vec_push, vec_insert, vec_pop, vec_remove, vec_clear, vec_free).
 * Don't store it: keep the index and call vec_get again when you need it.
 */
void* vec_get(const vec_t* vec, size_t index);

/**
 * Insert a copy of `elem` into `vec` at `index`, shifting later elements back by one.
 *
 * `index == vec->len` is allowed and behave like vec_push.
 *
 * Returns `1` on success, returns `0` if `index > vec->len` or allocation fails (`vec` is left unchanged).
 */
int vec_insert(vec_t* vec, size_t index, const void* elem);

/**
 * Remove an `elem` from `vec` at `index`, shifting later elements forward by one.
 *
 * Returns `1` on success, returns `0` on invalid access (`index >= vec->len`) (`vec` is left unchanged).
 *
 * Capacity of `vec` is unchanged.
 */
int vec_remove(vec_t* vec, size_t index);

/**
 * Clear all elem in a `vec`.
 *
 * Only updates the `vec->len` to `0` and does not wipe the data in the remaining capacity.
 *
 * Capacity of `vec` is unchanged.
 */
void vec_clear(vec_t* vec);


#endif
```
