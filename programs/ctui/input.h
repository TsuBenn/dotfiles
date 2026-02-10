#ifndef TUI_INPUT_H
#define TUI_INPUT_H

enum Key {
    KEY_ARROW_UP,
    KEY_ARROW_DOWN,
    KEY_ARROW_RIGHT,
    KEY_ARROW_LEFT,
};

void disable_raw_mode();
void enable_raw_mode();
int read_key();

#endif

