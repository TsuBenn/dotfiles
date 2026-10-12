#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "vec.h"

/* Stops the test program immediately. Used only for setup that must not fail. */
#define CHECK(x) do { if (!(x)) { fprintf(stderr, "setup failed: %s (line %d)\n", #x, __LINE__); exit(1); } } while (0)

static int failures = 0;

struct point { int x; int y; };
struct blob  { char data[100]; int id; };

static int blob_ok(const struct blob* b, int id) {
  if (!b || b->id != id) return 0;
  for (size_t i = 0; i < sizeof(b->data); i++) {
    if (b->data[i] != (char)('a' + id % 26)) return 0;
  }
  return 1;
}

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

/* ---------- self push ---------- */

static void section_self_push(void) {
  printf("\n-- pushing an element that lives inside the vec --\n");

  /* spare capacity: no reallocation happens, so this already works */
  vec_t* v = vec_new(sizeof(int));
  CHECK(v);
  for (int i = 0; i < 3; i++) {
    int x = 100 + i;
    CHECK(vec_push(v, &x));
  }
  expect_int("push(v, get(v, 0)) with spare capacity", vec_push(v, vec_get(v, 0)), 1);
  const int* last = vec_get(v, v->len - 1);
  expect_true("  ...the new last element is a copy of the first", last && *last == 100);
  vec_free(v);

  /* full: this push must grow the buffer, so `elem` points into memory about to be freed */
  v = vec_new(sizeof(int));
  CHECK(v);
  int first = 100;
  CHECK(vec_push(v, &first));              /* allocates the first buffer */
  while (v->len < v->capacity) {           /* fill it to the very last slot */
    int x = 100 + (int)v->len;
    CHECK(vec_push(v, &x));
  }
  size_t old_len = v->len;
  expect_int("push(v, get(v, 0)) on a full vec", vec_push(v, vec_get(v, 0)), 1);
  expect_size("  ...len grew by one", v->len, old_len + 1);
  last = vec_get(v, v->len - 1);
  expect_true("  ...the new last element is a copy of the first", last && *last == 100);
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

/* ---------- inserting an element that lives inside the vec ---------- */

/* Inserts a copy of element `from` at `index`, so `elem` points INSIDE the vec. */
static void test_self_insert(const char* label, const int* base, size_t n, size_t index, size_t from,
                             const int* want, size_t want_n) {
  vec_t* v = make_ints(base, n);
  int ret = vec_insert(v, index, vec_get(v, from));
  if (ret != 1) {
    printf("FAIL %s: returned %d, want 1\n", label, ret);
    failures++;
  } else {
    expect_ints(label, v, want, want_n);
  }
  vec_free(v);
}

static struct blob make_blob(int id) {
  struct blob b;
  memset(b.data, 'a' + id % 26, sizeof(b.data));
  b.id = id;
  return b;
}

static void section_self_insert(void) {
  printf("\n-- inserting an element that lives inside the vec --\n");

  const int base[] = {10, 20, 30};
  test_self_insert("insert(0, get(2)): elem is after the insertion point",
                   base, 3, 0, 2, (const int[]){30, 10, 20, 30}, 4);
  test_self_insert("insert(1, get(1)): elem is exactly at the insertion point",
                   base, 3, 1, 1, (const int[]){10, 20, 20, 30}, 4);
  test_self_insert("insert(3, get(0)): elem is before the insertion point",
                   base, 3, 3, 0, (const int[]){10, 20, 30, 10}, 4);
  test_self_insert("insert(0, get(0)): copy of the first, inserted at the front",
                   base, 3, 0, 0, (const int[]){10, 10, 20, 30}, 4);

  /* full vec of ints: the buffer grows AND the elements shift in the same call */
  vec_t* v = vec_new(sizeof(int));
  CHECK(v);
  int first = 100;
  CHECK(vec_push(v, &first));
  while (v->len < v->capacity) {
    int x = 100 + (int)v->len;
    CHECK(vec_push(v, &x));
  }
  size_t old_len = v->len;
  size_t src = old_len / 2;
  expect_int("full int vec: insert(0, get(len / 2))", vec_insert(v, 0, vec_get(v, src)), 1);
  expect_size("  ...len grew by one", v->len, old_len + 1);
  const int* p = vec_get(v, 0);
  expect_true("  ...new first element is a copy", p && *p == 100 + (int)src);
  p = vec_get(v, 1);
  expect_true("  ...the old first element moved to 1", p && *p == 100);
  p = vec_get(v, v->len - 1);
  expect_true("  ...the last element is unchanged", p && *p == 100 + (int)old_len - 1);
  vec_free(v);

  /* full vec of 104-byte structs: elem_size is not 1 or 4, so a bytes-vs-elements mix-up shows */
  v = vec_new(sizeof(struct blob));
  CHECK(v);
  struct blob b = make_blob(0);
  CHECK(vec_push(v, &b));
  while (v->len < v->capacity) {
    b = make_blob((int)v->len);
    CHECK(vec_push(v, &b));
  }
  old_len = v->len;
  int last_id = (int)old_len - 1;
  expect_int("full blob vec: insert(0, get(last))", vec_insert(v, 0, vec_get(v, old_len - 1)), 1);
  expect_size("  ...len grew by one", v->len, old_len + 1);
  expect_true("  ...new first element is a copy of the old last", blob_ok(vec_get(v, 0), last_id));
  expect_true("  ...the old first element moved to 1", blob_ok(vec_get(v, 1), 0));
  expect_true("  ...the last element is still the old last", blob_ok(vec_get(v, v->len - 1), last_id));
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

/* ---------- reserve ---------- */

static void section_reserve(void) {
  printf("\n-- reserve --\n");

  vec_t* v = make_ints((const int[]){1, 2, 3}, 3);
  expect_int("reserve(100)", vec_reserve(v, 100), 1);
  expect_true("  ...capacity is at least 100", v->capacity >= 100);
  expect_ints("  ...elements are unchanged (the buffer moved)", v, (const int[]){1, 2, 3}, 3);

  /* never shrinks */
  size_t cap = v->capacity;
  expect_int("reserve(1) on a bigger vec", vec_reserve(v, 1), 1);
  expect_size("  ...capacity is unchanged", v->capacity, cap);
  expect_int("reserve(0)", vec_reserve(v, 0), 1);
  expect_size("  ...capacity is unchanged", v->capacity, cap);
  vec_free(v);

  /* a brand-new vec has no buffer yet */
  v = vec_new(sizeof(int));
  CHECK(v);
  expect_int("reserve(0) on a brand-new vec", vec_reserve(v, 0), 1);
  expect_int("reserve(10) on a brand-new vec", vec_reserve(v, 10), 1);
  expect_true("  ...capacity is at least 10", v->capacity >= 10);
  expect_size("  ...len is still 0", v->len, 0);
  vec_free(v);

  /* the whole point of reserve: pushing up to that capacity never reallocates */
  v = vec_new(sizeof(int));
  CHECK(v);
  CHECK(vec_reserve(v, 100));
  size_t allocs = v->alloc_count;
  int zero = 0;
  CHECK(vec_push(v, &zero));
  const int* p = vec_get(v, 0);
  for (int i = 1; i < 100; i++) {
    CHECK(vec_push(v, &i));
  }
  expect_size("100 pushes after reserve(100): len", v->len, 100);
  expect_size("  ...no new allocations", v->alloc_count, allocs);
  expect_true("  ...a pointer from vec_get is still valid", p == vec_get(v, 0));
  vec_free(v);

  /* and without reserve, growth happens in big steps (doubling), not one slot at a time */
  v = vec_new(sizeof(int));
  CHECK(v);
  for (int i = 0; i < 1000; i++) {
    CHECK(vec_push(v, &i));
  }
  expect_true("1000 pushes need far fewer than 1000 allocations", v->alloc_count < 20);
  vec_free(v);

  /* refused requests leave the vec alone (a message is printed to stderr) */
  v = make_ints((const int[]){1, 2, 3}, 3);
  cap = v->capacity;
  expect_int("reserve(SIZE_MAX) is refused", vec_reserve(v, (size_t)-1), 0);
  expect_ints("  ...elements are untouched", v, (const int[]){1, 2, 3}, 3);
  expect_size("  ...capacity is untouched", v->capacity, cap);
  vec_free(v);

  /* just past the limit: capacity * elem_size would WRAP AROUND to a small number
   * if the guard were missing, and realloc would happily succeed with a tiny block */
  v = vec_new(sizeof(struct blob));
  CHECK(v);
  expect_int("reserve(SIZE_MAX / elem_size + 1) is refused",
            vec_reserve(v, (size_t)-1 / sizeof(struct blob) + 1), 0);
  expect_size("  ...capacity is untouched", v->capacity, 0);
  vec_free(v);
}

/* ---------- resize ---------- */

static void test_resize(const char* label, const int* base, size_t n, size_t new_len,
                        const int* fill, const int* want, size_t want_n) {
  vec_t* v = make_ints(base, n);
  int ret = vec_resize(v, new_len, fill);
  if (ret != 1) {
    printf("FAIL %s: returned %d, want 1\n", label, ret);
    failures++;
  } else {
    expect_ints(label, v, want, want_n);
  }
  vec_free(v);
}

static int is_all_zero(const void* p, size_t n) {
  const unsigned char* b = p;
  for (size_t i = 0; i < n; i++) {
    if (b[i] != 0) return 0;
  }
  return 1;
}

static void section_resize(void) {
  printf("\n-- resize --\n");

  const int seven = 7;
  test_resize("grow with a fill value", (const int[]){1, 2}, 2, 5, &seven, (const int[]){1, 2, 7, 7, 7}, 5);
  test_resize("grow with NULL fill gives zeros", (const int[]){1, 2}, 2, 4, NULL, (const int[]){1, 2, 0, 0}, 4);
  test_resize("grow an empty vec", NULL, 0, 3, &seven, (const int[]){7, 7, 7}, 3);
  test_resize("shrink", (const int[]){1, 2, 3, 4}, 4, 2, NULL, (const int[]){1, 2}, 2);
  test_resize("shrink ignores the fill value", (const int[]){1, 2, 3}, 3, 1, &seven, (const int[]){1}, 1);
  test_resize("same length", (const int[]){1, 2, 3}, 3, 3, NULL, (const int[]){1, 2, 3}, 3);
  test_resize("resize to 0", (const int[]){1, 2, 3}, 3, 0, NULL, NULL, 0);

  /* shrink keeps the old bytes in memory, so growing again must overwrite them */
  vec_t* v = make_ints((const int[]){5, 6, 7, 8}, 4);
  size_t cap = v->capacity;
  CHECK(vec_resize(v, 1, NULL));
  expect_size("shrink keeps capacity", v->capacity, cap);
  CHECK(vec_resize(v, 4, NULL));
  expect_ints("shrink then grow with NULL: no stale values come back", v, (const int[]){5, 0, 0, 0}, 4);
  vec_free(v);

  /* growing past the capacity: the buffer has to move */
  v = make_ints((const int[]){1, 2, 3}, 3);
  expect_int("resize(20) crosses the capacity", vec_resize(v, 20, &seven), 1);
  expect_size("  ...len", v->len, 20);
  int ok = vec_ok("resize(20)", v);
  for (size_t i = 0; i < 20 && ok; i++) {
    const int* q = vec_get(v, i);
    int want = i < 3 ? (int)i + 1 : 7;
    if (!q || *q != want) ok = 0;
  }
  expect_true("  ...old elements kept, new ones are 7", ok);
  vec_free(v);

  /* fill pointing INSIDE the vec, with spare capacity (no reallocation) */
  v = make_ints((const int[]){10, 20, 30}, 3);
  expect_int("resize(6, get(1)): fill from inside the vec", vec_resize(v, 6, vec_get(v, 1)), 1);
  expect_ints("  ...result", v, (const int[]){10, 20, 30, 20, 20, 20}, 6);
  vec_free(v);

  /* fill pointing INSIDE a full vec: the buffer moves during the call */
  v = vec_new(sizeof(int));
  CHECK(v);
  int first = 100;
  CHECK(vec_push(v, &first));
  while (v->len < v->capacity) {
    int x = 100 + (int)v->len;
    CHECK(vec_push(v, &x));
  }
  size_t old_len = v->len;
  expect_int("full vec: resize(len + 5, get(2))", vec_resize(v, old_len + 5, vec_get(v, 2)), 1);
  expect_size("  ...len", v->len, old_len + 5);
  ok = vec_ok("full vec resize", v);
  for (size_t i = old_len; i < old_len + 5 && ok; i++) {
    const int* q = vec_get(v, i);
    if (!q || *q != 102) ok = 0;
  }
  expect_true("  ...the 5 new elements are copies of element 2", ok);
  const int* q = vec_get(v, 0);
  expect_true("  ...element 0 is untouched", q && *q == 100);
  vec_free(v);

  /* a size that cannot be allocated: refused, and the vec is still usable */
  v = make_ints((const int[]){1, 2, 3}, 3);
  cap = v->capacity;
  expect_int("resize(SIZE_MAX) is refused", vec_resize(v, (size_t)-1, &seven), 0);
  expect_ints("  ...elements are untouched", v, (const int[]){1, 2, 3}, 3);
  expect_size("  ...capacity is untouched", v->capacity, cap);
  expect_int("  ...the vec is still usable: push", vec_push(v, &seven), 1);
  expect_ints("  ...after the push", v, (const int[]){1, 2, 3, 7}, 4);
  vec_free(v);

  /* 104-byte elements: a bytes-vs-elements mix-up shows up here */
  v = vec_new(sizeof(struct blob));
  CHECK(v);
  struct blob b0 = make_blob(0), b1 = make_blob(1), fill = make_blob(7);
  CHECK(vec_push(v, &b0));
  CHECK(vec_push(v, &b1));
  expect_int("blob vec: resize(6, &fill)", vec_resize(v, 6, &fill), 1);
  ok = blob_ok(vec_get(v, 0), 0) && blob_ok(vec_get(v, 1), 1);
  for (size_t i = 2; i < 6 && ok; i++) {
    if (!blob_ok(vec_get(v, i), 7)) ok = 0;
  }
  expect_true("  ...old elements kept, 4 new copies of the fill", ok);

  expect_int("blob vec: resize(8, NULL)", vec_resize(v, 8, NULL), 1);
  ok = blob_ok(vec_get(v, 5), 7) && vec_get(v, 6) && vec_get(v, 7);
  expect_true("  ...element 5 untouched", ok);
  expect_true("  ...element 6 is all zero bytes", is_all_zero(vec_get(v, 6), sizeof(struct blob)));
  expect_true("  ...element 7 is all zero bytes", is_all_zero(vec_get(v, 7), sizeof(struct blob)));
  vec_free(v);
}

/* ---------- clone ---------- */

static void section_vec_clone(void) {
  printf("\n-- vec_clone --\n");

  /* The clone's capacity is a design choice, so it is deliberately not tested. */

  vec_t* v = make_ints((const int[]){1, 2, 3}, 3);
  vec_t* c = vec_clone(v);
  CHECK(c);
  expect_ints("clone: same content", c, (const int[]){1, 2, 3}, 3);
  expect_size("clone: elem_size", c->elem_size, sizeof(int));
  expect_true("clone: has its own buffer", c->data != v->data);

  /* changing the clone leaves the original alone */
  int nine = 9;
  CHECK(vec_push(c, &nine));
  int* p = vec_get(c, 0);
  *p = 42;
  expect_ints("clone: the original after changing the clone", v, (const int[]){1, 2, 3}, 3);
  expect_ints("clone: the clone after the changes", c, (const int[]){42, 2, 3, 9}, 4);

  /* and the other way around */
  vec_clear(v);
  expect_ints("clone: unaffected by clearing the original", c, (const int[]){42, 2, 3, 9}, 4);

  /* the clone outlives the original: ASan catches it if they secretly share memory */
  vec_free(v);
  expect_ints("clone: still readable after the original is freed", c, (const int[]){42, 2, 3, 9}, 4);
  vec_free(c);

  /* a brand-new vec has no buffer at all */
  v = vec_new(sizeof(int));
  CHECK(v);
  c = vec_clone(v);
  CHECK(c);
  expect_ints("clone of a brand-new empty vec", c, NULL, 0);
  expect_int("  ...the clone is usable: push", vec_push(c, &nine), 1);
  expect_ints("  ...after the push", c, (const int[]){9}, 1);
  vec_free(c);
  vec_free(v);

  /* a vec that has grown several times */
  v = vec_new(sizeof(int));
  CHECK(v);
  for (int i = 0; i < 1000; i++) {
    CHECK(vec_push(v, &i));
  }
  c = vec_clone(v);
  CHECK(c);
  expect_size("clone of 1000 elements: len", c->len, 1000);
  int ok = vec_ok("clone of 1000 elements", c);
  for (int i = 0; i < 1000 && ok; i++) {
    const int* q = vec_get(c, (size_t)i);
    if (!q || *q != i) ok = 0;
  }
  expect_true("  ...every element matches", ok);
  vec_free(c);
  vec_free(v);

  /* 104-byte elements */
  v = vec_new(sizeof(struct blob));
  CHECK(v);
  for (int id = 0; id < 20; id++) {
    struct blob b = make_blob(id);
    CHECK(vec_push(v, &b));
  }
  c = vec_clone(v);
  CHECK(c);
  ok = c->len == 20;
  for (int id = 0; id < 20 && ok; id++) {
    if (!blob_ok(vec_get(c, (size_t)id), id)) ok = 0;
  }
  expect_true("blob vec clone: all 20 elements match", ok);
  vec_free(c);
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
  section_self_push();
  section_self_insert();
  section_reserve();
  section_resize();
  section_vec_clone();

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
