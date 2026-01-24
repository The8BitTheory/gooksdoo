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
    lda #0
    sta lastDisplayedLine
    sta lastDisplayedLine+1

    jsr initPlainTextSectorParser ; initializes all variables and pointers
    jsr initBufferLineTable

    lda #7
    sta .sectorsToRead

    ; get the first/next sector of the file
.nextSector
    jsr doReadSector        ; writes 256 bytes to sectorData. indexSector will read from this
                            ; we don't immediately write to lineBuffer, because of linebreaks introduced for lines longer 80

; parse it and keep parsing until we have lineTable entries for the first 25 (or 23) lines on screen
    jsr indexSectorWrapped  ; parsing writes lineTable entries and does line-breaks correctly (not splitting words)

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

; once the sector data (lineTable and buffer) for 25 lines is in memory, display 25 lines
;   displaying 25 lines requires re-visiting the sectors on disk.
;   sounds tedious, but being able to work with complete data (and not handle lines across sectors) is so much easier.
;   also: displaying 25 lines should require accessing 8 sectors max, usually only about 3-4.
    
    nop
    nop
    rts

calcZpLineTable
    clc
    adc #<lineTable
    sta zp_sectorLineTable
    tya
    adc #>lineTable
    sta zp_sectorLineTable+1
    rts

lastDisplayedLine   !word 0 ; helps comparing if we need to print more lines

parseLinePointer    !word 0 ; points to the line currently parsed
displayLinePointer  !word 0 ; points to the line currently displayed

.sectorsToRead      !byte 0 