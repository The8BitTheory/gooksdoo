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
    sta diskLoadFilenameBank
    sta zp_directoryAddress
    lda #$04
    sta diskLoadAddress+1
    sta zp_directoryAddress+1
    lda #$01
    sta diskLoadDataBank
    sta zp_directoryBank

    lda #9
    sta diskLoadDeviceNr

    jsr loadSectorList
    jsr drawHeaderLine
    jsr displayBuffer
    jsr drawStatusBar

.readKeyboardInput
    jsr setBank15
-   jsr k_getin
    beq -
    jsr disableBasicRom

    cmp #17     ;cursor down
    bne +
    jmp .scrollDown

+   cmp #145 ; cursor up
    bne +
    jmp .scrollUp

+   cmp #'X'
    bne .readKeyboardInput
    rts

.scrollUp
    ; if we're on first line, no scrolling
    lda firstDisplayedLine+1
    bne +
    lda firstDisplayedLine
    bne +
    jmp .readKeyboardInput

+   ; todo: check, if buffer contains previous line before scrolling
    jsr moveLinesDown

    sec
    lda firstDisplayedLine
    sbc #1
    sta firstDisplayedLine
    bcs +
    dec firstDisplayedLine+1

+   sec
    lda lastDisplayedLine
    sbc #1
    sta lastDisplayedLine
    bcs +
    dec lastDisplayedLine+1

+   jsr copyFirstFromBufferToScreen

    jmp .scrollingDone

.scrollDown
    ; check if we can scroll down
    
    ; - if yes: copy line from buffer to last line
    ; - if no: check if we can pull in more lines from sectors
    ;           - if yes: copy next sector into buffer

    ; check if more buffered lines are available
    lda lastBufferedLine+1
    cmp lastDisplayedLine+1
    bcc +
    lda lastBufferedLine
    cmp lastDisplayedLine
    bne +
    ; no more lines in buffer. check if we can pull in more lines from sectors
    jsr .readNextSectorIntoBuffer
    bcc +
    jmp .readKeyboardInput

+   jsr moveLinesUp

    inc firstDisplayedLine
    bne +
    inc firstDisplayedLine+1

+   inc lastDisplayedLine
    bne +
    inc lastDisplayedLine+1
    
+   jsr copyLastFromBufferToScreen

.scrollingDone
    jsr drawStatusBar
    jmp .readKeyboardInput

.readNextSectorIntoBuffer
    lda nextTrack
    beq .noNextSector
    sta track
    lda nextSector
    sta sector

    jsr openCommandAndAccessChannel
    jsr doReadSector
    jsr closeSectorAccess

    jsr indexSectorWrapped  ; parsing writes lineTable entries and does line-breaks correctly (not splitting words)
    inc nrIndexedSectors
    
    jsr sectorDataToBuffer
    clc
    rts

.noNextSector
    sec
    rts


;filename            !text "About This Serve",0
;filenameLength      !byte 16
diskLoadFilename !pet "beowulf",$a0,0