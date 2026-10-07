ram_seg     equ 80h
rom_seg     equ 00h
high_rom    equ 40h
seg_switch  equ 0020h
video_seg   equ 0B8h

fda_seg     equ 0C2h
fda_sec     equ 0000h
fda_bytn    equ 0002h
fda_bio     equ 0004h

reset:
    mvw hi, 0
    mov d, ram_seg
    mvw fg, 0A000h
    jwl offs8 fda_read
    mvw fg, 0A000h
    mvw jk, 0
.print:
    lds dfg, a
    mov e, video_seg
    mvw bc, 0
    str ebc, a
    mov a, 1
    adw fg, a
    adw jk, a
    mvw hi, 512
    tsw hi, jk
    jiz offs8 .endpr
    jmp offs8 .print
.endpr:

hang:
    jmp offs8 hang

; hi=sector read
; fg=buffer
fda_read:
    mov e, fda_seg
    mvw bc, fda_sec
    str ebc, hi
    mvw jk, 0   ; byte 0
.loop1:
    mov e, fda_seg
    mvw bc, fda_bytn
    str ebc, jk
    mvw bc, fda_bio
    str ebc, a
    str dfg, a
    mvw hi, 512
    tsw hi, jk
    jiz offs8 .end
    mov a, 1
    adw jk, a
    adw fg, a  ; inc byte
    jmp offs8 .loop1
.end:
    ret

    reserve (0FFF0h-$)
    mov     d, high_rom
    mvw     bc, seg_switch
    mov     a, rom_seg
    str     dbc, a
    jmp     reset
    reserve (10000h-$)