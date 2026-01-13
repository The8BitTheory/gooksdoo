
!src <cbm/c128/vdc.a>

*=$1c01
!byte $0c,$1c,$b5,$07,$9e,$20,$37,$31,$38,$32,$00,$00,$00
;jmp main

main
    jsr showTextfile
;    jsr showDirectory

    rts

filename            !text "About This Serve",0
filenameLength      !byte 16
deviceNumber        !byte 8

!src "src/system/c128.asm"
!src "src/converters/converters.asm"
!src "src/converters/decHelper.asm"
!src "src/backend/input/disk/commonDisk.asm"
!src "src/backend/input/disk/loadDir.asm"
;!src "src/backend/input/disk/loadSeq.asm"
!src "src/backend/input/disk/loadSectorList.asm"
!src "src/backend/logic/plainTextSectorParser.asm"
!src "src/frontend/output/textmode/vdcconsole.asm"
!src "src/frontend/logic/showDirectory.asm"
!src "src/frontend/logic/showTextfile.asm"

; a lineTable entry is a pointer into raw content to form a displayable line.
; lines can be 80 chars max
; an entry consists of:
; - 2 bytes: start of line
; - 1 byte: length of line

lineTable = *

