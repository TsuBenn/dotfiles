#include "input.h"
#include "tsring.h"
#include <string.h>

int input_get_string(string_t* buf, const char* prompt, const char* default_string) {
    if (default_string && strstr(prompt, "{}")) {
        if (!string_copy_str(buf, prompt)) {
            return 0;
        }
        string_t* hint = string_from("[]");
        if (!hint) {
            return 0;
        }
        if (!string_insert_str(hint, default_string, 1) || !string_replace_string(buf, "{}", hint, NULL)) {
            string_free(hint);
            return 0;
        }
        printf("%s", buf->buf);
        string_free(hint);
    } else {
        printf("%s", prompt);
    }
    if (!string_read_input(buf) || (string_is_empty(buf) && !default_string)) {
        return 0;
    }
    return 1;
}

// int input_get_int(int *buf, const char *prompt, int *min, int *max, int *default_int) {
//     if ((min || max || default_int) && strstr(prompt, "{}")) {
//         string_t* hint = string_new(32);
//         if (min || max) {
//             if (min) {
//             }
//         }
//     }
// }
