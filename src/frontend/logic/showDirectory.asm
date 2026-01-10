!zone showDirectory

showDirectory

    lda #$00
    sta diskLoadAddress
    lda #$04
    sta diskLoadAddress+1
    lda #$01
    sta diskLoadDataBank
    ;lda #$00
    ;sta diskLoadFilenameBank
    jsr loadDirectoryFromDisk

    ; break up directory into screenlines
    lda #<lineTable
    ldx #>lineTable

    jmp printDirectory
    nop
    nop
