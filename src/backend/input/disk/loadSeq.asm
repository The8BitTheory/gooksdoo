!zone loadSeq

; load 23 lines:
; - go to start sector. if not known, index sectors until it's found (eg when pressing page down)
; - load sector     -> puts 256 bytes into sectorData (is a temporary area)
; - index sector    -> read sectorData, write locations of line beginnings into lineTable
;                   -> breaks lines into 80 chars max, or shorter if CR/LF is found
; - sectorToBuffer  -> copies up to 2k to the buffer. less if EOF is reached
;                   -> crlf is not written, linelength is instead introduced (written here, read by display routine later)
;                   -> line beginnings and lengths are written to bufferTable
; - bufferToScreen  -> all required lines are copied to VRAM

loadSeqFileViaSectors
    jsr initPlainTextSectorParser ; initializes all variables and pointers
    jsr initBuffer
    lda #7
    sta .sectorsToRead

    ; get the first/next sector of the file
.nextSector
    jsr doReadSector        ; writes 256 bytes to sectorData. indexSector will read from this
                            ; we don't immediately write to lineBuffer, because of linebreaks introduced for lines longer 80

; parse it and keep parsing until we have lineTable entries for the first 25 (or 23) lines on screen
    jsr indexSectorWrapped  ; parsing writes lineTable entries and does line-breaks correctly (not splitting words)
    inc nrIndexedSectors

    jsr sectorDataToBuffer
    
    lda nextTrack
    beq +
    sta track
    lda nextSector
    sta sector
    
    dec .sectorsToRead
    bne .nextSector
    jmp +
    
+   jsr closeSectorAccess

    jsr indexBufferWrapped

    rts

calcZpLineTable
    clc
    adc #<lineTable
    sta zp_sectorLineTable
    tya
    adc #>lineTable
    sta zp_sectorLineTable+1
    rts

parseLinePointer    !word 0 ; points to the line currently parsed
displayLinePointer  !word 0 ; points to the line currently displayed

nrIndexedSectors    !byte 0 

.sectorsToRead      !byte 0 