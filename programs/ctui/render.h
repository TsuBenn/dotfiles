#ifndef TUI_RENDER_H
#define TUI_RENDER_H

typedef struct {
    char data[8192];
    int len;
} RenderBuffer;

void rb_append(RenderBuffer *rb, const char *string, ...);
void rb_draw(RenderBuffer *rb);

#endif

