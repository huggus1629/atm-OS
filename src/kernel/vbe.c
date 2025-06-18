#include "vbe.h"

#include "tm_stdio.h"
#include "stddef.h"

#define VBE_MODE_FOUND_FLAG_PTR ((uint8_t*) 0x7e03)
#define VBE_VERSION_PTR ((uint16_t*) 0x7e04)
#define VBE_MODE_INFBUF_PTR ((VBE_ModeInfo*) 0x7900)

#define VMI_GetVersionDependent(member, ver_offset) *(&(VBE_MODE_INFBUF_PTR->member) + ver_offset)

// Allocate globals
// =================

LFB_Info FrameBufferInfo;

// Function implementations
// =========================

int VBE_InitGraphics(void)
{
    // Check if a mode has been found
    if (*VBE_MODE_FOUND_FLAG_PTR)
    {
        // Fall back to text mode
        TM_CURSOR c;
        tm_initcursor(&c);
        tm_c_puts("\n\n\n\nFatal Error: Unsupported graphics adapter!", 0x4f, &c);
        return 1;
    }

    VBE_ModeInfo* modeInfo = VBE_MODE_INFBUF_PTR;

    uint8_t MajVersion = (*VBE_VERSION_PTR >> 8) & 0xff;
    uint8_t Ver3Offset = MajVersion >= 3 ? (offsetof(VBE_ModeInfo, LinRedMaskSize)
                                          - offsetof(VBE_ModeInfo, RedMaskSize)) : 0;

    // Abort if for some reason the RGB channels are not 8 bits each
    if (VMI_GetVersionDependent(RedMaskSize, Ver3Offset) != BITS_PER_COLOR ||
        VMI_GetVersionDependent(GreenMaskSize, Ver3Offset) != BITS_PER_COLOR ||
        VMI_GetVersionDependent(BlueMaskSize, Ver3Offset) != BITS_PER_COLOR)
        return 1;

    FrameBufferInfo.DisplayWidth = (uint16_t) VBE_MODE_INFBUF_PTR->XResolution;
    FrameBufferInfo.DisplayHeight = (uint16_t) VBE_MODE_INFBUF_PTR->YResolution;
    FrameBufferInfo.Base = (uint32_t*) VBE_MODE_INFBUF_PTR->PhysBasePtr;
    FrameBufferInfo.Pitch = (uint16_t) (Ver3Offset ?
                                        VBE_MODE_INFBUF_PTR->LinBytesPerScanLine :
                                        VBE_MODE_INFBUF_PTR->BytesPerScanLine);
                                        // use "Lin" prefix if on VBE 3.0+
    FrameBufferInfo.PxWidth = VBE_MODE_INFBUF_PTR->BitsPerPixel / 8;
    
    FrameBufferInfo.RedLSBOffset = (uint8_t) VMI_GetVersionDependent(RedFieldPosition, Ver3Offset);
    FrameBufferInfo.GreenLSBOffset = (uint8_t) VMI_GetVersionDependent(GreenFieldPosition, Ver3Offset);
    FrameBufferInfo.BlueLSBOffset = (uint8_t) VMI_GetVersionDependent(BlueFieldPosition, Ver3Offset);
    FrameBufferInfo.RsvdLSBOffset = (uint8_t) VMI_GetVersionDependent(RsvdFieldPosition, Ver3Offset);

    return 0;
}