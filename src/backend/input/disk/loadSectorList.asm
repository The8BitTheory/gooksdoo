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

closeSectorAccess
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
    cmp diskLoadFilename,x
    bne .skipToNextEntry
    inx
    cmp #$a0
    bne -

    lda .index
    clc
    adc #28
    tay
    lda sectorData,y
    sta fileNrBlocks
    lda sectorData+1,y
    sta fileNrBlocks+1
    
    jmp loadSeqFileViaSectors

.skipToNextEntry
    ldy .index
    jmp .checkNextDirectoryEntry

.fileNotFound
    jmp closeSectorAccess
    rts


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
    sta sectorData
    ldx $90
    beq +
    jmp .inError
+   jsr chrin
    sta nextSector
    sta sectorData+1
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
    jmp closeSectorAccess

outError
    sta .errorCode
    jmp closeSectorAccess

; when looking for the file to open
nextTrack          !byte 0
nextSector         !byte 0
;.filename           !pet "bridge",$a0
;.filename           !pet "beowulf",$a0

.errorCode          !byte 0
track              !byte 0
sector             !byte 0
.filenameOpenBuffer !pet '#'
sectorData             !fill 256
.blockRead          !pet "u1:5 0 ",0;00018 00001",$0d,0; " 5 0 ",0   ; followed by track and sector
.index              !byte 0

fileNrBlocks           !word 0 ; the number of blocks the file has



