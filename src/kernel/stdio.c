#include "stdio.h"
#include "stddef.h"
#include "font.h"

#define vram_start (PIXEL*) *((uint32_t*) 0x7df9)

extern int put_pixel(uint16_t x, uint16_t y, COLOR c)
{
    if (x > width || y > height)
        return -1;
    
    *(y * width + x + vram_start) = (PIXEL) {c};

    return 0;
}

extern int put_point(POINT p, COLOR c)
{
    return put_pixel(p.x, p.y, c);
}

extern int put_rect(POINT p1, POINT p2, MODE mode, COLOR f_col, LINE_FMT outline)
{
    // p1 is always top left corner, p2 is always bottom right corner
    if (p1.x >= p2.x || p1.y >= p2.y)
        return -1;
    
    // loop through each line
    for (size_t line = p1.y; line <= p2.y; line++)
    {
        // calculate offset of current line
        PIXEL* lineoffset = line * width + vram_start;

        if (mode == OUTLINE)
        {
            if (line < p1.y + outline.thickness || line > p2.y - outline.thickness)   // if current line is top or bottom, draw solid line (outline.c)
                for (size_t i = p1.x; i <= p2.x; i++)
                    *(lineoffset + i) = (PIXEL) {outline.c, 0};
            else
            {
                for (size_t i = 0; i < outline.thickness; i++)
                {
                    *(lineoffset + p1.x + i) = (PIXEL) {outline.c, 0};  // if not, draw leftmost and rightmost pixel (outline.c)
                    *(lineoffset + p2.x - i) = (PIXEL) {outline.c, 0};
                }
            }
        }
        
        else if (mode == FILL)              // if draw mode is "fill", draw every pixel with f_col     
            for (size_t i = p1.x; i <= p2.x; i++)
                *(lineoffset + i) = (PIXEL) {f_col, 0};

        else if (mode == BOTH)              // draw mode "fill+outline"
        {
            if (line < p1.y + outline.thickness || line > p2.y - outline.thickness)
                for (size_t i = p1.x; i <= p2.x; i++)
                    *(lineoffset + i) = (PIXEL) {outline.c, 0};
            else
            {
                for (size_t i = p1.x; i <= p2.x; i++)
                {
                    *(lineoffset + i) = (PIXEL) {(i < p1.x + outline.thickness || i > p2.x - outline.thickness) ? outline.c : f_col, 0};  // if at leftmost / rightmost pixel,
                                                                                                // draw using outline.c
                                                                                                // in between, draw using f_col
                }
            }
        }
    }
    
    return 0;
}


// text printing stuff
// ===========================

// global cursor
// ----------------
extern CURSOR cursor = {(POINT) {0, 0}, (POINT) {0, 0}, (STYLE) {{255, 255, 255}, (FONT_FMT) NORMAL}};
unsigned char print_mask[] = {128, 64, 32, 16, 8, 4, 2, 1};

void cursor_set_exact_pos(CURSOR* crs)
{
    crs->exact_pos = (POINT) {crs->c_pos.x * char_width, crs->c_pos.y * char_height};
}

void cursor_next(CURSOR* crs)
{
    crs->c_pos = crs->c_pos.x + 1 < 80 ? (POINT) {crs->c_pos.x + 1, crs->c_pos.y} : (POINT) {0, crs->c_pos.y + 1};
    cursor_set_exact_pos(crs);
}

void cursor_down(CURSOR* crs)
{
    crs->c_pos.y++;
    cursor_set_exact_pos(crs);
}

void cursor_newline(CURSOR* crs)
{
    crs->c_pos = (POINT) {0, crs->c_pos.y + 1};
    cursor_set_exact_pos(crs);
}

void cursor_tab(CURSOR* crs)
{
    crs->c_pos.x = (crs->c_pos.x < (cols - tab_len)) ? crs->c_pos.x + (tab_len - (crs->c_pos.x % tab_len)) : crs->c_pos.x;
    cursor_set_exact_pos(crs);
}

void cursor_carriage_return(CURSOR* crs)
{
    crs->c_pos.x = 0;
    cursor_set_exact_pos(crs);
}

// putc(char c, STYLE s)
// -------------------------
extern int putc(char c)
{
    // special cases
    if (c == '\n')
    {
        cursor_newline(&cursor);
        return 0;
    } else if (c == '\t')
    {
        cursor_tab(&cursor);
        return 0;
    } else if (c == '\r')
    {
        cursor_carriage_return(&cursor);
        return 0;
    }
    

    // normal letter
    for (size_t cy = 0; cy < char_height; cy++)
    {
        for (size_t cx = 0; cx < char_width; cx++)
        {
            put_pixel(cursor.exact_pos.x + cx, cursor.exact_pos.y + cy, (ascii[c].row[cy] & print_mask[cx]) ? WHITE : BLACK);
        }
    }

    cursor_next(&cursor);
    return 0;
}

extern int puts(char* s)
{
    size_t i = 0;
    while (*(s + i))
    {
        putc(*(s + i));
        i++;
    }
    
    cursor_newline(&cursor);
    return 0;
}


//////////////////////////////////////////////////////////////////////////


// ONLY USED AS TEXT MODE FALLBACK IF 640:480:32 MODE ISN'T AVAILABLE
// -------------------------------------------------------------------

#define tm_vram_start (C_ENTRY*) 0xb8000

extern void tm_initcursor(TM_CURSOR* crs)
{
    crs->ptr = tm_vram_start;
    tm_update_x_y(crs);

    return;
}

extern void tm_update_x_y(TM_CURSOR* crs)
{
    crs->x = (crs->ptr - tm_vram_start) % width;
    crs->y = (crs->ptr - tm_vram_start) / width;

    return;
}

extern void tm_update_ptr(TM_CURSOR* crs)
{
    crs->ptr = (80 * crs->y) + crs->x + tm_vram_start;
    return;
}
extern void tm_c_putc(C_ENTRY c, TM_CURSOR* crs)
{
    *(crs->ptr) = c;
    crs->ptr++;
    tm_update_x_y(crs);

    return;
}

extern void tm_c_puts(char* s, uint8_t color, TM_CURSOR* crs)
{
    size_t i = 0;
    while (s[i])
    {
        if (s[i] == '\n')
        {
            crs->y++;
            tm_update_ptr(crs);
        } else if (s[i] == '\r')
        {
            crs->x = 0;
            tm_update_ptr(crs);
        } else
            tm_c_putc((C_ENTRY) { s[i], color }, crs);
        i++;
    }

    return;
}

extern void tm_puts(char* s, TM_CURSOR* crs)
{
    tm_c_puts(s, 0x07, crs);

    return;
}
