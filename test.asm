ram_seg     equ 80h
rom_seg     equ 00h
high_rom    equ 40h
seg_switch  equ 0020h

fda_seg     equ 0C2h
fda_sec     equ 0003h
fda_byte    equ 0005h

reset:
    mov e, fda_seg
    lea hi, 1
    call offs8 fda_read
    store ebc, hi

hang:
    jmp offs8 hang

; hi=sector read
fda_read:
    call offs8 lba_gpos
    lea jk, 0   ; byte 0
.loop1:
    lea fg, 512
    cmpw fg, jk
    jn offs8 .end
    mov a, 1
    addw jk, a
    jmp offs8 .loop1
.end:
    ret

lba_gpos:
    lea jk, 512 ; sector size
    mul hi, jk  ; multiply
    ret

    reserve (0FFF0h-$)
    mov     d, high_rom
    lea     bc, seg_switch
    mov     a, rom_seg
    store   dbc, a
    jmp     reset
    reserve (10000h-$)