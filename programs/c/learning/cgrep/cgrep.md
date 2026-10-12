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
input.txt
main.c
Makefile
```

# Files

## File: main.c
```c
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "../string/tsring.h"

int main(int argc, char *argv[]) {
    if (argc < 3) {
        usage:
        fprintf(stderr, "Usage: %s <pattern> -f <file>   [-i]\n", argv[0]);
        fprintf(stderr, "       %s <pattern>    <string> [-i]\n", argv[0]);
        return 1;
    }

    string_t* pattern = string_from(argv[1]);

    int read_from_file = 0;
    int case_insensitive = 0;

    string_t* content;

    if (strcmp(argv[2], "-f") == 0) {
        if (!argv[3]) {
            goto usage;
        }
        content = string_read_from_file(argv[3]);
        read_from_file = 1;
    } else {
        content = string_from(argv[2]);
    }

    if (argc > 3 + read_from_file && strcmp(argv[3 + read_from_file], "-i") == 0) {
        case_insensitive = 1;
        string_to_lowercase(pattern);
    }

    if (!content) {
        return 1;
    }

    string_t* buf = string_new();
    string_reserve(buf, 1024);

    size_t offset = 0;
    size_t i = 0;

    size_t match = 0;
    size_t pat_len = pattern->len;

    while (string_read_line(content, buf, &offset) != NULL) {
        string_t* tmp;

        if (case_insensitive) {
            tmp = string_clone(buf);
            if (!tmp) {
                fprintf(stderr, "main (tmp: string_clone)");
                return 1;
            }
            string_to_lowercase(tmp);
        } else {
            tmp = buf;
        }

        if (string_contains_string(tmp, pattern, &match)) {
            printf("%5zu | %s\n", i, buf->buf);
            memset(buf->buf, ' ', buf->len);
            memset((char*)buf->buf + match, '^', pat_len);
            printf("      | %s\n", buf->buf);
        }

        if (case_insensitive) {
          string_free(tmp);
        }

        i++;
    }

    string_free(buf);
    string_free(content);
    string_free(pattern);

    return 0;
}
```

## File: Makefile
```makefile
CC = gcc
CFLAGS = -Wall -Wextra -g -fsanitize=address,undefined
BIN = cgrep

all: build/$(BIN)

build/$(BIN): main.c ../string/tsring.c ../string/tsring.h
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ main.c ../string/tsring.c

main: build/$(BIN)
	./build/$(BIN)

test: all
	./build/$(BIN) woman -f input.txt

clean:
	rm -rf build

.PHONY: all test clean
```
