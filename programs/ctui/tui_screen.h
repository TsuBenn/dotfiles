#ifndef TUI_SCREEN_H
#define TUI_SCREEN_H

#include "render.h"
#include "input.h"

typedef struct TuiScreen TuiScreen;

struct TuiScreen {
    void (*render)(TuiScreen *self, RenderBuffer *rb);
    void (*input)(TuiScreen *self, int key);
};

#endif

