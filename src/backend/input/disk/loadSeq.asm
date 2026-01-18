!zone loadSeq

loadSeqFileViaSectors
    lda #0
    sta lastDisplayedLine
    sta lastDisplayedLine+1

    jsr initPlainTextSectorParser ; initializes all variables and pointers

    ; get the first/next sector of the file
.nextSector
    jsr doReadSector

; parse it and keep parsing until we have lineTable entries for the first 25 (or 23) lines on screen
    
    jsr parseSector         ; parses as many lines as the sector contains. might end with incomplete line
    
-   jsr displayLineFromCurrentSector        ; displays as many complete lines as have been parsed.
    
    inc lastDisplayedLine
    bne +
    inc lastDisplayedLine+1

+   lda latestParsedLine
    cmp lastDisplayedLine
    bne -
    
    lda linesToView
    beq +

    lda nextTrack
    beq +

    lda nextTrack
    sta track
    lda nextSector
    sta sector
    jmp .nextSector
    
+   jsr closeSectorAccess
    
    nop
    nop
    rts
    

lastDisplayedLine  !word 0 ; helps comparing if we need to print more lines
