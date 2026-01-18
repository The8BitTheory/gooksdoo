!zone plainTextSectorParser

initPlainTextSectorParser
    lda #<lineTable
    sta zp_lineTable
    lda #>lineTable
    sta zp_lineTable+1

    lda #0
    sta latestParsedLine
    sta latestParsedLine+1

    lda #23
    sta linesToView
    rts

parseSector
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
    bne +
    sec
    rts

+   clc
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
    lda #0
    sta .charsSinceSpace

.continueParseLine
-   jsr readNextByte
    bcc +
    jmp .doneParse
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
    
+   ldy #4
    lda .lineLength
    sta (zp_lineTable),y

    jsr incLineTable

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


.storePointerInLineTable
    ldy #0
    lda diskLoadDeviceNr
    sta (zp_lineTable),y

    iny
    lda track
    sta (zp_lineTable),y

    iny
    lda sector
    sta (zp_lineTable),y

    iny
    lda .readIndex
    sta (zp_lineTable),y

    rts


writeToLineTable
    ; y must be set accordingly at this point
    sta (zp_lineTable),y

    rts

incLineTable
    clc
    lda zp_lineTable
    adc #lineTableIncr
    sta zp_lineTable
    lda zp_lineTable+1
    adc #0
    sta zp_lineTable+1
    rts



.temp4          !word 0,0
.lineLength     !byte 0     ; used to keep track of 80 chars max per line
.readIndex      !byte 0
.charsSinceSpace !byte 0

.leftToParse    !byte 0     ; how many bytes in this sector are still left
lineCount       !word 0     ; nr of total lines parsed in the file so far
linesToView    !byte 0     ; how many lines should be viewed? (parse is always done sector-wise)
                            ; 23 for a full screen (header and footer line excluded)
                            ; or 1 if just scrolling up or down
lineTableIncr   = 5
latestParsedLine   !word 0 ; how many lines of the document are available for display?
lineBuffer      !fill 80    ; buffer for lines spreading across sectors. used for displayLineFromCurrentSector
