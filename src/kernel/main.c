#include "stdint.h"
#include "stddef.h"
#include "stdio.h"
#include "font.h"

#define MODE_FOUND_FLAG_PTR (uint8_t*) 0x7dfd

extern void main()
{ 
    if (*MODE_FOUND_FLAG_PTR)
    {
        TM_CURSOR c;
        tm_initcursor(&c);
        tm_c_puts("Fatal Error: Unsupported graphics adapter!", 0x4f, &c);
        return;
    }

    put_point((POINT) {0, 0}, WHITE);
    put_point((POINT) {width-1, height-1}, WHITE);

    //put_rect((POINT) {0, 0}, (POINT) {width-1, height-1}, FILL, (COLOR) {255, 0, 0}, DUMMY_L);
    //put_rect((POINT) {15, 15}, (POINT) {width-1-15, height-1-15}, OUTLINE, DUMMY_C, (LINE_FMT) {(COLOR) {192, 192, 192}, 3});

    for (unsigned int y = 1; y <= height; y++)
    {
        for (unsigned int x = 1; x <= width; x++)
        {
            put_point((POINT) {x-1, y-1}, (COLOR) {x*x/y, y*y/x, x+y-100});
        }
    }

    put_rect((POINT) {100, 100}, (POINT) {200, 200}, BOTH, (COLOR) {255, 200, 100}, (LINE_FMT) {(COLOR) {1346, 632, 200}, 1});
    put_rect((POINT) {275, 225}, (POINT) {350, 275}, BOTH, (COLOR) {156, 733, 526}, (LINE_FMT) {(COLOR) {567, 215, 834}, 3});
    put_rect((POINT) {150, 150}, (POINT) {300, 250}, BOTH, (COLOR) {234, 525, 12}, (LINE_FMT) {(COLOR) {564, 642, 568}, 5});
 


    put_rect((POINT) {320, 240}, (POINT) {420, 320}, BOTH, (COLOR) {255, 0, 0}, (LINE_FMT) {(COLOR) {0, 255, 255}, 3});

    puts("Hello world");

    return;
}
