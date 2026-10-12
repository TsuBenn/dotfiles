#include "vec.h"
#include <stddef.h>
#include <stdint.h>
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
    if (new > SIZE_MAX / 2) {
      return target;
    }
    new *= 2;
  }
  return new;
}

static int vec_expand_capacity(vec_t *vec, size_t target_capacity) {
  size_t new_capacity = vec_new_capacity(vec->capacity, target_capacity);
  return vec_reserve(vec, new_capacity);
}

static void *vec_slot(const vec_t *vec, size_t i) {
  return (char *)vec->data + i * vec->elem_size;
}

static void check_elem_in_vec(const vec_t *vec, const void *elem,
                              int *elem_in_vec, size_t *elem_byte_offset) {
  *elem_in_vec = 0;
  *elem_byte_offset = 0;
  if (vec->data) {
    uintptr_t start = (uintptr_t)vec->data;
    uintptr_t end = start + vec->len * vec->elem_size;
    uintptr_t e = (uintptr_t)elem;
    if (e >= start && e < end) {
      *elem_in_vec = 1;
      *elem_byte_offset = (size_t)(e - start);
    }
  }
}

vec_t *vec_new(size_t elem_size) {
  if (elem_size == 0) {
    return NULL;
  }

  vec_t *new_vec = malloc(sizeof(vec_t));
  if (!new_vec) {
    return NULL;
  }

  new_vec->data = NULL;
  new_vec->len = 0;
  new_vec->capacity = 0;
  new_vec->elem_size = elem_size;
  new_vec->alloc_count = 0;

  return new_vec;
}

vec_t* vec_clone(const vec_t* vec) {
  vec_t* new_vec = vec_new(vec->elem_size);
  if (!new_vec) {
    return NULL;
  }
  if (!vec_reserve(new_vec, vec->len)) {
    vec_free(new_vec);
    return NULL;
  }
  if (vec->len > 0) {
    memcpy(new_vec->data, vec->data, vec->len * vec->elem_size);
  }
  new_vec->len = vec->len;
  return new_vec;
}

void vec_free(vec_t *vec) {
  if (!vec) {
    return;
  }
  if (vec->data) {
    free(vec->data);
  }
  free(vec);
}

int vec_push(vec_t *vec, const void *elem) {
  int elem_in_vec = 0;
  size_t elem_byte_offset = 0;

  check_elem_in_vec(vec, elem, &elem_in_vec, &elem_byte_offset);

  if (vec->len + 1 > vec->capacity) {
    if (!vec_expand_capacity(vec, vec->capacity + 1)) {
      return 0;
    }
  }

  if (elem_in_vec) {
    elem = (char *)vec->data + elem_byte_offset;
  }

  memcpy(vec_slot(vec, vec->len), elem, vec->elem_size);
  vec->len++;
  return 1;
}

void *vec_get(const vec_t *vec, size_t index) {
  if (index >= vec->len) {
    return NULL;
  }
  return vec_slot(vec, index);
}

int vec_pop(vec_t *vec, void *out) {
  if (vec->len == 0) {
    return 0;
  }
  vec->len--;
  memcpy(out, vec_slot(vec, vec->len), vec->elem_size);
  return 1;
}

int vec_insert(vec_t *vec, size_t index, const void *elem) {
  if (index > vec->len) {
    return 0;
  }

  int elem_in_vec = 0;
  size_t elem_byte_offset = 0;

  check_elem_in_vec(vec, elem, &elem_in_vec, &elem_byte_offset);
  if (elem_in_vec && elem_byte_offset >= index * vec->elem_size) {
    elem_byte_offset += vec->elem_size;
  }

  if (vec->len + 1 > vec->capacity) {
    if (!vec_expand_capacity(vec, vec->capacity + 1)) {
      return 0;
    }
  }

  if (elem_in_vec) {
    elem = (char *)vec->data + elem_byte_offset;
  }

  char *insert_addr = vec_slot(vec, index);
  memmove(insert_addr + vec->elem_size, insert_addr,
          vec->elem_size * (vec->len - index));
  memcpy(insert_addr, elem, vec->elem_size);
  vec->len++;
  return 1;
}

int vec_remove(vec_t *vec, size_t index) {
  if (index >= vec->len) {
    return 0;
  }
  char *remove_addr = vec_slot(vec, index);
  memmove(remove_addr, remove_addr + vec->elem_size,
          vec->elem_size * (vec->len - index - 1));
  vec->len--;
  return 1;
}

void vec_clear(vec_t *vec) { vec->len = 0; }

int vec_reserve(vec_t *vec, size_t capacity) {
  if (capacity <= vec->capacity) {
    return 1;
  }
  if (capacity > SIZE_MAX / vec->elem_size) {
    fprintf(stderr, "vec_reserve: size exceeds the maximum\n");
    return 0;
  }
  void *new_data = realloc(vec->data, vec->elem_size * capacity);
  if (!new_data) {
    perror("vec_reserve (new_data: realloc)");
    return 0;
  }
  vec->alloc_count++;
  vec->data = new_data;
  vec->capacity = capacity;
  return 1;
}

int vec_resize(vec_t *vec, size_t new_len, const void *fill) {
  if (new_len <= vec->len) {
    vec->len = new_len;
    return 1;
  }

  int elem_in_vec = 0;
  size_t elem_byte_offset = 0;

  if (fill != NULL) {
    check_elem_in_vec(vec, fill, &elem_in_vec, &elem_byte_offset);
  }

  if (new_len > vec->capacity) {
    if (!vec_expand_capacity(vec, new_len)) {
      return 0;
    }
  }

  if (elem_in_vec) {
    fill = (char *)vec->data + elem_byte_offset;
  }

  if (fill == NULL) {
    memset(vec_slot(vec, vec->len), 0, (new_len-vec->len)*vec->elem_size);
  } else {
    for (size_t i = vec->len; i < new_len; i++) {
      memcpy(vec_slot(vec, i), fill, vec->elem_size);
    }
  }

  vec->len = new_len;
  return 1;
}
