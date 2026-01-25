!zone c128

; zero page addresses. we use $0a-$8f ($7a and up is used by vdc-basic)
k_getin = $eeeb

c_fetch = $02a2
c_fetch_zp = $02aa
c_stash = $02af
c_stash_zp = $02b9

zp_memPtr = $0a ; -$0b      ; generic memory pointer
zp_directoryAddress = $0c ; -$0d    the address where the directory is stored
zp_directoryBank = $0e  ; the bank where the directory is stored
zp_sectorLineTable = $0f ; -$10   the linetable address of the current line
zp_lineBufferPos   = $11   ; -$12  the linebuffer address of the current line
zp_indexPtr     = $13 ; -$14    used to read data from either sectorData or lineBuffer
zp_jumpTarget   = $15 ; -$16    

arg1 = $17 ; - $18
arg2 = $19 ; - $1a
arg3 = $1b ; - $1c

detectC128
    rts

initC128
    rts

disableBasicRom
    lda #%00001110
    sta $ff00
    rts

setBank15
    LDA #$00
    STA $FF00
    rts

; goes to 1 mhz
; if super-cpu is present, disable turbo
doSlow
    lda $ff00
    pha

    jsr setBank15
    LDA #$00
    STA $D030
    LDA $D011
    AND #$7F
    ORA #$10
    STA $D011

    lda $D0B9
    bmi +       ; top-most bit set, no super-cpu detected
    sta $d07a   ; set super-cpu turbo off (ie to 1 mhz from the c128's speed register we just set)

+   pla
    sta $ff00
    rts

; goes to 2 mhz
; if super-cpu is present, goes to 20 mhz
doFast
    lda $ff00
    pha

    jsr setBank15
    ;set fast flag
    LDA $D011
    AND #$6F
    STA $D011
    LDA #$01
    STA $D030

    lda $D0B9
    bmi +       ; top-most bit set, no super-cpu detected
    sta $d07b   ; turbo on. 20 mhz super-cpu speed

+   pla
    sta $ff00
    RTS

mmuBankConfig       !byte $3F,$7F,$BF,$FF,$16,$56,$96,$D6,$2A,$6A,$AA,$EA,$06,$0A,$01,$00
