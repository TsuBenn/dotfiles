#include "input.h"
#include "tsring.h"
#include <stddef.h>
#include <stdio.h>
#include <string.h>

int input_get_string(string_t* buf, const char* prompt, const char* default_string) {
    if (default_string && strstr(prompt, "{}")) {
        if (!string_copy_str(buf, prompt)) {
            return 0;
        }
        string_t* hint = string_format(NULL, "[%s]", default_string);
        if (!string_replace_string(buf, "{}", hint, NULL)) {
            return 0;
        }
        printf("%s", buf->buf);
        string_free(hint);
    } else {
        printf("%s", prompt);
    }
    if (!string_read_input(buf)) {
        return 0;
    }
    if (string_is_empty(buf)) {
        if (default_string) {
            string_copy_str(buf, default_string);
        } else {
            return 0;
        }
    }
    return 1;
}

int input_get_int(int *buf, const char *prompt, int *min, int *max, int *default_int) {
    string_t* str_buf = string_new(64);
    string_t* hint = string_new(32);
    if ((min || max || default_int) && strstr(prompt, "{}")) {
        if (!string_copy_str(str_buf, prompt)) {
            goto fail;
        }
        if (min || max) {
            if (min) {
                string_push_format(hint, "[%d ->", *min);
            } else {
                string_push_str(hint, "[-inf ->");
            }
            if (max) {
                string_push_format(hint, " %d]", *max);
            } else {
                string_push_str(hint, " inf]");
            }
        }
        if (!string_replace_string(str_buf, "{}", hint, NULL)) {
            goto fail;
        }
        printf("%s", str_buf->buf);
    } else {
        printf("%s", prompt);
    }
    if (!string_read_input(str_buf)) {
        goto fail;
    }
    if (string_is_empty(str_buf)) {
        if (default_int) {
            *buf = *default_int;
            goto done;
        } else {
            goto fail;
        }
    }
    if (!string_parse_int(str_buf, buf)) {
        goto fail;
    }
    if (min && *buf < *min) {
        return -1;
    }
    if (max && *buf > *max) {
        return -1;
    }
    done:
    string_free(str_buf);
    string_free(hint);
    return 1;
    fail:
    string_free(hint);
    string_free(str_buf);
    return 0;
}

int input_get_long(long *buf, const char *prompt, long *min, long *max, long *default_long) {
    string_t* str_buf = string_new(64);
    string_t* hint = string_new(32);
    if ((min || max || default_long) && strstr(prompt, "{}")) {
        if (!string_copy_str(str_buf, prompt)) {
            goto fail;
        }
        if (min || max) {
            if (min) {
                string_push_format(hint, "[%ld ->", *min);
            } else {
                string_push_str(hint, "[-inf ->");
            }
            if (max) {
                string_push_format(hint, " %ld]", *max);
            } else {
                string_push_str(hint, " inf]");
            }
        }
        if (!string_replace_string(str_buf, "{}", hint, NULL)) {
            goto fail;
        }
        printf("%s", str_buf->buf);
    } else {
        printf("%s", prompt);
    }
    if (!string_read_input(str_buf)) {
        goto fail;
    }
    if (string_is_empty(str_buf)) {
        if (default_long) {
            *buf = *default_long;
            goto done;
        } else {
            goto fail;
        }
    }
    if (!string_parse_long(str_buf, buf)) {
        goto fail;
    }
    if (min && buf < min) {
        return -1;
    }
    if (max && buf > max) {
        return -1;
    }
    done:
    string_free(str_buf);
    string_free(hint);
    return 1;
    fail:
    string_free(hint);
    string_free(str_buf);
    return 0;
}

int input_get_float(float *buf, const char *prompt, float *min, float *max, float *default_float) {
    string_t* str_buf = string_new(64);
    string_t* hint = string_new(32);
    if ((min || max || default_float) && strstr(prompt, "{}")) {
        if (!string_copy_str(str_buf, prompt)) {
            goto fail;
        }
        if (min || max) {
            if (min) {
                string_push_format(hint, "[%.2lf ->", *min);
            } else {
                string_push_str(hint, "[-inf ->");
            }
            if (max) {
                string_push_format(hint, " %.2lf]", *max);
            } else {
                string_push_str(hint, " inf]");
            }
        }
        if (!string_replace_string(str_buf, "{}", hint, NULL)) {
            goto fail;
        }
        printf("%s", str_buf->buf);
    } else {
        printf("%s", prompt);
    }
    if (!string_read_input(str_buf)) {
        goto fail;
    }
    if (string_is_empty(str_buf)) {
        if (default_float) {
            *buf = *default_float;
            goto done;
        } else {
            goto fail;
        }
    }
    if (!string_parse_float(str_buf, buf)) {
        goto fail;
    }
    if (min && buf < min) {
        return -1;
    }
    if (max && buf > max) {
        return -1;
    }
    done:
    string_free(str_buf);
    string_free(hint);
    return 1;
    fail:
    string_free(hint);
    string_free(str_buf);
    return 0;
}

int input_get_double(double *buf, const char *prompt, double *min, double *max, double *default_double) {
    string_t* str_buf = string_new(64);
    string_t* hint = string_new(32);
    if ((min || max || default_double) && strstr(prompt, "{}")) {
        if (!string_copy_str(str_buf, prompt)) {
            goto fail;
        }
        if (min || max) {
            if (min) {
                string_push_format(hint, "[%.2lf ->", *min);
            } else {
                string_push_str(hint, "[-inf ->");
            }
            if (max) {
                string_push_format(hint, " %.2lf]", *max);
            } else {
                string_push_str(hint, " inf]");
            }
        }
        if (!string_replace_string(str_buf, "{}", hint, NULL)) {
            goto fail;
        }
        printf("%s", str_buf->buf);
    } else {
        printf("%s", prompt);
    }
    if (!string_read_input(str_buf)) {
        goto fail;
    }
    if (string_is_empty(str_buf)) {
        if (default_double) {
            *buf = *default_double;
            goto done;
        } else {
            goto fail;
        }
    }
    if (!string_parse_double(str_buf, buf)) {
        goto fail;
    }
    if (min && buf < min) {
        return -1;
    }
    if (max && buf > max) {
        return -1;
    }
    done:
    string_free(str_buf);
    string_free(hint);
    return 1;
    fail:
    string_free(hint);
    string_free(str_buf);
    return 0;
}

int input_get_menu_choice(int* buf, const char* prompt, char** menu_items, size_t menu_size, int* default_choice) {
    for (size_t i = 0; i < menu_size; i++) {
        printf("%2zu. %s\n", i + 1, menu_items[i]);
    }
    int status = 0;
    status = input_get_int(buf, prompt, &(int){1}, &(int){(int)menu_size}, default_choice);
    if (status == 1) {
        (*buf)--;
    }
    return status;
}

void input_pause(const char* prompt) {
    printf("%s", prompt);
    getchar();
    fflush(stdin);
}
