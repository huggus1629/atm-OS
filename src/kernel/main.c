#include "vbe.h"
#include "stdio.h"

void main(void)
{ 
    // Abort if initialization fails
    if(VBE_InitGraphics())
        return;
    
    PutPixel(511, 383, NewPixel(255, 255, 255));
    PutPixel(512, 383, NewPixel(255, 255, 255));
    PutPixel(511, 384, NewPixel(255, 255, 255));
    PutPixel(512, 384, NewPixel(255, 255, 255));

    return;
}
