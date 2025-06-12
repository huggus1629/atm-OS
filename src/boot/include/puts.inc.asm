; Print string Function
; ---------------------
; [in] si: pointer to first char

puts:
    push    ax
    push    bx
    push    si

.puts_loop:
    lodsb               ; load byte from [si] into al, increment si
    test    al, al      ; check for null terminator
    jz      .puts_done
    mov     ah, 0x0e    ; teletype output
    mov     bh, 0       ; Page number
    int     0x10
    jmp     .puts_loop

.puts_done:
    pop     si
    pop     bx
    pop     ax
    ret
; --------------------
