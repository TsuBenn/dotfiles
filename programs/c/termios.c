#include <termios.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

struct termios orig_termios;

enum Key {
    KEY_ARROW_UP = 1000,
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

typedef struct {
    const char **items;
    int count;
    int selected;
} Menu;

typedef struct {
    char data[8192];
    int len;
} RenderBuffer;

void rb_append(RenderBuffer *rb, const char *string, ...) {
    va_list args;
    va_start(args,string);

    int written = vsnprintf(rb->data + rb->len, sizeof(rb->data) - rb->len, string, args);

    va_end(args);

    if (written > 0) {
        rb->len += written;
    }
}

void rb_draw(RenderBuffer *rb) {
    write(1, rb->data, rb->len);
    rb->len = 0;
}

void draw_menu(RenderBuffer *rb, Menu *menu) {

    rb_append(rb, "\033[2J\033[H");

    for (int i = 0; i < menu->count; i++){
        if (i == menu->selected) {
            rb_append(rb ,"> %s\r\n", menu->items[i]);
        } else {
            rb_append(rb ,"  %s\r\n", menu->items[i]);
        }
    }

    rb_append(rb, "\r\nUse UP or DOWN and Enter, Press Q to quit\r\n");
}

void handle_menu_input(Menu *menu, int key) {
    if (key == KEY_ARROW_UP)
        menu->selected--;
    else if (key == KEY_ARROW_DOWN)
        menu->selected++;
    if (menu->selected >= menu->count) {
        menu->selected = 0;
    } else if (menu->selected < 0) {
        menu->selected = menu->count-1;
    }
}

typedef enum {
    STATE_MENU,
    STATE_LOADING,
    STATE_CONFIRM,
    STATE_INPUT,
    STATE_HELP,
    STATE_NOTIFICATION,
} UIState;

typedef struct {
    UIState state;
    Menu main_menu;
} UI;

void ui_update(UI *ui, int key) {

    switch (ui->state) {

        case STATE_MENU:

            handle_menu_input(&ui->main_menu, key);

            if (key == '\n') {
                switch (ui->main_menu.selected) {
                    case 0: ui->state = STATE_CONFIRM; break;
                    case 1: ui->state = STATE_INPUT; break;
                    case 2: ui->state = STATE_NOTIFICATION; break;
                    case 3: ui->state = STATE_HELP; break;
                    case 4: ui->state = STATE_LOADING; break;
                    case 5: exit(0);
                }
            }
            break;

        case STATE_HELP:
            if (key == 'q' || key == 27)
                ui->state = STATE_MENU;
            break;

        case STATE_LOADING:
            if (key == 'q')
                ui->state = STATE_MENU;
            break;
    }
}

void ui_render(UI *ui, RenderBuffer *rb) {

    switch (ui->state) {

        case STATE_MENU:
            draw_menu(rb, &ui->main_menu);
        break;

        case STATE_HELP:
            rb_append(rb,"\033[2J\033[H");
            rb_append(rb,"HELP SCREEN\r\n\r\n");
            rb_append(rb,"UP/DOWN - Navigate\r\n");
            rb_append(rb,"Enter   - Select\r\n");
            rb_append(rb,"Q       - Back\r\n");
        break;

        case STATE_LOADING:
            rb_append(rb, "\033[2J\033[H");
            rb_append(rb, "Loading...");
            ui->state = STATE_MENU;
        break;
    }
}

int main() {
    enable_raw_mode();

    const char *main_items[] = {
        "Confirmation",
        "Text Input",
        "Notification",
        "Help",
        "Loading Screen",
        "Exit",
    };

    Menu main_menu = {
        .items = main_items,
        .count = 6,
        .selected = 0,
    };

    UI ui = {
        .state = STATE_MENU,
        .main_menu = main_menu,
    };

    int k;

    RenderBuffer rb = {0};

    while (1) {

        k = read_key();

        ui_update(&ui, k);

        ui_render(&ui, &rb);
        rb_draw(&rb);

    }

    return 0;
}

