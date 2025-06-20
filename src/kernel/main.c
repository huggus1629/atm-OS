#include "vbe.h"
#include "stdio.h"
#include "stddef.h"

unsigned char R(int x, int y) {
    // Red: XOR pattern for variety
    return (unsigned char)((x ^ y) & 0xFF);
}

unsigned char G(int x, int y) {
    // Green: horizontal gradient with wrap
    return (unsigned char)(x & 0xFF);
}

unsigned char B(int x, int y) {
    // Blue: vertical gradient with wrap
    return (unsigned char)(y & 0xFF);
}

void main(void)
{ 
    // Abort if initialization fails
    if(VBE_InitGraphics())
        return;
    
    for (size_t i = 0; i < SCREEN_H; i++)
    {
        for (size_t j = 0; j < SCREEN_W; j++)
        {
            //PutPixel(P(j, i), C(5*i*j/(i+j+1), j*j/(i+1), i*i/(j+1)));
            //PutPixel(P(j, i), C(j*j/(i+1), i*i/(j+1), j+i));
            PutPixel(P(j, i), C(R(j, i), G(j, i), B(j, i)));
            //PutPixel(P(j, i), C(255, 255, 255));

            // why is this so much faster
            //*((Pixel*) ((BYTE*) FBI.Base + (i * FBI.Pitch) + (j * FBI.PxWidth))) = __C_PixelData(5*i*j/(i+j+1), j*j/(i+1), i*i/(j+1));
            
            //PutPixelM(P(j, i), C(5*i*j/(i+j+1), j*j/(i+1), i*i/(j+1)));
            //PutPixelM(P(j, i), C(255, 255, 255));
        }
    }

    return;
}
