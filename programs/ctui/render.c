#include "render.h"
#include <unistd.h>
#include <stdio.h>
#include <stdarg.h>
#include <termios.h>

void rb_append(RenderBuffer *rb, const char *string, ...) {
    va_list args;
    va_start(args, string);
    int written = vsnprintf(rb->data + rb->len, sizeof(rb->data) - rb->len, string, args);
    va_end(args);

    if (written > 0) {
        rb->len += written;
    }
}

void rb_draw(RenderBuffer *rb) {
    write(STDOUT_FILENO, rb->data, rb->len);
    rb->len = 0;
}
