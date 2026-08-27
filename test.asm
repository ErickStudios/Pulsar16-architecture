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
    lea hi, 0
    mov d, ram_seg
    lea fg, 0A000h
    call offs8 fda_read
    lea fg, 0A000h
    lea jk, 0
.print:
    load dfg, a
    mov e, video_seg
    lea bc, 0
    store ebc, a
    mov a, 1
    addw fg, a
    addw jk, a
    lea hi, 512
    cmpw hi, jk
    jz offs8 .endpr
    jmp offs8 .print
.endpr:

hang:
    jmp offs8 hang

; hi=sector read
; fg=buffer
fda_read:
    mov e, fda_seg
    lea bc, fda_sec
    store ebc, hi
    lea jk, 0   ; byte 0
.loop1:
    mov e, fda_seg
    lea bc, fda_bytn
    store ebc, jk
    lea bc, fda_bio
    load ebc, a
    store dfg, a
    lea hi, 512
    cmpw hi, jk
    jz offs8 .end
    mov a, 1
    addw jk, a
    addw fg, a  ; inc byte
    jmp offs8 .loop1
.end:
    ret

    reserve (0FFF0h-$)
    mov     d, high_rom
    lea     bc, seg_switch
    mov     a, rom_seg
    store   dbc, a
    jmp     reset
    reserve (10000h-$)