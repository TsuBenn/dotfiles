#ifndef TSRING_H
#define TSRING_H

#include <stddef.h>
#include <stdio.h>

/**
 * String type.
 */
typedef struct String {
  char *buf;
  size_t len;
  size_t cap;
} string_t;

/**
 * Ensure `buf` is pointing to a string. If `buf` is pointing to `NULL`, create a new string and point `buf` to that new string.
 *
 * When new string is created, `buf` owns the string and the caller must manage and free it with `string_free()`
 *
 * Returns `1` on success, returns `0` on allocation fails.
 */
int string_ensure_buf(string_t** buf);

/**
 * Prints the string along with its metadata for debug purposes.
 */
void string_debug(const string_t *str);

/**
 * Creates a new string by copying `string`.
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t *string_from(const char *string);

/**
 * Creates a new string from an allocated `buf` with provided `size`.
 *
 * The caller are responsible of providing the correct `size`, representing the
 * allocated memory size for `buf`. The returned `string_t` will take ownership
 * the `buf` provided.
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t *string_from_buf(char *buf, size_t size);

/**
 * Creates a new empty string with `init_cap`.
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t *string_new(size_t init_cap);

/**
 * Free a string.
 *
 * Safe to call with `NULL`. The pointer must not be used afterwards.
 */
void string_free(string_t *string);

/**
 * Reserve a certain amount of capacity of a `str`.
 *
 * If `new_capacity` is `<= str->capacity`, nothing will happens and the
 * function will return true.
 *
 * Returns `1` on success, returns `0` if allocation fails (`str` is left
 * unchanged).
 */
int string_reserve(string_t *str, size_t new_capacity);

/**
 * Comparing 2 strings.
 * Returns `1` if equal, returns `0` if not.
 */
int string_eq_string(const string_t *str, const string_t *other_str);

/**
 * Comparing a strings with a char* string.
 * Returns `1` if equal, returns `0` if not.
 */
int string_eq_str(const string_t *str, const char *other_str);

/**
 * Clearing a string content.
 * This action will not shrink the string's capacity.
 */
void string_clear(string_t *str);

/**
 * Append `other_str` to the end of `str`.
 *
 * Returns `1` on success, returns `0` if allocation (capacity expansion) fails
 * (`str` is left unchanged).
 */
int string_push_string(string_t *str, const string_t *other_str);

/**
 * Append `other_str` (a char*) to the end of `str`.
 *
 * Returns `1` on success, returns `0` if allocation (capacity expansion) fails
 * (`str` is left unchanged).
 */
int string_push_str(string_t *str, const char *other_str);

/**
 * Insert `other_str` into `str` at `position`.
 *
 * Returns `1` on success, returns `0` if allocation (capacity expansion) fails
 * (`str` is left unchanged) or `position` > `str->len`.
 */
int string_insert_string(string_t *str, const string_t *other_str, size_t position);

/**
 * Insert `other_str` into `str` at `position`.
 *
 * Returns `1` on success, returns `0` if allocation (capacity expansion) fails
 * (`str` is left unchanged) or `position` > `str->len`.
 */
int string_insert_str(string_t *str, const char *other_str, size_t position);

/**
 * Remove `size` amount of character at the back of the string.
 *
 * Returns `1` on success, returns `0` if `size` > `str->len`.
 *
 * This action will not shrink the string's capacity.
 */
int string_remove_back(string_t *str, size_t size);

/**
 * Remove `size` amount of character at the front of the string.
 *
 * Returns `1` on success, returns `0` if `size` > `str->len`.
 *
 * This action will not shrink the string's capacity.
 */
int string_remove_front(string_t *str, size_t size);

/**
 * Create a new string by slicing the provided string from `start` position to
 * `end` position. `start` is included and `end` is excluded.
 *
 * Returns `NULL` if allocation fails, returns an empty string if start >= end.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t *string_slice(const string_t *str, size_t start, size_t end);

/**
 * Cloning an existing string into a new string.
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t *string_clone(const string_t *str);

/**
 * Joining `other_str` into `str` as path.
 *
 * Returns `1` on success, returns `0` if `other_str` is empty or allocation
 * (capacity expansion) fails (`str` is left unchanged).
 */
int string_path_join_string(string_t *str, const string_t *other_str);

/**
 * Joining `other_str` into `str` as path.
 *
 * Returns `1` on success, returns `0` if `other_str` is empty or allocation
 * (capacity expansion) fails (`str` is left unchanged).
 */
int string_path_join_str(string_t *str, const char *other_str);

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
string_t *string_path_filename(const string_t *str);

/**
 * Removes the extension from a path, keeping the directories.
 *
 * The extension starts at the last dot in the last component and runs to the
 * end, so multi-dot extensions are not removed entirely.
 *
 * - A leading dot is part of the name, not an extension (".bashrc" is
 * unchanged).
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
string_t *string_path_stem(const string_t *str);

/**
 * Gets the extension of a path, no dot included.
 *
 * The extension starts at the last dot in the last component and runs to the
 * end.
 *
 * Returns an empty string if no extension were found.
 * Returns `NULL` if allocation fails or provided path is a directory.
 *
 * The caller owns the result and must free it with `string_free()`.
 */
string_t *string_path_get_extension(const string_t *str);

/**
 * Add extension to a path
 *
 * If the provided extension has a leading dot, it will be safely handled.
 * Path that already have the same extension as the provided one will stay
 * unchanged. Path that has a different extension will have the provided one
 * appended at the end.
 *
 * Returns `1` on success, returns `0` if allocation (capacity expansion) fails
 * (`str` is left unchanged) or provided path is a directory.
 */
int string_path_add_extension(string_t *str, const char *ext);

/**
 * Find the first occurance of `pat` in `str`.
 *
 * If found, the position where the first match occured will be assigned to `match_position`
 * `match_position` can be `NULL` if the caller isn't planning on using the value.
 *
 * Inital `match_position` value will be used to start the finding offset. If `match_position` is `NULL`, then it is default to `0`.
 *
 * Returns `1` on found, returns `0` if not.
 */
int string_find_string(const string_t *str, const string_t *pat,
                           size_t *match_position);

/**
 * Find the first occurance of `pat` in `str`.
 *
 * If found, the position where the first match occured will be assigned to `match_position`
 * `match_position` can be `NULL` if the caller isn't planning on using the value.
 *
 * Inital `match_position` value will be used to start the finding offset. If `match_position` is `NULL`, then it is default to `0`.
 *
 * Returns `1` on found, returns `0` if not.
 */
int string_find_str(const string_t *str, const char *pat,
                        size_t *match_position);

/**
 * Read from a file and store it in `buf`
 *
 * If `buf` is NULL, this function will return a newly allocated string and the caller owns the string and must `string_free()`
 *
 * Returns `NULL` if read from file fails or allocation fails (`buf` might have been modified).
 */
string_t *string_read_from_file(const char *file_path, string_t* buf);

/**
 * Read a line starting at `offset` from `str` and store it in `buf`.
 *
 * If `buf` is NULL, this function will return a newly allocated string and the caller owns the string and must `string_free()`
 *
 * The '\n' will not be included in the `buf` as well as the `offset` will be
 * set to the index after the '\n' and not on the '\n'.
 *
 * `buf` will be overriden on success and will have its capacity expands when
 * read line is longer than `buf->capacity`.
 *
 * `offset` will be updated to the index after the next occurence of `\n` or at
 * the next occurance of `\0` if end of string is reached.
 *
 * Returns `buf` on success.
 *
 * Returns `NULL` when end of `str` occured while no character is read or
 * allocation fails on `buf` (`buf` is left unchanged) or `offset == NULL`.
 */
string_t *string_read_line(const string_t *str, string_t *buf, size_t *offset, int ignore_empty);

/**
 * Read a line starting at `offset` from `str` and store it in `buf`.
 *
 * If `buf` is NULL, this function will return a newly allocated string and the caller owns the string and must `string_free()`
 *
 * The '\n' will not be included in the `buf` as well as the `offset` will be
 * set to the index after the '\n' and not on the '\n'.
 *
 * `buf` will be overriden on success and will have its capacity expands when
 * read line is longer than `buf->capacity`.
 *
 * `offset` will be updated to the index after the next occurence of `\n` or at
 * the next occurance of `\0` if end of string is reached.
 *
 * Returns `buf` on success.
 *
 * Returns `NULL` when end of `str` occured while no character is read or
 * allocation fails on `buf` (`buf` is left unchanged) or `offset == NULL`.
 */
string_t *string_read_line_str(const char *str, string_t *buf, size_t *offset, int ignore_empty);

/**
 * Read until a `delimiter` starting at `offset` from `str` and store it in
 * `buf`.
 *
 * If `buf` is NULL, this function will return a newly allocated string and the caller owns the string and must `string_free()`
 *
 * `delimiter` can be multiple characters, representing multiple possible `delimiter`.
 *
 * The 'delimiter' will not be included in the `buf` as well as the `offset`
 * will be set to the index after the 'delimiter' and not on the 'delimiter'.
 *
 * `buf` will be overriden on success and will have its capacity expands when
 * read line is longer than `buf->capacity`.
 *
 * `offset` will be updated to the index after the next occurence of the
 * `delimiter` or at the next occurance of `\0` if end of string is reached.
 *
 * Returns `buf` on success.
 *
 * Returns `NULL` when end of `str` occured while no character is read or
 * allocation fails on `buf` (`buf` is left unchanged) or `offset == NULL` or `delimeter` is an empty string.
 */
string_t *string_read_delimiter(const string_t *str, string_t *buf, size_t *offset, char* delimiter, int ignore_empty);

string_t *string_read_delimiter_str(const char *str, size_t str_len, string_t *buf, size_t *offset, char* delimiter, int ignore_empty);

/**
 * Read a `stream` and flush into `buf` when the `stream` hits the
 * `delimiter`
 *
 * If `buf` is NULL, this function will return a newly allocated string and the caller owns the string and must `string_free()`
 *
 * Return `NULL` if allocation fails or `stream` is at the end of file or
 * `stream` returns an error (`buf` might have been modified).
 */
string_t *string_read_stream(FILE *stream, string_t* buf, char delimiter);

/**
 * Gets a new string from `stdin` and put it in `buf`.
 *
 * If `buf` is NULL, this function will return a newly allocated string and the caller owns the string and must `string_free()`
 *
 * The returned string will exclude the `\n` from 'stdin'.
 *
 * Returns `buf` on success, returns `NULL` if allocation fails (`buf` might have been modified).
 */
string_t* string_read_input(string_t* buf);

/**
 * Parse `int` from `str` and assign to `out`.
 *
 * If `out` is NULL, then this function acts as a `int` checker.
 * On success `out` will be clamped between the maximum and minimum value of an `int`.
 *
 * Returns `1` if parse success, returns `0` if no `int` is found (`out` is left unchanged).
 */
int string_parse_int(const string_t *str, int *out);

/**
 * Parse `long` from `str` and assign to `out`.
 *
 * If `out` is NULL, then this function acts as a `long` checker.
 * On success `out` will be clamped between the maximum and minimum value of a `long`.
 *
 * Returns `1` if parse success, returns `0` if no `long` is found (`out` is left unchanged).
 */
int string_parse_long(const string_t *str, long *out);

/**
 * Parse `float` from `str` and assign to `out`.
 *
 * If `out` is NULL, then this function acts as a `float` checker.
 * On success `out` will be clamped between the maximum and minimum value of a `float`.
 *
 * Returns `1` if parse success, returns `0` if no `float` is found (`out` is left unchanged).
 */
int string_parse_float(const string_t *str, float *out);

/**
 * Parse `double` from `str` and assign to `out`.
 *
 * If `out` is NULL, then this function acts as a `double` checker.
 * On success `out` will be clamped between the maximum and minimum value of a `double`.
 *
 * Returns `1` if parse success, returns `0` if no `double` is found (`out` is left unchanged).
 */
int string_parse_double(const string_t *str, double *out);

/**
 * Check whether the `str` starts with `pat`.
 *
 * Returns `1` if match, returns `0` if not.
 */
int string_starts_with(const string_t *str, const char* pat);

/**
 * Check whether the `str` ends with `pat`.
 *
 * Returns `1` if match, returns `0` if not.
 */
int string_ends_with(const string_t *str, const char* pat);

/**
 * Trims leading and trailing whitespaces.
 *
 * This function will modify `str`, use `string_clone()` if the caller wants a
 * non-destructive `trim()` operation
 */
void string_trim(string_t *str);

/**
 * Join `other_str` into `str` with a `separtor` in between
 *
 * Returns `1` on success, returns `0` if allocation fails (`str` is left unchanged)
 */
int string_join_string(string_t *str, const string_t* other_str, const char* separator);

/**
 * Join `other_str` into `str` with a `separtor` in between
 *
 * Returns `1` on success, returns `0` if allocation fails (`str` is left unchanged)
 */
int string_join_str(string_t *str, const char* other_str, const char* separator);

/**
 * Replace the first occurance of `pat` in `str` with `replacement`
 *
 * If `pat` is not found inside of `str`, nothing will be changed and will be counted as success.
 *
 * The initial value of `match` is used as a starting offset for finding `pat`. After replacement, `match` will be set to the index after the replacement string.
 *
 * Example ("*" is the `match` position):
 *
 * `*Replace this with that`
 *
 * `Replace that* with that`
 *
 * Returns `1` on success, returns `0` if allocation fails (`str` is left unchanged).
 */
int string_replace_str(string_t *str, const char* pat, const char* replacement, size_t *match);

/**
 * Replace the first occurance of `pat` in `str` with `replacement`
 *
 * If `pat` is not found inside of `str`, nothing will be changed and will be counted as success.
 *
 * The initial value of `match` is used as a starting offset for finding `pat`. After replacement, `match` will be set to the index after the replacement string.
 *
 * Example ("*" is the `match` position):
 *
 * `*Replace this with that`
 *
 * `Replace that* with that`
 *
 * Returns `1` on success, returns `0` if allocation fails (`str` is left unchanged).
 */
int string_replace_string(string_t *str, const char* pat, const string_t* replacement, size_t *match);

/**
 * Turns all character within the alphabet into lowercase.
 *
 * This function will modify `str`, use `string_clone()` if the caller wants a
 * non-destructive `to_lowercase()` operation
 */
void string_to_lowercase(string_t *str);

/**
 * Turns all character within the alphabet into uppercase.
 *
 * This function will modify `str`, use `string_clone()` if the caller wants a
 * non-destructive `to_uppercase()` operation
 */
void string_to_uppercase(string_t *str);

/**
 * Check if the string is empty.
 *
 * A string with only whitespace is not considered empty.
 *
 * Returns `1` if empty, returns `0` if not.
 */
int str_is_empty(const char* str);

/**
 * Check if the string is empty.
 *
 * A string with only whitespace is not considered empty.
 *
 * Returns `1` if empty, returns `0` if not.
 */
int string_is_empty(const string_t* str);

/**
 * Replace `str` content with a copy of `other_str` content.
 *
 * Returns `1` on success, returns `0` if allocation fails (`str` is left unchanged).
 */
int string_copy_str(string_t* str, const char* other_str);

/**
 * Replace `str` content with a copy of `other_str` content.
 *
 * Returns `1` on success, returns `0` if allocation fails (`str` is left unchanged).
 */
int string_copy_string(string_t* str, const string_t* other_str);

/**
 * Push string with a formated string.
 *
 * Returns `1` on success, returns `0` on allocation fails (`str` is left unchanged) or format failed.
 */
int string_push_format(string_t* str, const char* format, ...);

/**
 * Format string and replace `buf`.
 *
 * If `buf` is NULL, this function will return a newly allocated string and the caller owns the string and must `string_free()`
 *
 * Returns `NULL` if allocation fails (`buf` might have been modified) or format failed.
 */
string_t* string_format(string_t* buf, const char* format, ...);

/**
 * Chars iterator.
 * Used for fast iteration over a string chars without buffering.
 */
typedef struct Chars {
 char* str;
 char* offset;
} chars_t;

/**
 * Create a chars iterator from a string (char*)
 *
 * Returns `NULL` if allocation fails.
 *
 * The caller owns the result and must use `chars_free()`.
 */
chars_t* chars_from(char* str);

/**
 * Free a chars.
 */
void chars_free(chars_t* chars);

/**
 * Iterate to the next `char` and return a pointer that `char`.
 *
 * Returns `NULL` if end of string.
 */
char* chars_next(chars_t* chars);

/**
 * Iterate to the previous `char` and return a pointer that `char`.
 *
 * Returns `NULL` if start of string.
 */
char* chars_prev(chars_t* chars);

/**
 * Rewind the iterator back to the start of string and return a pointer to the `char` at the start.
 */
char* chars_rewind(chars_t* chars);

/**
 * Iterate forward until `c` and return the pointer to that `c`.
 *
 * Returns `NULL` if end of string.
 */
char* chars_next_until(chars_t* chars, char c);

/**
 * Iterate to the next non-whitespace `char` and return a pointer that `char`.
 *
 * Returns `NULL` if end of string.
 */
char* chars_next_skip_whitespaces(chars_t* chars);

/**
 * Bring the iterator to the next non-whitespace `char`.
 *
 * This operation does not consume the that "non-whitespace `char`".
 * If the current `char` is already non-whitespace `char`, the iterator is left unchanged.
 *
 * Returns '1' on success, returns `0` if end of string.
 */
int chars_skip_whitespaces(chars_t* chars);

/**
 * Check whether the next set of `char` in `chars` matches `pat`.
 *
 * Returns `1` if match, returns `0` if not (`chars` is left unchanged).
 */
int chars_match(chars_t* chars, char* pat);

/**
 * Iterate through and check whether the next set of `char` in `chars` matches `pat`.
 *
 * This operation will consume the chars, for safer check use `chars_match()` instead.
 *
 * Returns `1` if match, returns `0` if not (`chars` might have been modified).
 */
int chars_match_consume(chars_t* chars, char* pat);

#endif
