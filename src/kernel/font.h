#ifndef FONT_H
#define FONT_H


typedef struct char_bmp
{
    char row[16];
} CHAR_BMP;

extern CHAR_BMP ascii[];


#endif // FONT_H

/*
{{ // ^
        0,
        0,
        0b00000000,
        0b00000000,
        0b00000000,
        0b00000000,
        0b00000000,
        0b00000000,
        0b00000000,
        0b00000000,
        0b00000000,
        0,
        0,
        0,
        0,
        0
    }},
*/