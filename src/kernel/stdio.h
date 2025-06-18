#ifndef STDIO_H
#define STDIO_H

#include "stdint.h"
#include "vbe.h"

#define SCREEN_W FBI.DisplayWidth
#define SCREEN_H FBI.DisplayHeight

#define CHAR_W 8
#define CHAR_H 16

#define CHAR_COLS (SCREEN_W / CHAR_W)
#define CHAR_ROWS (SCREEN_H / CHAR_H)

#define TAB_LEN 4

typedef uint32_t Pixel;

typedef struct point
{
    uint16_t x;
    uint16_t y;
} POINT;

typedef enum mode
{
    FILL = 0,
    OUTLINE = 1,
    BOTH = 2
} MODE;

typedef enum font_fmt
{
    NORMAL = 0b0,
    BOLD = 0b1,
    UNDERLINE = 0b100,
    STRIKETHRU = 0b1000
} FONT_FMT;

typedef struct cursor
{
    POINT c_pos;
    POINT exact_pos;
} CURSOR;

Pixel NewPixel(uint8_t red, uint8_t green, uint8_t blue);
int PutPixel(uint16_t x, uint16_t y, Pixel px);

extern CURSOR cursor;
void cursor_set_exact_pos(CURSOR* crs);
void cursor_next(CURSOR* crs); 
void cursor_down(CURSOR* crs);
void cursor_newline(CURSOR* crs);
void cursor_tab(CURSOR* crs);
void cursor_carriage_return(CURSOR* crs);

extern int putc(char c);
extern int puts(char* s);

#endif // STDIO_H