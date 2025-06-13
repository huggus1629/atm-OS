; ==============================
; Preprocessor macro definitions
; (if any)
; ==============================

    bits    16
    org     0x7c00

; ---------------------
; More macros
KERNEL_PTR  equ 0x8000

WIDTH       equ 1024     ; 8x16 font -> 128x48 character display
HEIGHT      equ 768
BPP         equ 24
; ---------------------

start:
    jmp     stage_1

; ========================
; Include functions
%include "puts.inc.asm"
%include "a20test.inc.asm"
%include "diskread.inc.asm"
; ------------------------
; Allocate variables (v_ = variable prefix, _b _w _d = byte/word/dword suffix)
v_drivenumber_b:    db  0
v_is_hdd_b:         db  0

; Values for LBA->CHS (floppy defaults)
v_sec_p_trk_b:      db  18
v_head_p_cyl_b:     db  2

; String constants
s_err_diskparams:   db  "Disk params loading error.",13,10,0
s_err_diskerr:      db  "Disk error.",13,10,0
s_a20test:  db  "Testing A20 Line...",13,10,0
s_a20good:  db  "A20 Line enabled.",13,10,0
s_a20bad:   db  "A20 Line disabled. Enabling...",13,10,0
; ========================

stage_1:
    xor     ax, ax
    mov     ss, ax
    mov     ds, ax
    mov     es, ax

    mov     bp, 0x7c00
    mov     sp, bp

    push    dx
    mov     al, 0x03    ; 0x03 : 80x25 text mode 16 colors 
    int     0x10        ; clear screen

    mov     ah, 0x02    ; set starting cursor pos
    xor     dx, dx
    int     0x10
    pop     dx      ; restore dx because it contains the drive number

    ; save drive number
    mov     [v_drivenumber_b], dl
    push    dx          ; save dl for BIOS
    and     dl, 0x80    ; if drive=hdd ? zero flag cleared, else (if floppy): zero flag set
    pop     dx          ; restore dl
    jz      .drive_is_floppy
    mov     byte [v_is_hdd_b], 1    ; is_hdd = true
    
    ; get drive parameters if hdd (int 0x13, ah=0x08)
    pusha
    xor     di, di  ; guard against potential BIOS bug
    mov     ah, 0x08
    int     0x10    ; dl is already set
    jc      err_diskparams  ; CF set on error
    and     cl, 0x3f    ; low 6 bits = sectors per track (0x3f = 0b00111111)
    mov     [v_sec_p_trk_b], cl     ; save SPT
    mov     [v_head_p_cyl_b], dh    ; save HPC
    popa

.drive_is_floppy:
    mov     si, s_a20test
    call    puts

    ;;;; testing only
    ;mov     ax, 0x2400
    ;int     0x15

    call    a20test ; test A20 line (CF set if disabled)
    jnc     .a20enabled ; if A20 enabled, jump there
    mov     si, s_a20bad
    call    puts
    ; add code to enable A20
    jmp     hang

.a20enabled:
    mov     si, s_a20good
    call    puts

; TODO
; enable a20 line
; query vbe (see memory layout), save mode info for later use by kernel
; ↑↑↑ maybe do this in stage 2 in case we run out of space (512 bytes)
; load stage 2, jmp

hang:
    cli
    hlt

err_diskparams:
    mov     si, s_err_diskparams
    call    puts
    jmp     hang

err_diskread:
    mov     si, s_err_diskerr
    call    puts
    jmp     hang

times   510-($-$$)  db  0x90
dw      0xaa55

%include "vbe_ctlinfobuf.inc.asm"
