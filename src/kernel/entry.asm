    bits    32
    extern  main

kernel_entry:
    mov     ebp, 0x110000
    mov     esp, ebp
    call    main
    jmp     $