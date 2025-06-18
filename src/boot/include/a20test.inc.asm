bits    16
; Test if A20 line is enabled
; ---------------------------
; [out] CF set if disabled / clear if enabled

; Note:
; If A20 is disabled, memory access past 1MiB (0xf000:0xffff => 0xfffff)
; wraps around to 0x0. Magic number 0xaa55 is at 0x0000:0x7dfe.
; If ES=0xffff: 0xffff0 + offset = 0x100000 + 0x7dfe
; -> offset = 0x7e0e
; So if word [0xffff:0x7e0e] == word [0x0000:0x7dfe] => wraparound => A20 disabled => set CF

a20test:
    cli
    pusha
    push    es

    ; bx, si = 0
    xor     bx, bx
    mov     si, bx

.a20test_2ndcheck:
    push    bx  ; save bx=0 for later
    push    si  ; save si=0 (or 1 on 2nd check)

    mov     es, bx
    add     si, 0x7dfe  ; init es:si to 0000:7dfe (or +1 on 2nd check)
    mov     dx, word [es:si] ; dx = 0xaa55 (or 0x00aa on 2nd check)

    pop     si  ; restore si to current check iteration (0 or 1)
    pop     bx  ; restore bx=0
    push    bx  ; save bx=0 again
    push    si  ; save current iteration

    not     bx  ; bx=ffff
    mov     es, bx  ; es=ffff
    add     si, 0x7e0e
    mov     cx, [es:si]

    cmp     cx, dx  ; if cx == dx: wraparound -> set cf    
    clc
    pop     si  ; restore iteration
    pop     bx  ; restore bx=0
    jne     .a20test_done
    ; if cx == dx check if it wasn't a coincidence by reading 1 byte to the right
    test    si, si  ; if si == 0 check again
    pushf   ; save ZF for jump
    inc     si      ; si=1
    popf    ; restore ZF (overwrite ZF change by inc instruction)
    jz      .a20test_2ndcheck
    stc

.a20test_done:
    pop     es
    popa
    sti
    ret