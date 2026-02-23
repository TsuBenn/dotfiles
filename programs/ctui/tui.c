#include "tui.h"
#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <conio.h>
#include <windows.h>
#else
#include <termios.h>
#include <unistd.h>
#endif

/* ================================
   CLEAR
================================ */

void tui_clear(void) {
#ifdef _WIN32
    system("cls");
#else
    system("clear");
#endif
}

/* ================================
   RAW MODE
================================ */

#ifdef _WIN32

static DWORD original_mode;

void tui_enable_raw(void) {
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    GetConsoleMode(hStdin, &original_mode);

    DWORD mode = original_mode;
    mode &= ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
    SetConsoleMode(hStdin, mode);
}

void tui_disable_raw(void) {
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    SetConsoleMode(hStdin, original_mode);
}

#else

static struct termios original_termios;

void tui_enable_raw(void) {
    tcgetattr(STDIN_FILENO, &original_termios);

    struct termios raw = original_termios;
    raw.c_lflag &= ~(ICANON | ECHO);
    raw.c_cc[VMIN] = 1;
    raw.c_cc[VTIME] = 0;

    tcsetattr(STDIN_FILENO, TCSANOW, &raw);
}

void tui_disable_raw(void) {
    tcsetattr(STDIN_FILENO, TCSANOW, &original_termios);
}

#endif

/* ================================
   KEY INPUT
================================ */

TuiKey tui_get_key(void) {
    TuiKey key = { TUI_KEY_NONE, 0 };

#ifdef _WIN32

    int ch = _getch();

    if (ch == 0 || ch == 224) {
        int arrow = _getch();
        switch (arrow) {
            case 72: key.type = TUI_KEY_UP; break;
            case 80: key.type = TUI_KEY_DOWN; break;
            case 75: key.type = TUI_KEY_LEFT; break;
            case 77: key.type = TUI_KEY_RIGHT; break;
        }
        return key;
    }

    if (ch == 13) key.type = TUI_KEY_ENTER;
    else if (ch == 8) key.type = TUI_KEY_BACKSPACE;
    else if (ch == 27) key.type = TUI_KEY_ESC;
    else {
        key.type = TUI_KEY_CHAR;
        key.ch = (char)ch;
    }

#else

    int ch = getchar();

    if (ch == 27) {
        int next1 = getchar();
        if (next1 == '[') {
            int next2 = getchar();
            switch (next2) {
                case 'A': key.type = TUI_KEY_UP; break;
                case 'B': key.type = TUI_KEY_DOWN; break;
                case 'C': key.type = TUI_KEY_RIGHT; break;
                case 'D': key.type = TUI_KEY_LEFT; break;
            }
            return key;
        }
        key.type = TUI_KEY_ESC;
        return key;
    }

    if (ch == '\n') key.type = TUI_KEY_ENTER;
    else if (ch == 127) key.type = TUI_KEY_BACKSPACE;
    else {
        key.type = TUI_KEY_CHAR;
        key.ch = (char)ch;
    }

#endif

    return key;
}

/* ================================
   MENU
================================ */

void tui_render_menu(const TuiMenu* menu) {
    printf("=== %s ===\n\n", menu->title);

    for (size_t i = 0; i < menu->item_count; i++) {
        printf("%c %s\n",
               (i == menu->selected) ? '>' : ' ',
               menu->items[i]);
    }

    printf("\n↑ ↓ or W/S | Enter select | ESC back\n");
}

void tui_menu_handle_key(TuiMenu* menu, TuiKey key) {
    if (key.type == TUI_KEY_UP && menu->selected > 0)
        menu->selected--;

    else if (key.type == TUI_KEY_DOWN &&
             menu->selected + 1 < menu->item_count)
        menu->selected++;

    if (key.type == TUI_KEY_CHAR) {
        if ((key.ch == 'w' || key.ch == 'W') && menu->selected > 0)
            menu->selected--;
        else if ((key.ch == 's' || key.ch == 'S') &&
                 menu->selected + 1 < menu->item_count)
            menu->selected++;
    }
}

/* ================================
   CONFIRM
================================ */

void tui_render_confirm(const TuiConfirm* confirm) {
    printf("%s\n\n", confirm->message);
    printf("[Y] Yes | [N] No\n");
}

void tui_confirm_handle_key(TuiConfirm* confirm, TuiKey key) {
    if (key.type == TUI_KEY_CHAR) {
        if (key.ch == 'y' || key.ch == 'Y')
            confirm->result = 1;
        else if (key.ch == 'n' || key.ch == 'N')
            confirm->result = 0;
    }
}

/* ================================
   SCROLL
================================ */

void tui_render_scroll(const TuiScroll* scroll) {
    printf("=== %s ===\n\n", scroll->title);

    size_t end = scroll->scroll_offset + scroll->visible_lines;
    if (end > scroll->line_count)
        end = scroll->line_count;

    for (size_t i = scroll->scroll_offset; i < end; i++)
        printf("%s\n", scroll->lines[i]);

    printf("\n↑ ↓ or W/S | ESC back\n");
}

void tui_scroll_handle_key(TuiScroll* scroll, TuiKey key) {
    if (key.type == TUI_KEY_UP && scroll->scroll_offset > 0)
        scroll->scroll_offset--;

    else if (key.type == TUI_KEY_DOWN &&
             scroll->scroll_offset + scroll->visible_lines < scroll->line_count)
        scroll->scroll_offset++;

    if (key.type == TUI_KEY_CHAR) {
        if ((key.ch == 'w' || key.ch == 'W') &&
            scroll->scroll_offset > 0)
            scroll->scroll_offset--;
        else if ((key.ch == 's' || key.ch == 'S') &&
                 scroll->scroll_offset + scroll->visible_lines < scroll->line_count)
            scroll->scroll_offset++;
    }
}

/* ================================
   INPUT
================================ */

void tui_render_input(const TuiInput* input) {
    printf("%s\n\n", input->prompt);
    printf("> %s\n", input->buffer);
    printf("\nENTER confirm | ESC cancel\n");
}

void tui_input_handle_key(TuiInput* input, TuiKey key) {
    if (key.type == TUI_KEY_BACKSPACE) {
        if (input->cursor_pos > 0) {
            input->cursor_pos--;
            input->buffer[input->cursor_pos] = '\0';
        }
    }
    else if (key.type == TUI_KEY_CHAR) {
        if (input->cursor_pos + 1 < input->buffer_size) {
            input->buffer[input->cursor_pos++] = key.ch;
            input->buffer[input->cursor_pos] = '\0';
        }
    }
}
