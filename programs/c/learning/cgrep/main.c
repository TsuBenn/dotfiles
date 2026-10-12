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
    if (pattern) {
        fprintf(stderr, "main (pattern: string_from)\n");
        return 1;
    }

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
        string_free(pattern);
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
