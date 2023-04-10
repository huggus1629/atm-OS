#include "stdint.h"

#ifndef STDIO_H
#define STDIO_H

#define width 640
#define height 480

#define char_width 8
#define char_height 16

#define cols width / char_width
#define rows height / char_height

#define tab_len 4

#define WHITE (COLOR) { 255, 255, 255 }
#define BLACK (COLOR) { 0, 0, 0 }
#define DUMMY_C (COLOR) {}
#define DUMMY_L (LINE_FMT) {}


typedef struct color
{
    uint8_t b;
    uint8_t g;
    uint8_t r;
} COLOR;

typedef struct pixel
{
    COLOR c;
    char _;
} PIXEL;

typedef struct point
{
    uint16_t x;
    uint16_t y;
} POINT;

typedef struct line_fmt
{
    COLOR c;
    uint16_t thickness;
} LINE_FMT;

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

typedef struct font_style
{
    COLOR color;
    FONT_FMT fmt;
} STYLE;

typedef struct cursor
{
    POINT c_pos;
    POINT exact_pos;
    STYLE style;
} CURSOR;


extern int put_pixel(uint16_t x, uint16_t y, COLOR c);
extern int put_point(POINT p, COLOR c);
extern int put_rect(POINT p1, POINT p2, MODE mode, COLOR f_col, LINE_FMT outline);

extern CURSOR cursor;
void cursor_set_exact_pos(CURSOR* crs);
void cursor_next(CURSOR* crs); 
void cursor_down(CURSOR* crs);
void cursor_newline(CURSOR* crs);
void cursor_tab(CURSOR* crs);
void cursor_carriage_return(CURSOR* crs);

extern int putc(char c);
extern int puts(char* s);


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


#endif // STDIO_H