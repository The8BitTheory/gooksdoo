
!src <cbm/c128/vdc.a>

*=$1c01
!byte $0c,$1c,$b5,$07,$9e,$20,$37,$31,$38,$32,$00,$00,$00
;jmp main

main
    lda #$00
    sta diskLoadAddress
    lda #$04
    sta diskLoadAddress+1
    lda #$01
    sta diskLoadDataBank
    ;lda #$00
    ;sta diskLoadFilenameBank

    jsr loadDirectoryFromDisk

    jsr printDirectory


    ;jsr loadSeqFile
    
    rts

filename            !text "About This Serve",0
filenameLength      !byte 16
deviceNumber        !byte 8

!src "src/system/c128.asm"
!src "src/converters/converters.asm"
!src "src/backend/input/disk/commonDisk.asm"
!src "src/backend/input/disk/loadDir.asm"
!src "src/backend/input/disk/loadSeq.asm"
!src "src/frontend/output/textmode/vdcconsole.asm"