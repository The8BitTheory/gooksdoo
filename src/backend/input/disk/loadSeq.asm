!zone loadSeq

loadSeqFileViaSectors
    lda #0
    sta lastDisplayedLine
    sta lastDisplayedLine+1

    jsr initPlainTextSectorParser ; initializes all variables and pointers
    jsr initLineBuffer

    ; get the first/next sector of the file
.nextSector
    jsr doReadSector        ; writes 256 bytes to sectorData. parseSector will read from this

; parse it and keep parsing until we have lineTable entries for the first 25 (or 23) lines on screen
    jsr parseSector         ; parses as many lines as the sector contains. might end with incomplete line (length $ff)
                            ; parsing writes lineTable entries and does line-breaks correctly (not splitting words)

; once the sector data (lineTable and buffer) for 25 lines is in memory, display 25 lines
;   displaying 25 lines requires re-visiting the sectors on disk.
;   sounds tedious, but being able to work with complete data (and not handle lines across sectors) is so much easier.
;   also: displaying 25 lines should require accessing 8 sectors max, usually only about 3-4.
    
    jsr sectorDataToBuffer
    
    inc bufferLinePointer
    lda parseLinePointer
    cmp bufferLinePointer
;    bpl -


    cmp parseLinePointer


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

calcZpLineTable
    clc
    adc #<lineTable
    sta zp_lineTable
    tya
    adc #>lineTable
    sta zp_lineTable+1
    rts

lastDisplayedLine   !word 0 ; helps comparing if we need to print more lines

parseLinePointer    !word 0 ; points to the line currently parsed
displayLinePointer  !word 0 ; points to the line currently displayed
bufferLinePointer   !word 0 
