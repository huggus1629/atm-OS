#ifndef STDIO_H
#define STDIO_H

#include "stdint.h"
#include "vbe.h"
#include "stddef.h"
#include "assert.h"

#define SCREEN_W FBI.DisplayWidth
#define SCREEN_H FBI.DisplayHeight
#define BPP24 1  // <---------- SET MANUALLY

#define VerifyBoundsPx(x, y, retval) \
    if (!(x < SCREEN_W && y < SCREEN_H)) \
        return retval;

#define CHAR_W 8
#define CHAR_H 16

#define CHAR_COLS (SCREEN_W / CHAR_W)
#define CHAR_ROWS (SCREEN_H / CHAR_H)

#define TAB_LEN 4

typedef DWORD Pixel;

typedef struct point
{
    uint16_t x;
    uint16_t y;
} Point;

typedef struct color
{
    uint8_t Red;
    uint8_t Green;
    uint8_t Blue;
} Color;

typedef struct lineformat
{
    Color Color;
    uint16_t Weight;
} LineFormat;

typedef enum polydrawmode
{
    FILL,
    OUTLINE,
    BOTH
} PolyDrawMode;

typedef enum font_fmt
{
    NORMAL = 0b0,
    BOLD = 0b1,
    UNDERLINE = 0b100,
    STRIKETHRU = 0b1000
} FONT_FMT;

typedef struct cursor
{
    Point c_pos;
    Point exact_pos;
} CURSOR;

#define P(x, y) ((Point) {x, y})
#define C(r, g, b) ((Color) {r, g, b})

#define XY2LFBPtr(x, y) (BYTE*) FBI.Base + (y * FBI.Pitch) + (x * FBI.PxWidth)
#define EncodeColorPx(Red, Green, Blue) \
        (((Pixel)0) | \
        ((Red) << FBI.RedLSBOffset) | \
        ((Green) << FBI.GreenLSBOffset) | \
        ((Blue) << FBI.BlueLSBOffset))

static inline Pixel __C_PixelData(uint8_t Red, uint8_t Green, uint8_t Blue)
{
    Pixel Px = (Pixel) 0;
    Px |= (Red << FBI.RedLSBOffset) |
          (Green << FBI.GreenLSBOffset) | 
          (Blue << FBI.BlueLSBOffset);
    
    return Px;
}

static inline int __PutPixel(uint16_t x, uint16_t y, Pixel PixelData)
{
    VerifyBoundsPx(x, y, 1);
    
    BYTE* Location = XY2LFBPtr(x, y);
    
    Location[0] = (BYTE) (PixelData & 0xff);
    Location[1] = (BYTE) ((PixelData >> BITS_PER_COLOR) & 0xff);
    Location[2] = (BYTE) ((PixelData >> (2 * BITS_PER_COLOR)) & 0xff);
    #if !BPP24
        Location[3] = (BYTE) ((PixelData >> (3 * BITS_PER_COLOR)) & 0xff);
    #endif

    return 0;
}

static inline int PutPixel(Point Point, Color Color)
{
    //Pixel Pxd = __C_PixelData(Color.Red, Color.Green, Color.Blue);
    Pixel Pxd = EncodeColorPx(Color.Red, Color.Green, Color.Blue);
    return __PutPixel(Point.x, Point.y, Pxd);
}

int PutRect(Point TopL, Point BotR, PolyDrawMode DrawMode, Color FillColor, LineFormat OutlineFmt);

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