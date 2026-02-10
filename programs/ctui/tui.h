#ifndef TUI_CORE_H
#define TUI_CORE_H

#include "tui_context.h"

void tui_start();
void tui_shutdown();

void tui_begin(TuiContext *scr);
void tui_end(TuiContext *scr);

#endif
