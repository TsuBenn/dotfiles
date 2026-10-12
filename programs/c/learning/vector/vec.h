#ifndef VEC_H
#define VEC_H

#include <stddef.h>

typedef struct Vec {
  void* data;
  size_t len;
  size_t capacity;
  size_t elem_size;
  size_t alloc_count;
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
 * Create a new empty `vec` with specified type size.
 *
 * Returns `NULL` if `elem_size == 0` or allocation fails.
 *
 * The caller owns the result and must free it with `vec_free()`
 */
vec_t* vec_clone(const vec_t* vec);

/**
 * Create a new empty `vec` with specified type.
 * This macro calls `vec_new()` with type wrapped inside of sizeof()
 */
 #define vec_new_t(type) (vec_new(sizeof(type)))

/**
 * Free a `vec`.
 *
 * Safe to call with `NULL`. The pointer must not be used afterwards.
 */
void vec_free(vec_t* vec);

/**
 * Push an `elem` to the back of `vec`.
 *
 * `elem` can be pointing into `vec`
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
 * Cast a `vec_get()` into a specified type.
 */
#define vec_get_t(vec, index, type) (((type*)vec_get((vec), (index))))

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

/**
 * Makes sure `vec` can hold at least `capacity` elements without reallocating.
 *
 * Never shrinks: if `capacity <= vec->capacity`, nothing happens and 1 is returned.
 * `vec->len` and the elements are unchanged.
 *
 * Returns 1 on success, returns 0 if allocation fails (`vec` is left unchanged).
 *
 * May move the buffer, so pointers from vec_get() are invalidated.
 */
int vec_reserve(vec_t* vec, size_t capacity);

/**
 * Changes the length of `vec` to `new_len`.
 *
 * If `new_len > vec->len`, every new element is a copy of the `vec->elem_size`
 * bytes at `fill`.
 * If `new_len <= vec->len`, the extra elements are dropped, `fill` is ignored,
 * and the capacity is unchanged.
 * `fill == NULL` means that every new element will be Zero Bytes.
 *
 * Returns 1 on success, returns 0 if `new_len` is too large or allocation fails
 * (`vec` is left unchanged).
 *
 * May move the buffer, so pointers from vec_get() are invalidated.
 */
int vec_resize(vec_t* vec, size_t new_len, const void* fill);

#endif
