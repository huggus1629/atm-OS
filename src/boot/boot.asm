    bits    16
    org     0x7c00

KERNEL_LOCATION equ 0x8000

WIDTH           equ 640     ; 8x16 font -> 80x30 character display
HEIGHT          equ 480
BPP             equ 32

;
; FAT12 Header
; ===================
entry:
    jmp short tmp
    nop

; BIOS Parameter Block
; ----------------------
bpb_oem_ident:              db  'MSWIN4.1'      ; 8 bytes
bpb_bytes_per_sector:       dw  512
bpb_sectors_per_cluster:    db  1
bpb_reserved_sectors:       dw  1
bpb_fat_count:              db  2
bpb_root_dir_entries_count: dw  0xe0
bpb_total_sectors:          dw  2880
bpb_media_descriptor_type:  db  0xf0
bpb_sectors_per_fat:        dw  9
bpb_sectors_per_track:      dw  18
bpb_heads:                  dw  2
bpb_hidden_sectors:         dd  0
bpb_large_sector_count:     dd  0               ; not used

; Extended Boot Record
; ---------------------
ebr_drive_number:           db  0
ebr_reserved:               db  0
ebr_signature:              db  0x28
ebr_serial_number:          dd  0
ebr_volume_label:           db  'atmOS      '   ; 11 bytes (padded w/ spaces)
ebr_system_ident:           db  'FAT12   '      ; 8 bytes

tmp:
    jmp     setup


; GDT
; ====
gdt_start:
gdt_null:       ; the mandatory null descriptor
    dd      0x0     ; ’ dd ’ means define double word ( i.e. 4 bytes )
    dd      0x0
gdt_code:       ; the code segment descriptor
                ; base =0 x0 , limit =0 xfffff ,
                ; 1 st flags : ( present )1 ( privilege )00 ( descriptor type )1 -> 1001 b
                ; type flags : ( code )1 ( conforming )0 ( readable )1 ( accessed )0 -> 1010 b
                ; 2 nd flags : ( granularity )1 (32 - bit default )1 (64 - bit seg )0 ( AVL )0 -> 1100 b
    dw      0x0fff      ; Limit ( bits 0 -15)
    dw      0x0         ; Base ( bits 0 -15)
    db      0x0         ; Base ( bits 16 -23)
    db      0b10011010  ; 1 st flags , type flags
    db      0b11000000  ; 2 nd flags , Limit ( bits 16 -19)
    db      0x0         ; Base ( bits 24 -31)
gdt_data:       ; the data segment descriptor
                ; Same as code segment except for the type flags :
                ; type flags : ( code )0 ( expand down )0 ( writable )1 ( accessed )0 -> 0010 b
    dw      0x0fff       ; Limit ( bits 0 -15)
    dw      0x0          ; Base ( bits 0 -15)
    db      0x0          ; Base ( bits 16 -23)
    db      0b10010010   ; 1 st flags , type flags
    db      0b11000000   ; 2 nd flags , Limit ( bits 16 -19)
    db      0x0          ; Base ( bits 24 -31)
gdt_end:

gdt_descriptor:
    dw      gdt_end - gdt_start - 1
    dd      gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start


; Disk Read Function
; --------------------
; for params see interrupt table
disk_read:
    push    ax
    push    bx
    push    cx
    push    dx
    push    si

    mov     si, 4   ; 3 + 1
.disk_retry:
    dec     si
    jz      .disk_cont
    mov     ah, 0x02
    stc
    pusha
    int     0x13
    popa
    jc      .disk_retry
    jmp     .disk_cont
.disk_cont:
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    jz      end         ; TODO maybe error handler for disk errors
    ret


; Boot Code
; ==========

setup:
    xor     ax, ax
    mov     ss, ax
    mov     ds, ax
    mov     es, ax

    mov     bp, 0x7c00
    mov     sp, bp

main:
    mov     al, 0x03    ; 0x03 : 80x25 text mode 16 colors 
    int     0x10        ; clear screen
    

    ; get vbe info structure
    mov     al, 1
    mov     bx, vbe_info_struct
    mov     cx, 2
    call    disk_read
    
    mov     ax, 0x4f00
    mov     di, vbe_info_struct
    int     0x10
    ; pointer to array is stored at vbe_info_struct + 14

    cmp     ax, 0x004f                      ; check return code
    jne     check_done
    cmp     dword [vbe_info_struct], "VESA" ; check signature
    jne     check_done
    
    mov     bx, word [vbe_info_struct + 14] ; load pointer into ax

    xor     si, si
check_mode_loop:
    mov     ax, 0x4f01
    mov     cx, word [bx + si]
    cmp     cx, 0xffff
    je      check_done
    mov     di, 0x1000
    pusha
    int     0x10
    cmp     ax, 0x004f
    popa
    jne     check_done

    ; compare stats
    ; 1. lin. framebuf.? = (word [0x1000] >> 7) & 1
    ; 2. width = word [0x1000 + 18]
    ; 3. height = word [0x1000 + 20]
    ; 4. bpp = word [0x1000 + 25]

    ; Check if linear framebuffer is available
    mov     ax, word [0x1000]   ; AX:   ????????|#???????
    shr     ax, 7               ; AX:   -------?|???????#
    and     ax, 1               ; AX:   00000000|0000000#
    jz      .chk_next_mode      ; if ax == 0 mode has no lin. framebuf.

    ; Check if width correct
    mov     ax, word [0x1000 + 18]
    cmp     ax, WIDTH
    jne     .chk_next_mode

    ; Check if height correct
    mov     ax, word [0x1000 + 20]
    cmp     ax, HEIGHT
    jne     .chk_next_mode

    ; Check if bpp correct
    mov     al, byte [0x1000 + 25]
    cmp     al, BPP
    jne     .chk_next_mode
    
    ; mode found!
    mov     byte [mode_found], 0
    push    ax
    push    bx
    mov     ax, word [0x1000 + 40]
    mov     bx, word [0x1000 + 42]
    mov     [framebuf], ax
    mov     [framebuf + 2], bx
    pop     bx
    pop     ax
    jmp     check_done

.chk_next_mode:
    add     si, 2
    jmp     check_mode_loop

check_done:
    cmp     byte [mode_found], 0
    jne     load_kernel

    ; set found mode
    mov     ax, 0x4f02
    mov     bx, word [bx + si]
    or      bx, 0x4000          ; 0x4000 = 01000000 00000000b (sets LFB bit 14)
    and     bx, 0x7fff          ; 0x7fff = 01111111 11111111b (clears bit 15 [clear screen])
    pusha
    int     0x10
    cmp     ax, 0x004f
    popa
    jne     mode_set_err
    jmp     load_kernel

mode_set_err:
    mov     byte [mode_found], 1

load_kernel:
    mov     al, 0x0f
    mov     bx, KERNEL_LOCATION
    mov     cx, 3       ; kernel is in LBA 2 (CHS 0,0,3) and onwards
    call    disk_read   ; read kernel to 0x8000


    cli
    lgdt    [gdt_descriptor]
    mov     eax, cr0
    or      eax, 1
    mov     cr0, eax
    jmp     CODE_SEG:pm_start

    bits    32
pm_start:
    ; reinit segments
    mov     ax, DATA_SEG
    mov     ds, ax
    mov     ss, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    
    jmp     KERNEL_LOCATION
    ;jmp     end



end:
    jmp     $


times 512-2-1-4-($-$$) db 0x90
framebuf:   dd  0       ; 0x7df9, 32bit ptr to framebuf
mode_found: db  1       ; 0x7dfd, CLEAR if mode found, SET if not (SET by default)
dw 0xaa55

vbe_info_struct:
    .signature:     db      "VBE2"
    .vbe_data:      resb    512-4