!zone plainTextSectorParser

initPlainTextSectorParser
    lda #<lineTable
    sta zp_sectorLineTable
    lda #>lineTable
    sta zp_sectorLineTable+1

    lda #0
    sta latestParsedLine
    sta latestParsedLine+1
    sta parseLinePointer
    sta parseLinePointer+1

    lda #23
    sta linesToView

    jmp initBufferLineTable


; this indices the lines of the sector for 80 chars max per line.
indexSectorWrapped
    lda nextTrack
    beq +       ; if zero: last sector of file. .nextSector contains nr of bytes in this sector
    ldx #$fe    ; not zero. sector contains 254 bytes
    jmp ++
+   ldx nextSector
    
++  stx .leftToParse
    ldy #2
    sty .readIndex
-   jsr .parseLine
    ldy .leftToParse
    beq +
    bne -

+   rts

readNextByte
    ldy .readIndex
    lda sectorData,y
    inc .readIndex
    dec .leftToParse
    rts

readNextByteWithoutInc
    ldy .readIndex
    lda sectorData,y
    rts

; each line takes 3 bytes in the lineTable. 2 bytes for pointer, 1 byte for line length
.parseLine
    lda .lineLength
    bne .continueParseLine

    jsr .storePointerInLineTable    ; stores the start of the line (device, track, sector, y-offset)
    jsr .writeBufferEntryPosition

    lda #0
    sta .charsSinceSpace

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

    lda .leftToParse
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
    lda .leftToParse
    adc .charsSinceSpace
    sta .leftToParse

.finishLineWithBreak
    inc lineCount
    bne +
    inc lineCount+1
    
+   inc parseLinePointer

    jsr .writeBufferEntryLength

    lda #0
    sta .lineLength
    sta .charsSinceSpace

    inc latestParsedLine
    bne +
    inc latestParsedLine+1

+   lda .leftToParse
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
    
; increase line-table pointer by 5 (read entry)
    jsr incLineTable

    rts

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

    

; this is used for initial display of the screen
sectorDataToBuffer
    ; load pointer to sectorData line from lineTable
    ldx #2
    ldy #0
-   lda sectorData,x

; TODO: here we'll need to check for linebreaks and exceeded line length



    sta (zp_lineBufferPos),y
    iny
    inx
    beq .copyLineTableIndices
    bne -   ; as we read 254 bytes, this is always true

.copyLineTableIndices
; this takes the lineTable entries of this sector and translates them into indices for the buffer.

.sectorDataCopied
    clc
    tya
    adc zp_lineBufferPos
    sta zp_lineBufferPos
    bcc +
    inc zp_lineBufferPos+1
+   rts
    nop

;    lda bufferLinePointer
;    sta multiply16
;    lda bufferLinePointer+1
;    sta multiply16+1
;    lda #lineTableIncr
;    sta multiply8
;    jsr multiply    ; result: a=lo, y=hi

;    jsr calcZpLineTable

;.nextLineFromSectorData
;    ldy #3
;    lda (zp_sectorLineTable),y
;    sta .readIndex
    
;    iny
;    lda (zp_sectorLineTable),y
;    tax ; line length
;    stx .lineLength

;    jsr .writeBufferEntry

;-   ldy .readIndex
;    lda sectorData,y
    
;    ldy .writeIndex
;    sta lineBuffer,y
    
;    inc .writeIndex
;    bne +
;    inc .writeIndex+1

;+   inc .readIndex
;    beq +       ; .readIndex is running over. sector data is at an end
;    dec .lineLength
;    bne -
    ;jsr .writeBufferEntry
;    jmp .nextLineFromSectorData

;    lda #$0d
;    jsr chrout

;+   rts
;    nop

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

;    iny
;    lda .lineLength
;    sta bufferTable,y

; increase line-buffer pointer by 3 (write entry)
;    clc
;    lda zp_bufferLineTable
;    adc #3
;    sta zp_bufferLineTable
;    lda zp_bufferLineTable+1
;    adc #0
;    sta zp_bufferLineTable+1

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
    bne +
    inc bufferTablePosition+1

+   rts


.temp4          !word 0,0
.lineLength     !byte 0     ; used to keep track of 80 chars max per line
.readIndex      !byte 0     ; the lineNr of the current sector we're reading
.charsSinceSpace !byte 0

.leftToParse    !byte 0     ; how many bytes in this sector are still left
lineCount       !word 0     ; nr of total lines parsed in the file so far
linesToView    !byte 0     ; how many lines should be viewed? (parse is always done sector-wise)
                            ; 23 for a full screen (header and footer line excluded)
                            ; or 1 if just scrolling up or down
lineTableIncr   = 4
latestParsedLine   !word 0 ; how many lines of the document are available for display?
lineBuffer      !fill 2000    ; buffer for lines spreading across sectors. used for displayLineFromCurrentSector
bufferTable     !fill 69        ; 3 bytes per entry, 25 entries max (23, really)

bufferTablePosition !byte 0 ; the lineNr of the buffer we're writing

