/*=================
vbe.h
------
Defines the VBE Mode Info struct
and related functions.
===================*/

#ifndef VBE_H
#define VBE_H

#include "stdint.h"

// VBE Mode Info Struct
// ======================
typedef struct __attribute__((packed))
{
    // General Mode Information
    // ------------------------
    uint16_t ModeAttributes;
    uint8_t _skip_unused0[14];
    uint16_t BytesPerScanLine;    // Use with VBE 2.0
    uint16_t XResolution;
    uint16_t YResolution;
    uint8_t _skip_unused1[3];
    uint8_t BitsPerPixel;
    uint8_t _skip_unused2[1];
    uint8_t MemoryModel;
    uint8_t _skip_unused3[3];

    // Direct Color Fields (use with VBE 2.0, NOT 3.0)
    // -------------------
    uint8_t RedMaskSize;          // Size of red mask in bits
    uint8_t RedFieldPosition;     // LSB position of red mask
    uint8_t GreenMaskSize;        // Size of green mask in bits
    uint8_t GreenFieldPosition;   // LSB position of green mask
    uint8_t BlueMaskSize;         // Size of blue mask in bits
    uint8_t BlueFieldPosition;    // LSB position of blue mask
    uint8_t RsvdMaskSize;         // Size of reserved mask in bits
    uint8_t RsvdFieldPosition;    // LSB position of reserved mask
    uint8_t _skip_unused4[1];     // Direct color mode attributes

    // VBE 2.0+ fields
    // ---------------
    uint32_t PhysBasePtr;         // Physical address of linear frame buffer
    uint8_t _skip_unused5[6];

    // VBE 3.0+ fields (use with VBE 3.0)
    // ---------------
    uint16_t LinBytesPerScanLine;     // Bytes per scanline in linear modes
    uint8_t _skip_unused6[1];
    uint8_t LinNumberOfImagePages;    // Number of images for linear modes (maybe not used)
    uint8_t LinRedMaskSize;           // Red mask size (linear modes)
    uint8_t LinRedFieldPosition;      // Red field position (linear modes)
    uint8_t LinGreenMaskSize;         // Green mask size (linear modes)
    uint8_t LinGreenFieldPosition;    // Green field position (linear modes)
    uint8_t LinBlueMaskSize;          // Blue mask size (linear modes)
    uint8_t LinBlueFieldPosition;     // Blue field position (linear modes)
    uint8_t LinRsvdMaskSize;          // Reserved mask size (linear modes)
    uint8_t LinRsvdFieldPosition;     // Reserved field position (linear modes)
    uint32_t MaxPixelClock;           // Maximum pixel clock in Hz

    uint8_t _skip_unused7[190];
} VBE_ModeInfo;

// Struct to hold the LFB address and RGB field offsets,
// initialized by VBE_InitModeInfo().
typedef struct
{
    uint16_t DisplayWidth;
    uint16_t DisplayHeight;
    uint8_t BPP;
    uint32_t* Base;
    uint16_t Pitch;  // Bytes per scanline
    uint16_t PxWidth;
    uint8_t RedLSBOffset;
    uint8_t GreenLSBOffset;
    uint8_t BlueLSBOffset;
    uint8_t RsvdLSBOffset;
} LFB_Info;

// Macros
// =======

#define BITS_PER_COLOR 8
#define FBI FrameBufferInfo

// Globals
// ========

extern LFB_Info FrameBufferInfo;

// ================================================

// Function declarations
// ======================

// Saves various mode info to a global struct
// (for use by other graphics functions).
int VBE_InitGraphics(void);

#endif // VBE_H