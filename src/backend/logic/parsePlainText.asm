; this reads a seq file byte by byte, directly from disk.
; when a new line starts, a pointer to that position is stored in lineTable
; word wrap is done accordingly (primitive, according to space characters)
; when a linebreak is encountered, the length is stored and parsing the line is done.
; the last parsed position is kept, which makes it easy to continue parsing on the next line.

; this routine only deals with disk and ram (not vram, etc)

!zone plainText
parsePlainText
    +print txtParsing
    jsr initParser

    lda #0
    sta .lineLength
    sta charsSinceSpace

; each line takes 3 bytes in the lineTable. 2 bytes for pointer, 1 byte for line length
.parseLine
    jsr .storePointerInLineTable
    lda #0
    sta charsSinceSpace

-   jsr readNextByte
    bcs .finishLineWithBreak
    cmp #' '            ; if this is a space character, we reset the counter
    bne +
    sty charsSinceSpace ; y should be zero because it was set in readNextByte
+   inc charsSinceSpace
    
    cmp #$0d    ;line break?
    beq -
    cmp #$0a    ; other line break
    beq .finishLineWithBreak

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
    sbc charsSinceSpace
    sta .lineLength
    ; next, reset out read pointer to after the last space

    dec charsSinceSpace
    sec
    lda zp_contentAddress
    sbc charsSinceSpace
    sta zp_contentAddress
    lda zp_contentAddress+1
    sbc #0
    sta zp_contentAddress+1

.finishLineWithBreak
    inc zp_linecount
    bne +
    inc zp_linecount+1
    
+   lda .lineLength
    jsr .storeValueInLineTable
    lda #0
    jsr .storeValueInLineTable
    lda #0
    sta .lineLength
    sta charsSinceSpace

    lda leftToParse+1
    bne .parseLine
    lda leftToParse
    bne .parseLine

.doneParse
    jsr .storePointerInLineTable
    lda .lineLength
    jmp .storeValueInLineTable
    lda #0
    jmp .storeValueInLineTable


.storeValues
    lda zp_contentAddress
    sta .temp4
    lda zp_contentAddress+1
    sta .temp4+1
    lda leftToParse
    sta .temp4+2
    lda leftToParse+1
    sta .temp4+3
    rts

.recoverValues
    lda .temp4
    sta zp_contentAddress
    lda .temp4+1
    sta zp_contentAddress+1
    lda .temp4+2
    sta leftToParse
    lda .temp4+3
    sta leftToParse+1
    rts

.checkEndChar
; store values for if we're not at the end
    lda zp_contentAddress
    sta .temp4
    lda zp_contentAddress+1
    sta .temp4+1
    lda leftToParse
    sta .temp4+2
    lda leftToParse+1
    sta .temp4+3

    jsr readNextByte
    cmp #'.'
    bne +

    jmp .doneParse  ;if we find a single dot on a line, this is the end of the file

.storeValueInLineTable
    ldy #0
    jsr writeToLineTable
    rts

.storePointerInLineTable
    ldy #0
    lda zp_contentAddress

    jsr writeToLineTable
    lda zp_contentAddress+1

    jsr writeToLineTable

    rts


.stashToLineTable
    ldx zp_contentBank
    ; y must be set accordingly at this point
    jsr c_stash
    inc zp_lineTable
    bne +
    inc zp_lineTable+1

+   rts

.temp4          !word 0,0
.lineLength     !byte 0     ; used to keep track of 80 chars max per line
charsSinceSpace !byte 0