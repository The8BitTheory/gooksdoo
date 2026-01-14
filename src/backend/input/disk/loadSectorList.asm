!zone loadSectorList

!macro writeAcc {
    jsr chrout
    ldy $90
    beq +
    jmp outError
+
}

loadSectorList
    lda #18
    sta track
    lda #1
    sta sector

    lda #0
    sta fileOpError

    ; open 15,8,15  - open command channel
    lda #15
    sta diskLoadFileNr
    lda #15
    sta diskLoadSecAddr

    lda #0
    jsr setNamLfsBnk
    jsr openForOutput

    ; open 5,8,5,"#"    - open direct access channel
    lda #5
    sta diskLoadFileNr
    lda #5
    sta diskLoadSecAddr
    
    lda #1
    ldx #<.filenameOpenBuffer
    ldy #>.filenameOpenBuffer
    jsr setNamLfsBnk
    jsr openForInput

.readSector
    ;lda #1
    ;sta .headOnly
    jsr doReadSector

    jmp .searchFileInSector

    ; get#5 sector of next block

.close
    ; close5
    lda #5
    sta diskLoadFileNr
    jsr closeDiskFile
    ; close15
    lda #15
    sta diskLoadFileNr
    jsr closeDiskFile

    rts

.searchFileInSector
    ldy #2
-   lda sectorData,y
    cmp #$81        ; match filetype seq?
    beq .searchFilename ; type matches, check filename

    ; otherwise, check next directory entry
.checkNextDirectoryEntry
    tya
    clc
    adc #32
    bcs .goToNextSector
    tay
    jmp -

.goToNextSector
    lda nextTrack
    beq +       ; null means: last sector reached
    sta track
    lda nextSector
    sta sector
    jmp .readSector

+   jmp .fileNotFound
    nop
    nop


.searchFilename
    sty .index
    iny
    lda sectorData,y
    sta track
    iny
    lda sectorData,y
    sta sector

    ldx #0
-   iny
    lda sectorData,y
    cmp .filename,x
    bne .skipToNextEntry
    inx
    cmp #$a0
    bne -

    lda .index
    clc
    adc #28
    tay
    lda sectorData,y
    sta .nrBlocks
    lda sectorData+1,y
    sta .nrBlocks+1
    jmp .fileFound

.skipToNextEntry
    ldy .index
    jmp .checkNextDirectoryEntry

.fileNotFound
    jmp .close
    rts

.fileFound
    jsr initPlainTextSectorParser ; initializes all variables and pointers

    ;lda #0
    ;sta .headOnly

    ; get the first/next sector of the file
-   jsr doReadSector

; parse it and keep parsing until we have lineTable entries for the first 25 (or 23) lines on screen
    
    jsr parseSector         ; parses as many lines as the sector contains. might end with incomplete line
;    jsr displayLines        ; displays as many complete lines as have been parsed.

    lda nextTrack
    beq +

    lda nextTrack
    sta track
    lda nextSector
    sta sector
    jmp -
    
+   jmp .close
    nop
    nop
    rts
    nop

; this routine could be moved to a low-level disk-related asm file
doReadSector
    ldx #15
    jsr chkout
    bcc +
    jmp outError

    ; print#15,"U1:";7;0;track;sector    - drive reads sector into disk 
+   ldx #0
-   lda .blockRead,x
    beq +
    +writeAcc
    inx
    jmp -

+   lda track
    jsr sendAsDec

    lda #' '
    +writeAcc

    lda sector
    jsr sendAsDec

    lda #$0d
    +writeAcc

+   jsr clrchn

    ldx #5
    jsr chkin
    bcc +
    jmp .inError

+   jsr chrin
    sta nextTrack
    ldx $90
    beq +
    jmp .inError
+   jsr chrin
    sta nextSector
    ldx $90
    beq +
    jmp .inError

+   ;lda .headOnly
    ;beq .sectorComplete 27 vs 72 seconds

    ldy #2
    ; get#5 track of next block
-   jsr chrin
    sta sectorData,y
    ldx $90
    beq +
    cpx #64
    beq .sectorComplete
    jmp .inError
+   iny
    bne -
.sectorComplete
    jsr clrchn
    rts

sendAsDec
    ldx #0
    jsr makeItDec
    
    ldy #1
    sty .index
    ldx #3
-   lda decResult,x
    +writeAcc
    inx
    dec .index
    bpl -

    rts

.inError
    ;5: device not present

    sta .errorCode
    jmp .close

outError
    sta .errorCode
    jmp .close

; when looking for the file to open
nextTrack          !byte 0
nextSector         !byte 0
.filename           !pet "bridge",$a0

.errorCode          !byte 0
track              !byte 0
sector             !byte 0
.filenameOpenBuffer !pet '#'
sectorData             !fill 256
.blockRead          !pet "u1:5 0 ",0;00018 00001",$0d,0; " 5 0 ",0   ; followed by track and sector
.index              !byte 0
.nrBlocks           !word 0 ; the number of blocks the file has
