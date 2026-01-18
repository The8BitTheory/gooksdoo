
!src <cbm/c128/vdc.a>

*=$1c01
!byte $0c,$1c,$b5,$07,$9e,$20,$37,$31,$38,$32,$00,$00,$00
;jmp main

main
    lda #$0d
    jsr chrout
    lda #14
    jsr chrout

    jsr .printLineTableAddress
    jsr showTextfile
;    jsr showDirectory

    rts

.printLineTableAddress
    lda #>lineTable
    jsr byteToHex
    lda hexStringResult
    jsr chrout
    lda hexStringResult+1
    jsr chrout
    lda #<lineTable
    jsr byteToHex
    lda hexStringResult
    jsr chrout
    lda hexStringResult+1
    jmp chrout



!src "src/system/c128.asm"
!src "src/converters/converters.asm"
!src "src/converters/calculators.asm"
!src "src/converters/decHelper.asm"
!src "src/backend/input/disk/commonDisk.asm"
!src "src/backend/input/disk/loadDir.asm"
!src "src/backend/input/disk/loadSeq.asm"
!src "src/backend/input/disk/loadSectorList.asm"
!src "src/backend/logic/plainTextSectorParser.asm"
!src "src/frontend/output/textmode/vdcconsole.asm"
!src "src/frontend/logic/showDirectory.asm"
!src "src/frontend/logic/showTextfile.asm"

; a lineTable entry is a pointer into raw content to form a displayable line.
; lines can be 80 chars max
; an entry consists of:
; - 4 bytes: start of line. deviceNr (255 for REU, 254 for GeoRAM), trackNr (1-255), sectorNr (0-), offset inside sector
; - 1 byte: length of line

lineTable = *

