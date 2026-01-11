!zone loadSectorList

loadSectorList
    ; open 15,8,15  - open command channel
    ; open 5,8,7,"#"    - open direct access channel

    ; print#15,"U1";7;0;track;sector    - drive reads sector into disk buffer
    ; get#5 track of next block
    ; get#5 sector of next block

    ; close5
    ; close15

    lda #3
    sta diskLoadFileNr

    lda #7
    sta diskLoadSecAddr

    ; open logFn,deviceNr,channelNr,
    ; a=filename length, x=filename LB, y=filename HB to be set
    lda #1
    ldx #<.filenameOpenBuffer
    ldy #>.filenameOpenBuffer
    jsr setNamLfsBnk

    jsr openForInput

    ldx #0
-   jsr $ffcf   ;chrin
    sta .result,x
    inx
    bne -

    jsr closeDiskFile

    rts

.filenameOpenBuffer !text '#'
.result             !fill 256
