!zone loadSectorList

chrout = $ffd2
chkout = $ffc9  ; x=logFn, sets device for chrout

chkin = $ffc6
chrin = $ffcf

loadSectorList
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
    lda #<.filenameOpenBuffer
    ldx #>.filenameOpenBuffer
    jsr setNamLfsBnk
    jsr openForInput

    lda #18
    sta .track
    lda #01
    sta .sector

    ; print#15,"U1:";7;0;track;sector    - drive reads sector into disk 
    ;ldx #15
    ;jsr chkout

    ldx #0
-   lda .directoryCmd,x
    beq +
    jsr chrout
    ldy $90
    bne .outError
    inx
    jmp -

+   lda #'4'
    jsr chrout
    lda #'0'
    jsr chrout
    lda #' '
    jsr chrout
    lda #'0'
    jsr chrout

    ;ldx #5
    ;jsr chkin
    ;bcs .inError
    ldy #0
    ; get#5 track of next block
-   jsr chrin
    sta .result,y
    ldx $90
    bne .inError
    inx
    bne -

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

.inError
    ;5: device not present

    sta .errorCode
    jmp .close

.outError
    sta .errorCode
    jmp .close

.errorCode          !byte 0
.track              !byte 0
.sector             !byte 0
.filenameOpenBuffer !text '#'
.result             !fill 256
.directoryCmd       !pet "u1 5 0 ",0   ; followed by track and sector