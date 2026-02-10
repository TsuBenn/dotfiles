#include "tui.h"
#include "input.h"
#include "render.h"
#include "tui_context.h"
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>

void tui_start() {
    enable_raw_mode();

    atexit(tui_shutdown);

    write(STDOUT_FILENO, "\033[?25l", 6);

    write(STDOUT_FILENO, "\033[2J\033[H", 7);
}

void tui_shutdown() {
    write(STDOUT_FILENO, "\033[?25h", 6);
}

void tui_begin(TuiContext *scr) {
    scr->rb.len = 0;

    rb_append(&scr->rb, "\033[H");
}

void tui_end(TuiContext *scr) {
    rb_draw(&scr->rb);
}

