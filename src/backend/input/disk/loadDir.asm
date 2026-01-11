!zone loadDir

loadDirectoryFromDisk
    lda #1
    sta diskLoadDataBank
    lda #0
    sta diskLoadFilenameBank

    lda #$00
    sta diskLoadAddress
    lda #$04
    sta diskLoadAddress+1

    ldx #<.filenameDirectory
    ldy #>.filenameDirectory
    lda #1

    jsr setNamLfsBnk

    ldx diskLoadAddress
    ldy diskLoadAddress+1
    lda #0  ; 0=load, else=verify)

    jsr $ffd5       ;BLOAD
        
    jmp closeDiskFile



.filenameDirectory      !text '$'

