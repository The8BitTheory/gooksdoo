!zone showDirectory

; showing the directory works line by line.
; first: we'll find the startline (easy if zero)
; then we'll break up the lines into 80-char max segments, including proper word wrap
; once 25 lines are parsed (or how many we need), we'll display them
; parsing results are written into the lineTable.
; whenever a line is displayed a second time (eg by scrolling back), no more parsing is needed
; if we skip forward (eg scroll by full pages or jumping to a given line number), the parsing is done on-demand
; raw data is kept in memory, the lineTable just points into the respective addresses

showDirectory

    lda #$00
    sta diskLoadAddress
    sta zp_directoryAddress
    lda #$04
    sta diskLoadAddress+1
    sta zp_directoryAddress+1
    lda #$01
    sta diskLoadDataBank
    sta zp_directoryBank
    ;lda #$00
    ;sta diskLoadFilenameBank
    jsr loadDirectoryFromDisk
    ;jsr loadSectorList

    ;jsr parseDirectory

    ; break up directory into screenlines
    lda #<lineTable
    ldx #>lineTable

;    jsr clearScreen

    jmp printDirectory
    nop
    nop


.startLine          !word 0     ; first line to show
.lastParsedLine     !word 0     ; showing lines beyond that need to be parsed first

.nrLinesToShow      !byte 0     

