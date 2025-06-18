; ======================
; Enable the A20 Line
; 1. Try BIOS (ax=2401h) to enable
; 2. Try Keyboard Controller
; 3. Try Fast A20 (last resort)
; Wait in timeout loop after 2 and 3
; ======================
a20enable:
    pusha
    clc

    ; 1st test
    call    a20test
    jnc     .a20enable_done     ; if enabled, exits with cf cleared

    ; try BIOS
    mov     ax, 0x2401
    int     0x15        ; enables A20 if BIOS supports it
    
    ; ignore return value, just test A20
    call    a20test
    jnc     .a20enable_done

    ; try 8042
    call    a20enable_8042
    call    a20test_loop
    jnc     .a20enable_done     ; if cf clear, we're done

    ; try fast A20
    in      al, 0x92    ; read 0x92
    test    al, 2       ; see if it's already on
    jnz     .a20enable_done     ; if it is, we're done
    or      al, 2       ; if not, set the bit
    and     al, 0xfe    ; and with 11111110 to definitely clear reset bit
    out     0x92, al    ; write
    
    call    a20test_loop
    ; this will clear cf if a20 is on
    ; or set cf if a20 is off
    ; and return with that cf

.a20enable_done:
    popa
    ret


; Try 8042 (PS/2) Controller to enable A20
; ----------------------------------------
a20enable_8042:
    cli     ; don't want to be interrupted

    ; disable keyboard
    call    kbctrl_rdy_for_write
    mov     al, 0xad    ; command to disable ps/2 port
    out     0x64, al

    ; send command we want to read "controller output port"
    call    kbctrl_rdy_for_write
    mov     al, 0xd0
    out     0x64, al

    ; actually read it
    call    kbctrl_rdy_for_read     ; wait for byte in buffer
    in      al, 0x60    ; read from data port 0x60
    or      al, 2       ; set A20 enable bit
    push    ax          ; save for later
    
    ; send command we want to write to port
    call    kbctrl_rdy_for_write
    mov     al, 0xd1
    out     0x64, al

    ; actually write it
    call    kbctrl_rdy_for_write
    pop     ax          ; restore al to A20 enabled version
    out     0x60, al

    ; reenable keyboard
    call    kbctrl_rdy_for_write
    mov     al, 0xae
    out     0x64, al

    call    kbctrl_rdy_for_write    ; wait until command left the buffer

    sti
    ret

kbctrl_rdy_for_read:
    in      al, 0x64    ; read status register
    test    al, 1       ; bit 0 set -> buffer full -> ready to be read
    jz      kbctrl_rdy_for_read     ; read until bit 0 is set
    ret

kbctrl_rdy_for_write:
    in      al, 0x64    ; read status register
    test    al, 2       ; bit 1 clear -> buffer empty -> ready for write
    jnz     kbctrl_rdy_for_write    ; read until bit 1 is clear
    ret


; Test A20 Loop
; ---------------
; Tests if A20 is enabled 0xffff times
; ---------------
; [out] cf: clear if A20 enabled
;           set if timeout reached
a20test_loop:
    pusha
    xor     cx, cx
    not     cx      ; cx = 0xffff
.a20test_loop_start:
    call    a20test
    jnc     .a20test_loop_done
    loop    .a20test_loop_start
.a20test_loop_done:
    popa
    ret
    