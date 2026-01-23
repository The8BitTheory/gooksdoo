!zone plainTextSectorParser

initPlainTextSectorParser
    lda #<lineTable
    sta zp_sectorLineTable
    lda #>lineTable
    sta zp_sectorLineTable+1

    lda #0
    sta parseLinePointer
    sta parseLinePointer+1

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
    sta .storePointerTarget
    lda #>.storePointerInLineTable
    sta .storePointerTarget+1

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
    inc .readIndex
    dec .leftToIndex
    rts

readNextByteWithoutInc
    ldy .readIndex
    lda (zp_indexPtr),y ; was: sectorData,y
    rts

.storePointer
    jmp (.storePointerTarget)

; each line takes 3 bytes in the lineTable. 2 bytes for pointer, 1 byte for line length
.parseLine
    lda .lineLength
    bne .continueParseLine

    lda #0
    sta .charsSinceSpace

    ;jsr .storePointerInLineTable    ; stores the start of the line (device, track, sector, y-offset)
    jsr .storePointer

;    ldy .readIndex
;    dey
;    dey
;    tya
;    clc
;    adc zp_lineBufferPos
;    sta zp_lineBufferPos
;    bcc +
;    inc zp_lineBufferPos+1
;+   jsr .writeBufferEntryPosition


.continueParseLine
-   jsr readNextByte
+   cmp #' '            ; if this is a space character, we reset the counter
    bne +
    ldy #0
    sty .charsSinceSpace ; y should be zero because it was set in readNextByte
+   inc .charsSinceSpace
    
    cmp #$0d    ;line break?
    beq .finishLineWithBreak
    cmp #$0a    ; other line break
    beq -

    inc .lineLength
    lda .lineLength
    cmp #80
    beq .finishLine

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

.finishLineWithBreak
    inc lineCount
    
    lda #0
    sta .lineLength
    sta .charsSinceSpace

    lda .leftToIndex
    beq .doneParse
    jmp .parseLine

.doneParse
    rts
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
    
incLineTable
    clc
    lda zp_sectorLineTable
    adc #lineTableIncr
    sta zp_sectorLineTable
    bcc +
    inc zp_sectorLineTable+1
+   rts

initBufferLineTable
    lda #<lineBuffer
    sta zp_lineBufferPos
    lda #>lineBuffer
    sta zp_lineBufferPos+1
    
    rts

sectorDataToBuffer
    ldx #2
    ldy #0
-   lda sectorData,x
    sta (zp_lineBufferPos),y
    iny
    inx
    beq +
    bne -   ; as we read only 254 bytes, this is always true

+   clc
    tya
    adc zp_lineBufferPos
    sta zp_lineBufferPos
    bcc +
    inc zp_lineBufferPos+1
+   rts
    nop

indexBufferWrapped
    ldy lineCount
    sty .nrBufferEntries

    jsr initBufferLineTable

    lda #<lineBuffer
    sta zp_indexPtr
    lda #>lineBuffer
    sta zp_indexPtr+1

    lda #<.writeBufferEntryPosition
    sta .storePointerTarget
    lda #>.writeBufferEntryPosition
    sta .storePointerTarget+1

    ldy #0
    sty .readIndex
-   jsr .parseLine

    dec .nrBufferEntries
    beq +
    bne -

+   rts


    rts
    nop



.writeBufferEntryPosition
    lda bufferTablePosition
    asl
    adc bufferTablePosition
    tay

    lda zp_lineBufferPos
    sta bufferTable,y
    
    iny
    lda zp_lineBufferPos+1
    sta bufferTable,y

    rts

.writeBufferEntryLength
    lda bufferTablePosition
    asl
    adc bufferTablePosition
    tay
    iny
    iny
    lda .lineLength
    sta bufferTable,y
    
    inc bufferTablePosition

    rts


.storePointerTarget !word 0
.temp4          !word 0,0
.lineLength     !byte 0     ; used to keep track of 80 chars max per line
.readIndex      !byte 0     ; the lineNr of the current sector we're reading
.charsSinceSpace !byte 0

.leftToIndex    !byte 0     ; how many bytes in this sector are still left

lineCount       !byte 0     ; nr of lines indexed from sectors (used to index buffer as a countdown)

linesToView    !byte 0     ; how many lines should be viewed? (parse is always done sector-wise)
                            ; 23 for a full screen (header and footer line excluded)
                            ; or 1 if just scrolling up or down
lineTableIncr   = 4
lineBuffer      !fill 2000    ; buffer for lines spreading across sectors. used for displayLineFromCurrentSector
bufferTable     !fill 255       ; 3 bytes per entry, 25 entries max (23, really). 255 bytes make room for 85 entries
.nrBufferEntries    !byte 0

bufferTablePosition !byte 0 ; the lineNr of the buffer we're writing


