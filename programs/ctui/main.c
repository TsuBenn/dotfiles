#include "tui.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    SCREEN_MAIN_MENU,
    SCREEN_SUB_MENU,
    SCREEN_SCROLL,
    SCREEN_INPUT,
    SCREEN_CONFIRM,
    SCREEN_INFO
} Screen;

int main() {
    tui_enable_raw();
    atexit(tui_disable_raw);

    int running = 1;
    Screen current = SCREEN_MAIN_MENU;

    /* ===============================
       MAIN MENU
    =============================== */

    const char* main_items[] = {
        "Open Sub Menu",
        "Open Scroll Screen",
        "Open Input Screen",
        "Open Confirm Screen",
        "Show Info Screen",
        "Exit Program"
    };

    TuiMenu main_menu = {
        .title = "Main Menu",
        .items = main_items,
        .item_count = 6,
        .selected = 0
    };

    /* ===============================
       SUB MENU
    =============================== */

    const char* sub_items[] = {
        "Do Nothing",
        "Go Back"
    };

    TuiMenu sub_menu = {
        .title = "Sub Menu",
        .items = sub_items,
        .item_count = 2,
        .selected = 0
    };

    /* ===============================
       SCROLL SCREEN
    =============================== */

    const char* scroll_lines[] = {
        "This is line 1",
        "This is line 2",
        "This is line 3",
        "This is line 4",
        "This is line 5",
        "This is line 6",
        "This is line 7",
        "This is line 8",
        "This is line 9",
        "This is line 10"
    };

    TuiScroll scroll = {
        .title = "Scroll Screen Example",
        .lines = scroll_lines,
        .line_count = 10,
        .scroll_offset = 0,
        .visible_lines = 4
    };

    /* ===============================
       INPUT SCREEN
    =============================== */

    char input_buffer[64] = {0};

    TuiInput input = {
        .prompt = "Type something and press ENTER:",
        .buffer = input_buffer,
        .buffer_size = sizeof(input_buffer),
        .cursor_pos = 0
    };

    /* ===============================
       CONFIRM SCREEN
    =============================== */

    TuiConfirm confirm = {
        .message = "Are you sure you want to continue?",
        .result = -1
    };

    /* ===============================
       INFO SCREEN (Uses Scroll Renderer)
    =============================== */

    const char* info_lines[] = {
        "Renderer Feature Overview:",
        "",
        "- Real-time keyboard input",
        "- Arrow key support",
        "- W/S navigation",
        "- Backspace support",
        "- ESC navigation",
        "- Scrollable content",
        "- Menu system",
        "- Confirmation prompt",
        "- Text input handling",
        "",
        "Works on Windows and Linux."
    };

    TuiScroll info_screen = {
        .title = "Renderer Capabilities",
        .lines = info_lines,
        .line_count = 12,
        .scroll_offset = 0,
        .visible_lines = 6
    };

    /* ===============================
       MAIN LOOP
    =============================== */

    while (running) {

        tui_clear();

        switch (current) {
            case SCREEN_MAIN_MENU: tui_render_menu(&main_menu); break;
            case SCREEN_SUB_MENU:  tui_render_menu(&sub_menu); break;
            case SCREEN_SCROLL:    tui_render_scroll(&scroll); break;
            case SCREEN_INPUT:     tui_render_input(&input); break;
            case SCREEN_CONFIRM:   tui_render_confirm(&confirm); break;
            case SCREEN_INFO:      tui_render_scroll(&info_screen); break;
        }

        TuiKey key = tui_get_key();

        /* Global ESC handling */
        if (key.type == TUI_KEY_ESC) {
            if (current == SCREEN_MAIN_MENU)
                running = 0;
            else
                current = SCREEN_MAIN_MENU;
            continue;
        }

        switch (current) {

            /* ================= MENU ================= */

            case SCREEN_MAIN_MENU:
                tui_menu_handle_key(&main_menu, key);

                if (key.type == TUI_KEY_ENTER) {
                    switch (main_menu.selected) {
                        case 0: current = SCREEN_SUB_MENU; break;
                        case 1: current = SCREEN_SCROLL; break;
                        case 2:
                            memset(input_buffer, 0, sizeof(input_buffer));
                            input.cursor_pos = 0;
                            current = SCREEN_INPUT;
                            break;
                        case 3:
                            confirm.result = -1;
                            current = SCREEN_CONFIRM;
                            break;
                        case 4:
                            info_screen.scroll_offset = 0;
                            current = SCREEN_INFO;
                            break;
                        case 5:
                            running = 0;
                            break;
                    }
                }
                break;

            case SCREEN_SUB_MENU:
                tui_menu_handle_key(&sub_menu, key);

                if (key.type == TUI_KEY_ENTER) {
                    if (sub_menu.selected == 1)
                        current = SCREEN_MAIN_MENU;
                }
                break;

            /* ================= SCROLL ================= */

            case SCREEN_SCROLL:
                tui_scroll_handle_key(&scroll, key);
                break;

            case SCREEN_INFO:
                tui_scroll_handle_key(&info_screen, key);
                break;

            /* ================= INPUT ================= */

            case SCREEN_INPUT:
                tui_input_handle_key(&input, key);

                if (key.type == TUI_KEY_ENTER)
                    current = SCREEN_MAIN_MENU;
                break;

            /* ================= CONFIRM ================= */

            case SCREEN_CONFIRM:
                tui_confirm_handle_key(&confirm, key);

                if (confirm.result == 1)
                    current = SCREEN_MAIN_MENU;
                else if (confirm.result == 0)
                    current = SCREEN_MAIN_MENU;
                break;
        }
    }

    tui_clear();
    printf("Program exited cleanly.\n");
    return 0;
}
