#include <termios.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>

struct termios orig_termios;

enum Key {
    KEY_ARROW_UP,
    KEY_ARROW_DOWN,
    KEY_ARROW_RIGHT,
    KEY_ARROW_LEFT,
};

void disable_raw_mode() {
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

void enable_raw_mode() {
    tcgetattr(STDIN_FILENO, &orig_termios);
    atexit(disable_raw_mode);

    struct termios raw = orig_termios;
    raw.c_lflag &= ~(ECHO | ICANON);

    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

int read_key() {
    char c;
    if (read(STDIN_FILENO, &c, 1) != 1) {
        return -1;
    }

    if (c != '\033') {
        return c;
    }

    char seq[2];

    if (read(STDIN_FILENO, &seq[0], 1) != 1) {
        return '\033';
    }

    if (read(STDIN_FILENO, &seq[1], 1) != 1) {
        return '\033';
    }

    if (seq[0] == '[') {
        switch (seq[1]) {
            case 'A': return KEY_ARROW_UP;
            case 'B': return KEY_ARROW_DOWN;
            case 'C': return KEY_ARROW_RIGHT;
            case 'D': return KEY_ARROW_LEFT;
        }
    }

    return '\033';
}




