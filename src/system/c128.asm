!zone c128

; zero page addresses. we use $0a-$8f ($7a and up is used by vdc-basic)
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

detectC128
    rts

initC128
    rts


mmuBankConfig       !byte $3F,$7F,$BF,$FF,$16,$56,$96,$D6,$2A,$6A,$AA,$EA,$06,$0A,$01,$00
