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

    COLOR pink = (COLOR) {112, 2, 214};
    COLOR purple = (COLOR) {150, 79, 155};
    COLOR blue = (COLOR) {168, 56, 0};

    put_rect((POINT) {100, 100}, (POINT) {260, 136}, FILL, pink, (LINE_FMT) {0});
    put_rect((POINT) {100, 136}, (POINT) {260, 154}, FILL, purple, (LINE_FMT) {0});
    put_rect((POINT) {100, 154}, (POINT) {260, 190}, FILL, blue, (LINE_FMT) {0});

    for (size_t i = 0; i < 16; i++)
    {
            puts("\n\t\t\t\t\tTest 1234567890 +\"*%&/()=?^");
    }

    return;
}
