#ifndef TM_STDIO_H
#define TM_STDIO_H

#include "stdint.h"

// Text mode fallback has 80x25 character

#define TM_WIDTH 80
#define TM_HEIGHT 25

// NOT USED WITH GRAPHICS MODE
typedef struct c_entry {
    uint8_t c_val;
    uint8_t color;
} C_ENTRY;

typedef struct tm_cursor {
    C_ENTRY* ptr;
    uint8_t x;
    uint8_t y;
} TM_CURSOR;
extern void tm_initcursor(TM_CURSOR* c);
extern void tm_update_x_y(TM_CURSOR* c);
extern void tm_update_ptr(TM_CURSOR* c);

extern void tm_c_putc(C_ENTRY c, TM_CURSOR* crs);
extern void tm_c_puts(char* s, uint8_t color, TM_CURSOR* crs);
extern void tm_puts(char* s, TM_CURSOR* crs);

#endif