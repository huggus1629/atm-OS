#include "stdio.h"

#include "vbe.h"
#include "stddef.h"

Pixel NewPixel(uint8_t red, uint8_t green, uint8_t blue)
{
    Pixel px = 0;
    px |= (red << FBI.RedLSBOffset) |
          (green << FBI.GreenLSBOffset) | 
          (blue << FBI.BlueLSBOffset);
    
    return px;
}

int PutPixel(uint16_t x, uint16_t y, Pixel px)
{
    if (x >= SCREEN_W || y >= SCREEN_H)
        return 1;
    
    Pixel* location = (Pixel*) ((BYTE*) FBI.Base + (y * FBI.Pitch) + (x * FBI.PxWidth));
    *location = px;

    return 0;
}