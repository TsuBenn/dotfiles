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
