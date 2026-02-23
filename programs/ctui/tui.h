#ifndef TUI_H
#define TUI_H

#include <stddef.h>

/* ================================
   KEY SYSTEM
================================ */

typedef enum {
    TUI_KEY_NONE = 0,
    TUI_KEY_UP,
    TUI_KEY_DOWN,
    TUI_KEY_LEFT,
    TUI_KEY_RIGHT,
    TUI_KEY_ENTER,
    TUI_KEY_BACKSPACE,
    TUI_KEY_ESC,
    TUI_KEY_CHAR
} TuiKeyType;

typedef struct {
    TuiKeyType type;
    char ch;
} TuiKey;

void tui_enable_raw(void);
void tui_disable_raw(void);
TuiKey tui_get_key(void);

/* ================================
   UTIL
================================ */

void tui_clear(void);

/* ================================
   MENU
================================ */

typedef struct {
    const char* title;
    const char** items;
    size_t item_count;
    size_t selected;
} TuiMenu;

void tui_render_menu(const TuiMenu* menu);
void tui_menu_handle_key(TuiMenu* menu, TuiKey key);

/* ================================
   CONFIRM
================================ */

typedef struct {
    const char* message;
    int result; /* -1 none, 0 no, 1 yes */
} TuiConfirm;

void tui_render_confirm(const TuiConfirm* confirm);
void tui_confirm_handle_key(TuiConfirm* confirm, TuiKey key);

/* ================================
   SCROLL
================================ */

typedef struct {
    const char* title;
    const char** lines;
    size_t line_count;
    size_t scroll_offset;
    size_t visible_lines;
} TuiScroll;

void tui_render_scroll(const TuiScroll* scroll);
void tui_scroll_handle_key(TuiScroll* scroll, TuiKey key);

/* ================================
   INPUT
================================ */

typedef struct {
    const char* prompt;
    char* buffer;
    size_t buffer_size;
    size_t cursor_pos;
} TuiInput;

void tui_render_input(const TuiInput* input);
void tui_input_handle_key(TuiInput* input, TuiKey key);

#endif
