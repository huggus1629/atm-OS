; ===========================
; Stage 2 Bootloader
; LBA on Floppy: 2
; loaded from 0x7e00 - 0x7fff
; ==============================
; Macro definitions
%include "pointers.mac.asm"
WIDTH       equ 1024    ; 8x16 font -> 128x48 character display
HEIGHT      equ 768
BPP         equ 24
; ==============================

    bits    16
    org     0x7e00

stage2_entry:
    jmp     stage2_main

; ======================
; Variables
s_reached: db  "Reached Stage 2",13,10,0
; ======================

stage2_main:
    mov     ax, [STAGE1_FNS_BASEPTR + 2] ; puts function
    mov     si, s_reached
    call    ax

    jmp     [STAGE1_FNS_BASEPTR]     ; jump to hang

    ; TODO
    ; load kernel to 0x8000
    ; set up, load GDT
    ; get & set vbe mode
    ; enter protected mode
    ; jump to kernel

times   512-($-$$)  db  0x90