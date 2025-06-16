bits    16
; Read sectors from disk into memory
; ----------------------------------
; [in] si = LBA of first sector to read
; [in] al = how many sectors to read
; [in] dl = drive number
; [in] es:bx = destination buffer
; ----------------------
; [out] CF set on error
; if successful:
; [out] data in es:bx
; [out] ah = status (should be 0)
; [out] al = how many sectors read
diskread:
    push    bx
    push    cx
    push    dx
    push    si
    push    di

    call    reset_diskctl   ; reset disk system
    jc      .diskread_done

    call    lba_to_chs      ; converts LBA in si to CHS as expected by BIOS
    
    mov     di, 3
    mov     ah, 0x02        ; read function
.diskread_retry:
    push    ax              ; save ax in case we need to retry
    int     0x13
    
    jnc     .diskread_done  ; if CF clear, we're done
    ; if CF set, retry max. 3 times
    dec     di
    jz      .diskread_done  ; if di=0, all tries exhausted
    pop     ax              ; restore ax and retry
    jmp     .diskread_retry
.diskread_done:
    add     sp, 2   ; ignore saved ax, we now need ax returned by int 0x13
    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    ret

; Convert LBA to CHS
; ------------------
; [in] si: LBA
; -------------
; [out] ch: Cylinder [low 8 bits]
; [out] cl[5..0]: Sector
; [out] cl[7..6]: Cylinder [high 2 bits]
; [out] dh: Head
lba_to_chs:
    push    ax
    push    bx
    push    dx

    mov     al, byte [v_sec_p_trk_b]    
    mul     byte [v_head_p_cyl_b]       ; SPT(al) * HPC = SPC(ax) (word)
    mov     bx, ax  ; save SPC in bx

    ; calculate Cylinder#
    mov     ax, si  ; for division by a word, dividend must be dword (dx:ax)
    xor     dx, dx  ; => dx=0, ax=LBA
    div     bx      ; LBA(dx:ax) / SPC(bx) -> Cylinder# in ax, remainder in dx
    push    ax      ; ax=Cylinder# so save that for later

    ; calculate Head# and Sector#
    mov     ax, dx                  ; move remainder to ax
    div     byte [v_sec_p_trk_b]    ; remainder(ax) / SPT -> Head# in al, rem=Sector# - 1 in ah
    inc     ah  ; => al=Head#, ah=Sector#

    pop     cx      ; restore Cylinder#
                    ; => cx =   000000cc cccccccc
                    ; Cyl# low 8 bits need to be in ch
    push    ax      ; save Head#
    mov     al, cl
    mov     cl, ch  ; swap cl, ch
    mov     ch, al  ; => cx =   cccccccc 000000cc
    shl     cl, 6   ; shift high 2 bits left by 6 so Cylinder# done
    or      cl, ah  ; Sector# done
    pop     ax      ; restore Head# in al
    pop     dx      ; restore dl
    mov     dh, al  ; Head# done
    pop     bx
    pop     ax
    ret

; Reset all disk controllers
; --------------------------
; [in] dl: drive number or >=0x80 to reset all
; --------------------------
; [out] CF set on error
reset_diskctl:
    pusha
    xor     ax, ax  ; -> ah = 0
    int     0x13    ; reset
    popa
    ret
