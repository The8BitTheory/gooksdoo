!zone plainTextSectorParser

initPlainTextSectorParser
    lda #<lineTable
    sta zp_sectorLineTable
    lda #>lineTable
    sta zp_sectorLineTable+1

    lda #1
    sta nrIndexedSectorLines
    lda #0
    sta nrIndexedSectorLines+1
    sta nrIndexedSectors

    lda #23
    sta linesToView
    rts


; this indices the lines of the sector for 80 chars max per line.
indexSectorWrapped
    lda #<sectorData
    sta zp_indexPtr
    lda #>sectorData
    sta zp_indexPtr+1

    lda #<.storePointerInLineTable
    sta zp_jumpTarget
    lda #>.storePointerInLineTable
    sta zp_jumpTarget+1

    lda #0
    sta .leftToIndex+1
    sta .lineLength

    lda #$ff
    sta .indexLength

    lda nextTrack
    beq +       ; if zero: last sector of file. .nextSector contains nr of bytes in this sector
    ldx #$fe    ; not zero. sector contains 254 bytes
    jmp ++
+   ldx nextSector
    
++  stx .leftToIndex
    ldy #2
    sty .readIndex
-   jsr .parseLine
    ldy .leftToIndex
    beq +
    bne -

+   rts

readNextByte
    ldy .readIndex
    lda (zp_indexPtr),y ; was: sectorData,y
    tay
    inc .readIndex
    lda .readIndex
    cmp #254
    bne +
    inc zp_indexPtr+1
    lda #0
    sta .readIndex
+   sec
    lda .leftToIndex
    sbc #1
    sta .leftToIndex
    bcs +
    dec .leftToIndex+1
+   tya
    rts

readNextByteWithoutInc
    ldy .readIndex
    lda (zp_indexPtr),y ; was: sectorData,y
    rts

.storePointer
    jmp (zp_jumpTarget)

; each line takes 3 bytes in the lineTable. 2 bytes for pointer, 1 byte for line length
.parseLine
+   lda .lineLength
    bne .continueParseLine

    lda #0
    sta .charsSinceSpace

    jsr .storePointer               ; stores either sector or buffer linestart

.continueParseLine
-   jsr readNextByte
    cmp #' '            ; if this is a space character, we reset the counter
    bne +
    ldy #0
    sty .charsSinceSpace ; y should be zero because it was set in readNextByte
+   inc .charsSinceSpace
    
    ; we handle CR and CRLF
    cmp #$0d    ;line break?
    bne +
    jsr readNextByteWithoutInc      ; peek into the next char without increasing readIndex
    cmp #$0a                        ; other line break found?
    bne .finishLineWithBreak        ; no. handle linebreak at this position
    jsr readNextByte                ; yes. read with readIndex increment. ie just skip the LF
    jmp .finishLineWithBreak        ; and now handle the linebreak

+   inc .lineLength
    lda .lineLength
    cmp #79
    beq .finishLine

    lda .leftToIndex+1
    bne -
    lda .leftToIndex
    beq .doneParse

    jmp -

.finishLine
    ; when a line is running over, let's check if we're wrapping the word correctly
    ; if the following character is not a space character, it means we split a word
    jsr readNextByteWithoutInc
    cmp #' '    ; space
    bne +
    ; if space: wrap was luckily good. we can skip the space (would indent the next line otherwise)
    jsr readNextByte
    jmp .finishLineWithBreak

    ; if no space: find previous space and wrap to new line from there
    ; first, reduce line length so it only goes until last space
+   sec
    lda .lineLength
    sbc .charsSinceSpace
    sta .lineLength
    ; next, reset out read pointer to after the last space

    dec .charsSinceSpace
    sec
    lda .readIndex
    sbc .charsSinceSpace
    sta .readIndex

    clc
    lda .leftToIndex
    adc .charsSinceSpace
    sta .leftToIndex
    bcc .finishLineWithBreak
    inc .leftToIndex+1

.finishLineWithBreak
    lda .indexLength
    bmi +
    jsr .writeBufferEntryLength
    
+   lda #0
    sta .lineLength
    sta .charsSinceSpace

    lda .leftToIndex+1
    beq +
    jmp .parseLine
+   lda .leftToIndex
    beq .doneParse
    jmp .parseLine

.doneParse
    lda .indexLength
    bmi +

    dec bufferTablePosition

    ; if this was indexing the buffer, subtract 1 from the lastBufferedLine
    ; that eliminates potentially incomplete lines
    sec
    lda lastBufferedLine
    sbc #1
    sta lastBufferedLine
    bcs +
    dec lastBufferedLine+1

+   rts
    nop

.storePointerInLineTable
    ldy #0
    lda diskLoadDeviceNr
    sta (zp_sectorLineTable),y

    iny
    lda track
    sta (zp_sectorLineTable),y

    iny
    lda sector
    sta (zp_sectorLineTable),y

    iny
    lda .readIndex
    sta (zp_sectorLineTable),y
    
;incLineTable
    clc
    lda zp_sectorLineTable
    adc #lineTableIncr
    sta zp_sectorLineTable
    bcc +
    inc zp_sectorLineTable+1

+   inc nrIndexedSectorLines
    bne +
    inc nrIndexedSectorLines+1

+   rts

initBuffer
    lda #0
    sta firstBufferedLine
    sta firstBufferedLine+1
    sta lastBufferedLine
    sta lastBufferedLine+1
    sta bufferSectorToUse

    lda #<lineBuffer
    sta zp_lineBufferPos
    clc
    lda #>lineBuffer
    adc bufferSectorToUse
    sta zp_lineBufferPos+1

    rts

sectorDataToBuffer
    ;zp_lineBufferPos needs to be set accordingly
    lda #<lineBuffer
    sta zp_lineBufferPos
    clc
    lda #>lineBuffer
    adc bufferSectorToUse
    sta zp_lineBufferPos+1

    ldx #2
    ldy #0
-   lda sectorData,x
    sta (zp_lineBufferPos),y
    iny
    inx
    beq +
    bne -   ; as we read only 254 bytes, this is always true

+   lda #0
    sta (zp_lineBufferPos),y
    iny
    sta (zp_lineBufferPos),y
    dey
    
    clc
    tya
    adc zp_lineBufferPos
    sta zp_lineBufferPos
    bcc +
    inc zp_lineBufferPos+1

    ; 8 sectors can be buffered
+   inc bufferSectorToUse
    lda bufferSectorToUse
    cmp #8
    bne +
    lda #0
    sta bufferSectorToUse

+   rts

; this is called when all sectors are written to the buffer
; does the same what indexSectorWrapped did, but for the 2k buffer.
; in addition, it keeps the line lengths
indexBufferWrapped

    lda #<lineBuffer
    sta zp_indexPtr
    lda #>lineBuffer
    sta zp_indexPtr+1

    lda #<.writeBufferEntryPosition
    sta zp_jumpTarget
    lda #>.writeBufferEntryPosition
    sta zp_jumpTarget+1

    lda #<2048
    sta .leftToIndex
    lda #>2048
    sta .leftToIndex+1

    ldy #0
    sty .lineLength
    sty .indexLength
    sty .readIndex
    sty bufferTablePosition
    
-   jsr .parseLine
    ldy .leftToIndex+1
    bne -
    ldy .leftToIndex
    beq +
    bne -

+   rts


.writeBufferEntryPosition
    lda bufferTablePosition
    asl
    adc bufferTablePosition
    tay

    clc
    lda zp_indexPtr
    adc .readIndex
    sta bufferTable,y
    
    iny
    lda zp_indexPtr+1
    adc #0
    sta bufferTable,y

+   rts

.writeBufferEntryLength
    lda bufferTablePosition
    asl
    adc bufferTablePosition
    tay
    iny
    iny
    lda .lineLength
    sta bufferTable,y

    inc lastBufferedLine
    bne +
    inc lastBufferedLine+1
    
+   inc bufferTablePosition

    rts


.lineLength     !byte 0     ; used to keep track of 80 chars max per line
.readIndex      !byte 0     ; the lineNr of the current sector we're reading
.charsSinceSpace !byte 0
.indexLength    !byte 0     ; positive if length of line is to be indexed (buffer). negative if not (sectors)

.leftToIndex    !word 0     ; how many bytes in this sector are still left

linesToView    !byte 0     ; how many lines should be viewed? (parse is always done sector-wise)
                            ; 23 for a full screen (header and footer line excluded)
                            ; or 1 if just scrolling up or down
lineTableIncr   = 4
lineBuffer      !fill 2048    ; buffer for lines spreading across sectors. used for displayLineFromCurrentSector
bufferTable     !fill 255       ; 3 bytes per entry, 25 entries max (23, really). 255 bytes make room for 85 entries
nrIndexedSectorLines  !word 0     
firstBufferedLine       !word 0
lastBufferedLine        !word 0

bufferTablePosition !byte 0 ; the lineNr of the buffer we're writing



