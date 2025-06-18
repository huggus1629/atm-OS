STACK_TOP   equ 0x7900  ; -> exactly 29KiB of stack space (more than enough)

    bits    32
    extern  main

kernel_entry:
    mov     ebp, STACK_TOP
    mov     esp, ebp

    ; ======= Call to C main() function =======
    call    main
    ; ===== Return from C main() function =====

    ; Hang forever
    ;cli
    ;hlt
    jmp     $   ; jmp $ works better with Bochs
