#ifndef INPUT_H
#define INPUT_H

#include "tsring.h"

/**
 * Get a `string` from the user and put it in `buf`.
 *
 * This function will use `buf` as a buffer for producing prompts to reduce allocation.
 *
 * If `default_string` is not NULL, default_string will be provided if input is blank.
 *
 * If the caller wants more control over the input, use `string_read_input()` instead.
 *
 * Hints can be provided by adding "{}" inside the prompt.
 *
 * Example:
 *
 * `get_string(&buf, "Enter your name {}:", "nobody");`
 *
 * -> What the user will see: `Enter your name [nobody]:`
 *
 * Returns 1 on success, returns 0 if allocation fails (`buf` might have been modified) or input is empty and `default_string` is `NULL`.
 */
int input_get_string(string_t* buf, const char* prompt, const char* default_string);

/**
 * Get a `int` from the user and put it in `buf`.
 *
 * If `default_int` is not NULL, default_int will be provided if input is blank.
 *
 * `min` or `max` represent the range of allowed input, both ends are inclusive.
 * `min` or `max` can be NULL, representing an open end of the allowed range of input.
 *
 * Example:
 * `min = NULL; max = NULL` -> No limits.
 * `min = x; max = NULL` -> Limits the lower bound to x -> [x -> inf].
 * `min = NULL; max = x` -> Limits the upper bound to x -> [-inf -> x].
 * `min = x; max = y` -> Limits both ends from x -> y -> [x -> y].
 *
 * Hints can be provided by adding "{}" inside the prompt.
 *
 * Example:
 *
 * `get_int(&buf, "Enter your number {}:", &(int){0}, &(int){100}, &(int){69});`
 *
 * -> What the user will see: `Enter your name [0 - 100] [69]:`
 *
 * If the caller wants more control over the input, use `string_read_input()` instead.
 *
 * Returns 1 on success, returns 0 if allocation fails (`buf` is left unchanged) or input is empty and `default_int` is `NULL`, returns -1 if ouf of bound.
 */
int input_get_int(int* buf, const char* prompt, int* min, int* max, int* default_int);

/**
 * Get a `long` from the user and put it in `buf`.
 *
 * If `default_long` is not NULL, default_long will be provided if input is blank.
 *
 * `min` or `max` represent the range of allowed input, both ends are inclusive.
 * `min` or `max` can be NULL, representing an open end of the allowed range of input.
 *
 * Example:
 * `min = NULL; max = NULL` -> No limits.
 * `min = x; max = NULL` -> Limits the lower bound to x -> [x -> inf].
 * `min = NULL; max = x` -> Limits the upper bound to x -> [-inf -> x].
 * `min = x; max = y` -> Limits both ends from x -> y -> [x -> y].
 *
 * Hints can be provided by adding "{}" inside the prompt.
 *
 * Example:
 *
 * `get_long(&buf, "Enter your number {}:", &(long){0}, &(long){100}, &(long){69});`
 *
 * -> What the user will see: `Enter your name [0 - 100] [69]:`
 *
 * If the caller wants more control over the input, use `string_read_input()` instead.
 *
 * Returns 1 on success, returns 0 if allocation fails (`buf` is left unchanged) or input is empty and `default_long` is `NULL`, returns -1 if ouf of bound.
 */
int input_get_long(long* buf, const char* prompt, long* min, long* max, long* default_long);

/**
 * Get a `float` from the user and put it in `buf`.
 *
 * If `default_float` is not NULL, default_float will be provided if input is blank.
 *
 * `min` or `max` represent the range of allowed input, both ends are inclusive.
 * `min` or `max` can be NULL, representing an open end of the allowed range of input.
 *
 * Example:
 * `min = NULL; max = NULL` -> No limits.
 * `min = x; max = NULL` -> Limits the lower bound to x -> [x -> inf].
 * `min = NULL; max = x` -> Limits the upper bound to x -> [-inf -> x].
 * `min = x; max = y` -> Limits both ends from x -> y -> [x -> y].
 *
 * Hints can be provided by adding "{}" inside the prompt.
 *
 * Example:
 *
 * `get_float(&buf, "Enter your number {}:", &(float){0}, &(float){100}, &(float){69});`
 *
 * -> What the user will see: `Enter your name [0 - 100] [69]:`
 *
 * If the caller wants more control over the input, use `string_read_input()` instead.
 *
 * Returns 1 on success, returns 0 if allocation fails (`buf` is left unchanged) or input is empty and `default_float` is `NULL`, returns -1 if ouf of bound.
 */
int input_get_float(float* buf, const char* prompt, float* min, float* max, float* default_float);

/**
 * Get a `double` from the user and put it in `buf`.
 *
 * If `default_double` is not NULL, default_double will be provided if input is blank.
 *
 * `min` or `max` represent the range of allowed input, both ends are inclusive.
 * `min` or `max` can be NULL, representing an open end of the allowed range of input.
 *
 * Example:
 * `min = NULL; max = NULL` -> No limits.
 * `min = x; max = NULL` -> Limits the lower bound to x -> [x -> inf].
 * `min = NULL; max = x` -> Limits the upper bound to x -> [-inf -> x].
 * `min = x; max = y` -> Limits both ends from x -> y -> [x -> y].
 *
 * Hints can be provided by adding "{}" inside the prompt.
 *
 * Example:
 *
 * `get_double(&buf, "Enter your number {}:", &(double){0}, &(double){100}, &(double){69});`
 *
 * -> What the user will see: `Enter your name [0 - 100] [69]:`
 *
 * If the caller wants more control over the input, use `string_read_input()` instead.
 *
 * Returns 1 on success, returns 0 if allocation fails (`buf` is left unchanged) or input is empty and `default_double` is `NULL`, returns -1 if ouf of bound.
 */
int input_get_double(double* buf, const char* prompt, double* min, double* max, double* default_double);

/**
 * Print a list of choice from `menu_items` and let the user choose.
 *
 * The input the user puts in range from `1 -> n` with `n` being the number of menu_items.
 * While the choice assigned to `buf` will be put in the range of `0 -> (n-1)`.
 *
 * Returns 1 on success, returns 0 if allocation fails (`buf` is left unchanged) or input is empty and `default_choice` is `NULL`, returns -1 if ouf of bound.
 */
int input_get_menu_choice(int* buf, const char* prompt,char** menu_items, size_t menu_size, int* default_choice);

void input_pause(const char* prompt);

#endif
