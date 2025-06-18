#include "tm_stdio.h"

#include "stddef.h"

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
    crs->x = (crs->ptr - tm_vram_start) % TM_WIDTH;
    crs->y = (crs->ptr - tm_vram_start) / TM_WIDTH;

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
