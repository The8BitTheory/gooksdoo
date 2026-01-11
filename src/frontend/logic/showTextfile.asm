!zone showTextfile

; stream a textfile from disk (or possibly any other source)
; lines can be 80 chars max.
; lineTable has an entry with start-address and length of each line
; for disk-streaming, each line starts at the following:
; - devicenr (eg 8)
; - track
; - sector
; - offset inside block
; that's 4 bytes for the pointer
; plus 1 more byte for length

showTextfile
    lda #$00
    sta diskLoadAddress
    sta zp_directoryAddress
    lda #$04
    sta diskLoadAddress+1
    sta zp_directoryAddress+1
    lda #$01
    sta diskLoadDataBank
    sta zp_directoryBank

    jsr loadSectorList


    rts
    