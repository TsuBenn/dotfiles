#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tsring.h"

/* Stops the test program immediately. Used only for setup that must not fail. */
#define CHECK(x) do { if (!(x)) { fprintf(stderr, "setup failed: %s (line %d)\n", #x, __LINE__); exit(1); } } while (0)

static int failures = 0;

/* ---------- reporting helpers ---------- */

/* Rules that must ALWAYS hold for a valid string_t, no matter what was done to it:
 *   - the string and its buffer exist
 *   - len matches the real length of the text
 *   - len never exceeds capacity */
static int invariants(const char* label, const string_t* s) {
  if (!s || !s->buf) {
    printf("FAIL %s: string or buffer is NULL\n", label);
    failures++;
    return 0;
  }
  size_t real_len = strlen(s->buf);
  if (s->len != real_len) {
    printf("FAIL %s: len is %zu but the content is %zu long\n", label, s->len, real_len);
    failures++;
    return 0;
  }
  if (s->len > s->capacity) {
    printf("FAIL %s: len %zu is bigger than capacity %zu\n", label, s->len, s->capacity);
    failures++;
    return 0;
  }
  return 1;
}

static void expect_str(const char* label, const string_t* s, const char* want) {
  if (!invariants(label, s)) return;
  if (strcmp(s->buf, want) == 0) {
    printf("PASS %s = \"%s\"\n", label, s->buf);
  } else {
    printf("FAIL %s: got \"%s\", want \"%s\"\n", label, s->buf, want);
    failures++;
  }
}

/* For long strings: only checks the invariants, without printing the content. */
static void expect_valid(const char* label, const string_t* s) {
  if (invariants(label, s)) {
    printf("PASS %s (len %zu)\n", label, s->len);
  }
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

static int all_chars(const string_t* s, char c) {
  for (size_t i = 0; i < s->len; i++) {
    if (s->buf[i] != c) return 0;
  }
  return 1;
}

static string_t* make(const char* text) {
  string_t* s = string_from(text);
  CHECK(s);
  return s;
}

/* ---------- from / new ---------- */

static void section_from_new(void) {
  printf("\n-- from / new --\n");

  string_t* s = make("hello");
  expect_str("from(\"hello\")", s, "hello");
  string_free(s);

  s = make("");
  expect_str("from(\"\")", s, "");
  string_free(s);

  string_t* n = string_new();
  CHECK(n);
  expect_str("new()", n, "");
  string_free(n);

  /* from must COPY its input, not point at it */
  char src[] = "abc";
  s = make(src);
  src[0] = 'X';
  expect_str("from copies its input", s, "abc");
  string_free(s);

  char big[201];
  memset(big, 'x', 200);
  big[200] = '\0';
  s = make(big);
  expect_size("from(200 chars) len", s->len, 200);
  expect_valid("from(200 chars)", s);
  string_free(s);
}

/* ---------- clear ---------- */

static void section_clear(void) {
  printf("\n-- clear --\n");

  string_t* s = make("hello");
  size_t cap = s->capacity;
  string_clear(s);
  expect_str("clear", s, "");
  expect_size("clear keeps capacity", s->capacity, cap);

  string_clear(s);
  expect_str("clear on an already empty string", s, "");

  expect_int("push_str after clear", string_push_str(s, "again"), 1);
  expect_str("content after clear + push", s, "again");
  string_free(s);
}

/* ---------- eq ---------- */

static void section_eq(void) {
  printf("\n-- eq --\n");

  string_t* a = make("hello");
  string_t* b = make("hello");
  string_t* c = make("help!");
  string_t* d = make("hell");
  string_t* e = make("");
  string_t* f = make("");

  expect_int("eq same content", string_eq(a, b), 1);
  expect_int("eq same length, different content", string_eq(a, c), 0);
  expect_int("eq different length (one is a prefix)", string_eq(a, d), 0);
  expect_int("eq both empty", string_eq(e, f), 1);
  expect_int("eq empty vs non-empty", string_eq(a, e), 0);
  expect_int("eq with itself", string_eq(a, a), 1);

  /* same text but a bigger capacity must still be equal */
  CHECK(string_push_str(b, " world"));
  CHECK(string_remove_back(b, 6));
  expect_int("eq ignores capacity", string_eq(a, b), 1);

  string_free(a);
  string_free(b);
  string_free(c);
  string_free(d);
  string_free(e);
  string_free(f);
}

/* ---------- push_str / push_string ---------- */

static void section_push(void) {
  printf("\n-- push_str / push_string --\n");

  string_t* s = make("ab");
  expect_int("push_str normal", string_push_str(s, "cd"), 1);
  expect_str("push_str normal result", s, "abcd");
  expect_int("push_str empty", string_push_str(s, ""), 1);
  expect_str("push_str empty result", s, "abcd");
  string_free(s);

  s = make("");
  expect_int("push_str onto empty", string_push_str(s, "abc"), 1);
  expect_str("push_str onto empty result", s, "abc");
  string_free(s);

  /* "abcdefgh" is 8 chars, the starting capacity, so one more char forces a grow */
  s = make("abcdefgh");
  expect_int("push_str past capacity", string_push_str(s, "i"), 1);
  expect_str("push_str past capacity result", s, "abcdefghi");
  string_free(s);

  char hundred[101];
  memset(hundred, 'z', 100);
  hundred[100] = '\0';
  s = make("a");
  expect_int("push_str 100 chars at once", string_push_str(s, hundred), 1);
  expect_size("push_str 100 chars at once len", s->len, 101);
  expect_valid("push_str 100 chars at once", s);
  string_free(s);

  /* push_string */
  s = make("ab");
  string_t* t = make("cd");
  expect_int("push_string normal", string_push_string(s, t), 1);
  expect_str("push_string normal result", s, "abcd");
  expect_str("push_string leaves the other string alone", t, "cd");
  string_free(t);

  t = make("");
  expect_int("push_string empty", string_push_string(s, t), 1);
  expect_str("push_string empty result", s, "abcd");
  string_free(t);
  string_free(s);

  s = make("abcdefgh");
  t = make("ijklmnop");
  expect_int("push_string past capacity", string_push_string(s, t), 1);
  expect_str("push_string past capacity result", s, "abcdefghijklmnop");
  string_free(t);
  string_free(s);

  /* many small pushes: grows several times, ASan watches every write */
  s = make("");
  for (int i = 0; i < 1000; i++) {
    CHECK(string_push_str(s, "x"));
  }
  expect_size("1000 pushes len", s->len, 1000);
  expect_valid("1000 pushes", s);
  expect_int("1000 pushes are all 'x'", all_chars(s, 'x'), 1);
  string_free(s);
}

/* ---------- insert ---------- */

static void test_insert(const char* base, const char* other, size_t pos, int want_ret, const char* want_str) {
  string_t* s = make(base);
  string_t* o = make(other);
  char label[160];
  snprintf(label, sizeof(label), "insert(\"%s\", \"%s\", %zu)", base, other, pos);

  int ret = string_insert(s, o, pos);
  if (ret != want_ret) {
    printf("FAIL %s: returned %d, want %d\n", label, ret, want_ret);
    failures++;
  } else {
    expect_str(label, s, want_str);
  }
  string_free(s);
  string_free(o);
}

static void section_insert(void) {
  printf("\n-- insert --\n");

  test_insert("abcd", "XY", 0, 1, "XYabcd");   /* at the front */
  test_insert("abcd", "XY", 2, 1, "abXYcd");   /* in the middle */
  test_insert("abcd", "XY", 4, 1, "abcdXY");   /* at the end (position == len) */
  test_insert("abcd", "XY", 5, 0, "abcd");     /* past the end: refused, unchanged */
  test_insert("abcd", "", 2, 1, "abcd");       /* inserting nothing */
  test_insert("", "XY", 0, 1, "XY");           /* into an empty string */
  test_insert("", "XY", 1, 0, "");             /* position 1 on an empty string */
  test_insert("abcdefgh", "XY", 4, 1, "abcdXYefgh");  /* forces a capacity grow */
  test_insert("a", "b", 1, 1, "ab");
  test_insert("a", "b", 0, 1, "ba");

  char hundred[101];
  memset(hundred, 'z', 100);
  hundred[100] = '\0';
  string_t* s = make("abcd");
  string_t* o = make(hundred);
  expect_int("insert 100 chars in the middle", string_insert(s, o, 2), 1);
  expect_size("insert 100 chars in the middle len", s->len, 104);
  expect_valid("insert 100 chars in the middle", s);
  expect_int("starts with \"ab\"", strncmp(s->buf, "ab", 2) == 0, 1);
  expect_int("ends with \"cd\"", strcmp(s->buf + 102, "cd") == 0, 1);
  string_free(s);
  string_free(o);

  /* many inserts at the front */
  s = make("");
  o = make("ab");
  for (int i = 0; i < 100; i++) {
    CHECK(string_insert(s, o, 0));
  }
  expect_size("100 inserts at the front len", s->len, 200);
  expect_valid("100 inserts at the front", s);
  string_free(s);
  string_free(o);
}

/* ---------- remove_back / remove_front ---------- */

/* `fn` is a function pointer: it lets one helper test both remove functions.
 * (ffmpeg uses callbacks like this all the time.) */
typedef int (*remove_fn)(string_t*, size_t);

static void test_remove(const char* name, remove_fn fn, const char* base, size_t size, int want_ret, const char* want_str) {
  string_t* s = make(base);
  size_t cap = s->capacity;
  char label[160];
  snprintf(label, sizeof(label), "%s(\"%s\", %zu)", name, base, size);

  int ret = fn(s, size);
  if (ret != want_ret) {
    printf("FAIL %s: returned %d, want %d\n", label, ret, want_ret);
    failures++;
  } else {
    expect_str(label, s, want_str);
    if (s->capacity != cap) {
      printf("FAIL %s: capacity changed from %zu to %zu\n", label, cap, s->capacity);
      failures++;
    }
  }
  string_free(s);
}

static void section_remove_back(void) {
  printf("\n-- remove_back --\n");

  test_remove("remove_back", string_remove_back, "hello", 2, 1, "hel");
  test_remove("remove_back", string_remove_back, "hello", 0, 1, "hello");
  test_remove("remove_back", string_remove_back, "hello", 5, 1, "");       /* exactly len */
  test_remove("remove_back", string_remove_back, "hello", 6, 0, "hello");  /* more than len: refused */
  test_remove("remove_back", string_remove_back, "a", 1, 1, "");
  test_remove("remove_back", string_remove_back, "", 0, 1, "");
  test_remove("remove_back", string_remove_back, "", 1, 0, "");

  /* the string must stay usable afterwards */
  string_t* s = make("hello");
  CHECK(string_remove_back(s, 2));
  expect_int("push_str after remove_back", string_push_str(s, "p!"), 1);
  expect_str("remove_back then push", s, "help!");
  string_free(s);
}

static void section_remove_front(void) {
  printf("\n-- remove_front --\n");

  test_remove("remove_front", string_remove_front, "hello", 2, 1, "llo");
  test_remove("remove_front", string_remove_front, "hello", 0, 1, "hello");
  test_remove("remove_front", string_remove_front, "hello", 5, 1, "");       /* exactly len */
  test_remove("remove_front", string_remove_front, "hello", 6, 0, "hello");  /* more than len: refused */
  test_remove("remove_front", string_remove_front, "a", 1, 1, "");
  test_remove("remove_front", string_remove_front, "", 0, 1, "");
  test_remove("remove_front", string_remove_front, "", 1, 0, "");
  test_remove("remove_front", string_remove_front, "abcdefghij", 3, 1, "defghij");

  string_t* s = make("hello");
  CHECK(string_remove_front(s, 2));
  expect_int("push_str after remove_front", string_push_str(s, "!"), 1);
  expect_str("remove_front then push", s, "llo!");
  string_free(s);
}

/* ---------- slice ---------- */

static void test_slice(const char* src, size_t start, size_t end, const char* want) {
  string_t* s = make(src);
  char label[160];
  snprintf(label, sizeof(label), "slice(\"%s\", %zu, %zu)", src, start, end);
  string_t* r = string_slice(s, start, end);
  expect_str(label, r, want);
  string_free(r);
  string_free(s);
}

static void section_slice(void) {
  printf("\n-- slice --\n");

  test_slice("0123456789", 2, 5, "234");
  test_slice("0123456789", 0, 10, "0123456789");  /* the whole string */
  test_slice("0123456789", 0, 1, "0");
  test_slice("0123456789", 9, 10, "9");
  test_slice("0123456789", 0, 0, "");             /* empty range */
  test_slice("0123456789", 3, 3, "");
  test_slice("0123456789", 5, 2, "");             /* start after end */
  test_slice("0123456789", 7, 100, "789");        /* end is clamped to len */
  test_slice("0123456789", 10, 10, "");
  test_slice("0123456789", 11, 20, "");           /* start past the end */
  test_slice("", 0, 5, "");

  /* the slice is an independent copy */
  string_t* s = make("hello");
  string_t* r = string_slice(s, 1, 4);
  string_clear(s);
  expect_str("slice survives clearing the original", r, "ell");
  string_free(r);
  string_free(s);
}

/* ---------- clone ---------- */

static void section_clone(void) {
  printf("\n-- clone --\n");

  string_t* a = make("hello");
  string_t* c = string_clone(a);
  expect_str("clone content", c, "hello");
  expect_int("clone has its own buffer", a->buf != c->buf, 1);

  CHECK(string_push_str(c, "!"));
  expect_str("changing the clone leaves the original alone", a, "hello");
  expect_str("clone after push", c, "hello!");
  string_free(c);

  string_clear(a);
  c = string_clone(a);
  expect_str("clone of an empty string", c, "");
  string_free(c);
  string_free(a);

  /* a string that has grown past its first capacity */
  a = make("");
  for (int i = 0; i < 100; i++) {
    CHECK(string_push_str(a, "ab"));
  }
  c = string_clone(a);
  expect_int("clone of a grown string equals the original", string_eq(a, c), 1);
  expect_valid("clone of a grown string", c);
  string_free(c);
  string_free(a);
}

/* ---------- main ---------- */

int main(void) {
  section_from_new();
  section_clear();
  section_eq();
  section_push();
  section_insert();
  section_remove_back();
  section_slice();
  section_clone();
  section_remove_front();

  /* Aliasing: the SAME string passed as both arguments. Uncomment ONE at a time,
   * at the very end (a sanitizer abort stops the whole run), and see what happens.
   *
   *   string_t* s = make("ab");
   *   string_push_string(s, s);        // expect "abab"
   *   expect_str("push_string with itself", s, "abab");
   *
   *   string_t* s = make("abcd");
   *   string_insert(s, s, 2);          // "ab" + "abcd" + "cd"
   *   expect_str("insert with itself", s, "ababcdcd");
   */

  printf("\n%s (%d failure%s)\n", failures ? "SOME TESTS FAILED" : "ALL TESTS PASSED",
         failures, failures == 1 ? "" : "s");
  return failures ? 1 : 0;
}
