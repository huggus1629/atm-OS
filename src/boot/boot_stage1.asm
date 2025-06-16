; ===========================
; Stage 1 Bootloader
; LBA on Floppy: 0
; loaded from 0x7c00 - 0x7dff
; ==============================
; Macro definitions
%include "pointers.mac.asm"
; ==============================

    bits    16
    org     0x7c00

stage1_entry:
    jmp near    stage1_main ; JMP rel16 = 3 bytes

; ========================
; Offset table (base = 0x7c03)
; for functions used in next stage
hang_ptr:       dw  hang        ; offset 0h
puts_ptr:       dw  puts        ; offset 2h
diskread_ptr:   dw  diskread    ; offset 4h
; ------------------
; Include functions
%include "puts.inc.asm"
%include "a20test.inc.asm"
%include "diskread.inc.asm"
%include "a20enable.inc.asm"
; ------------------------
; Allocate variables (v_ = variable prefix, _b _w _d = byte/word/dword suffix)
v_drivenumber_b:    db  0
v_is_hdd_b:         db  0

; Values for LBA->CHS (floppy defaults)
v_sec_p_trk_b:      db  18
v_head_p_cyl_b:     db  2

; String constants
s_err_diskparams:   db  "Disk geometry error",13,10,0
s_err_diskerr:      db  "Disk error",13,10,0
s_a20good:  db  "A20 enabled",13,10,0
s_a20bad:   db  "A20 disabled. Enabling",13,10,0
s_a20fail:  db  "A20 failure",13,10,0
; ========================

stage1_main:
    xor     ax, ax
    mov     ss, ax
    mov     ds, ax
    mov     es, ax

    mov     bp, 0x7c00
    mov     sp, bp

    ; TESTING: turn off floppy motor
;     push    ax
; .motor_off_loop:
;     in      al, 0x3f2   ; get digital output register (####----)
;     mov     ah, al      ; save reg in ah
;     and     al, 0xf0    ; get only motor bits (-> ZF clear if motor on)
;     jz      .motor_off_done
;     mov     al, ah      ; restore original register value
;     and     al, 0x0f    ; turn off 4 high bits
;     out     0x3f2, al   ; send motor off signal
;     jmp     .motor_off_loop
; .motor_off_done:
;     pop     ax          ; restore ax

    push    dx          ; save drive number just to be safe
    mov     al, 0x03    ; 0x03 : 80x25 text mode 16 colors 
    int     0x10        ; clear screen
    pop     dx          ; restore drive no.

    ; save drive number
    mov     [v_drivenumber_b], dl
    push    dx          ; save dl for BIOS
    and     dl, 0x80    ; if drive=hdd ? zero flag cleared, else (if floppy): zero flag set
    pop     dx          ; restore dl
    jz      .skip_geometry_check
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

.skip_geometry_check:
    call    a20test ; test A20 line (CF set if disabled)
    jnc     .a20enabled ; if A20 enabled, jump there
    
    mov     si, s_a20bad
    call    puts
    call    a20enable   ; cf set on error
    jc      err_a20

.a20enabled:
    mov     si, s_a20good
    call    puts    ; say a20 enabled

    mov     si, 2   ; LBA of Stage 2
    mov     al, 1   ; 1 sector
    mov     dl, byte [v_drivenumber_b]
    mov     bx, STAGE2_PTR
    call    diskread    ; read stage 2 bootloader to 0x7e00-0x7fff

    jc      err_diskread    ; cf set on error

    jmp     STAGE2_PTR  ; jump to stage 2

hang:
    cli
    hlt

err_diskparams:
    mov     si, s_err_diskparams
    jmp     puts_and_hang

err_diskread:
    mov     si, s_err_diskerr
    jmp     puts_and_hang

err_a20:
    mov     si, s_a20fail
    jmp     puts_and_hang

puts_and_hang:      ; to save space
    call    puts
    jmp     hang

times   510-($-$$)  db  0x90
dw      0xaa55

; ===========================
; VBE Controller Info Buffer
; LBA on Floppy: 1
; loaded from 0x7a00 - 0x7bff
; ==============================
%include "vbe_ctlinfobuf.inc.asm"
