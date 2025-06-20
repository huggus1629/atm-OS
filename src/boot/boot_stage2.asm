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
MEM_MODEL   equ 6       ; 6 = direct color
; ==============================
; Import global symbols
    extern  hang            ; hang
    extern  puts            ; puts function
    extern  diskread        ; diskread function
    extern  err_diskread    ; disk error handler
    extern  v_drivenumber_b ; drive number
; ==============================

section     .stage2

    bits    16

stage2_entry:
    jmp near    stage2_main

; =========================
; Variables
mode_found:         db  1   ; CLEAR=found, SET=not found
vbe_version:        dw  0   ; high byte = maj ver no. , low byte = min ver no.
s_reached:          db  "Reached Stage 2",13,10,0
s_loading_kernel:   db  "Loading Kernel to 0x8000",13,10,0
s_vbe_supported:    db  "VBE 2.0+ supported",13,10,0
s_checking_mode:    db  "Checking mode...",13,10,0
s_mode_found:       db  "Mode found!",13,10,0
; =========================
    ; ------------------------------
    ; GDT setup (flat 32-bit model)
    ; ------------------------------

    gdt_start:
    gdt_null:
    ; Null descriptor (required, not used)
        dw 0x0000              ; Limit 0:15
        dw 0x0000              ; Base 0:15
        db 0x00                ; Base 16:23
        db 0x00                ; Access byte
        db 0x00                ; Limit 16:19 (4 bits), Flags (4 bits)
        db 0x00                ; Base 24:31
    gdt_code:
    ; Code segment descriptor (base=0, limit=4GB, 0x9A = code, readable, accessed=0, ring 0, present)
        dw 0xFFFF              ; Limit 0:15 (0xFFFF)
        dw 0x0000              ; Base 0:15 (0x0000)
        db 0x00                ; Base 16:23 (0x00)
        db 10011010b           ; Access: 1=present, 00=DPL0, 1=code, 1=executable, 0=not conforming, 1=readable, 0=accessed
        db 11001111b           ; Flags: 1100=limit 16:19=0xF, 1=32bit, 1=granularity 4K, 00=reserved
        db 0x00                ; Base 24:31 (0x00)
    gdt_data:
    ; Data segment descriptor (base=0, limit=4GB, 0x92 = data, writable, accessed=0, ring 0, present)
        dw 0xFFFF              ; Limit 0:15 (0xFFFF)
        dw 0x0000              ; Base 0:15 (0x0000)
        db 0x00                ; Base 16:23 (0x00)
        db 10010010b           ; Access: 1=present, 00=DPL0, 1=data, 0=not executable, 0=expand-up, 1=writable, 0=accessed
        db 11001111b           ; Flags: 1100=limit 16:19=0xF, 1=32bit, 1=granularity 4K, 00=reserved
        db 0x00                ; Base 24:31 (0x00)

    gdt_end:

    ; GDT descriptor (for lgdt)
    gdt_descriptor:
        dw gdt_end - gdt_start - 1    ; Size (limit = size-1)
        dd gdt_start                  ; Linear address of GDT

    CODE_SEG    equ gdt_code - gdt_start
    DATA_SEG    equ gdt_data - gdt_start
    ; End GDT setup
    ; ------------------------------

stage2_main:
    mov     si, s_reached
    call    puts

    ; Load Kernel
    ; --------------
    mov     si, s_loading_kernel    ; print loading kernel msg
    call    puts

    xor     ax, ax
    ; set diskread parameters
    mov     si, 3   ; kernel at LBA 3 onwards
    mov     al, 0xf ; for now just read 0xf sectors
    mov     dl, [v_drivenumber_b]
    mov     bx, KERNEL_PTR
    call    diskread
    jc      err_diskread
    ; done loading kernel
    ; ------------------------

    push    es  ; save segment (modified by VBE)
    ; get & set VBE graphics mode
    ; ----------------------------
    ; load vbe info structure to 0x7a00 (1 "sector" before 0x7c00)
    mov     si, 1
    mov     al, 1
    mov     bx, VBE_INFBUF_PTR
    call    diskread    ; (dl still set)
    jc      err_diskread

.after_vbebufread:
    ; get VBE info
    mov     ax, 0x4f00
    mov     di, VBE_INFBUF_PTR
    int     0x10
    ; pointer to array is stored at vbe_info_struct + 14

    cmp     ax, 0x004f                      ; check return code
    jne     .check_done
    cmp     dword [VBE_INFBUF_PTR], "VESA" ; check signature
    jne     .check_done

    mov     ax, word [VBE_INFBUF_PTR + 4]   ; get VBE version
    cmp     ah, 2
    mov     word [vbe_version], ax

    jb      .check_done     ; abort if vbe version < 2.0

    ; print "VBE 2.0+ supported" message
    mov     si, s_vbe_supported
    call    puts

    mov     bx, word [VBE_INFBUF_PTR + 14]  ; load mode list offset into bx
    mov     es, word [VBE_INFBUF_PTR + 16]  ; load mode list segment into es

    xor     si, si
.check_mode_loop:
    mov     ax, 0x4f01          ; get mode info fn
    mov     cx, word [es:bx + si]  ; mode number stored @ bx+si
    cmp     cx, 0xffff          ; check if end of list reached
    je      .check_done
    mov     di, VBE_MODE_INFBUF_PTR ; 0x7900 (256 byte buffer)
    pusha
    int     0x10
    cmp     ax, 0x004f          ; check return code
    popa
    jne     .check_done

    ; print "Checking mode..." for each mode
    push    si
    mov     si, s_checking_mode
    call    puts
    pop     si

    ; compare stats
    ; 1. supported by hardware? = word +0 & 1 == 1
    ; 2. lin. framebuf.? = (word +0 >> 7) & 1 == 1
    ; 3. width = word [+18]
    ; 4. height = word [+20]
    ; 5. bpp = word [+25]

    ; Check if supported & linear framebuffer is available
    mov     ax, word [VBE_MODE_INFBUF_PTR]  ; AX:   ????????|#??????#
    and     al, 0x81                        ; AX:   00000000|#000000#
    cmp     al, 0x81
    jne     .chk_next_mode                  ; if no lfb or not supported -> skip

    ; Check if width correct
    mov     ax, word [VBE_MODE_INFBUF_PTR + 18]
    cmp     ax, WIDTH
    jne     .chk_next_mode

    ; Check if height correct
    mov     ax, word [VBE_MODE_INFBUF_PTR + 20]
    cmp     ax, HEIGHT
    jne     .chk_next_mode

    ; Check if bpp correct
    mov     al, byte [VBE_MODE_INFBUF_PTR + 25]
    cmp     al, BPP
    jne     .chk_next_mode
    
    ; Check if memory model = 6 (direct color)
    mov     al, byte [VBE_MODE_INFBUF_PTR + 27]
    cmp     al, 6
    jne     .chk_next_mode
    
    ; all values good -> mode found!
    mov     byte [mode_found], 0

    push    si
    mov     si, s_mode_found
    call    puts
    pop     si

    jmp     .check_done

.chk_next_mode:
    add     si, 2
    jmp     .check_mode_loop

.check_done:
    cmp     byte [mode_found], 0
    jne     .after_vbe

    ; set found mode
    mov     ax, 0x4f02
    mov     bx, word [es:bx + si]
    or      bx, 0x4000          ; 0x4000 = 01000000 00000000b (sets LFB bit 14)
    and     bx, 0x7fff          ; 0x7fff = 01111111 11111111b (clears bit 15 [clear screen])
    pusha
    int     0x10
    cmp     ax, 0x004f
    popa
    pop     es  ; restore original es
    jne     .mode_set_err
    jmp     .after_vbe

.mode_set_err:
    mov     byte [mode_found], 1

.after_vbe:
    ; load GDT and switch to protected mode
    ; !! no BIOS interrupts in PM !!
    cli
    lgdt    [gdt_descriptor]
    mov     eax, cr0
    or      eax, 1
    mov     cr0, eax
    jmp     CODE_SEG:pm_start

    ; now in 32 bit mode
    bits    32
pm_start:
    ; reinit segments
    mov     ax, DATA_SEG
    mov     ds, ax
    mov     ss, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    
    jmp     KERNEL_PTR

times   512-($-$$)  db  0x90