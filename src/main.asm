
!src <cbm/c128/vdc.a>

k_primm = $ff7d

*=$1c01
!byte $0c,$1c,$bb,$07,$9e,$20,$37,$31,$38,$32,$00,$00,$00
;jmp main

main
    jsr saveZp
    
    lda #09
    sta $ba ; set devicenr to 9
    jsr disableBasicRom
    jsr initVdcTextmode
    jsr clearScreen

    ;lda #$0d
    ;jsr chrout
    ;lda #14
    ;jsr chrout

    ;jsr .printSectorDataAddress
    ;jsr .printLineTableAddress
    ;jsr .printLineBufferAddress
    ;jsr .printLineBufferTableAddress
    
    jsr showTextfile
;    jsr showDirectory

    jsr recoverZp
    jmp setBank15
    

.printSectorDataAddress
    jsr k_primm
    !pet "sectorData: $",0

    lda #>sectorData
    jsr byteToHex
    lda hexStringResult
    jsr chrout
    lda hexStringResult+1
    jsr chrout
    lda #<sectorData
    jsr byteToHex
    lda hexStringResult
    jsr chrout
    lda hexStringResult+1
    jsr chrout
    lda #$0d
    jmp chrout

.printLineBufferTableAddress
    jsr k_primm
    !pet "lineBufferTable: $",0

    lda #>bufferTable
    jsr byteToHex
    lda hexStringResult
    jsr chrout
    lda hexStringResult+1
    jsr chrout
    lda #<bufferTable
    jsr byteToHex
    lda hexStringResult
    jsr chrout
    lda hexStringResult+1
    jsr chrout
    lda #$0d
    jmp chrout

.printLineBufferAddress
    jsr k_primm
    !pet "lineBuffer: $",0

    lda #>lineBuffer
    jsr byteToHex
    lda hexStringResult
    jsr chrout
    lda hexStringResult+1
    jsr chrout
    lda #<lineBuffer
    jsr byteToHex
    lda hexStringResult
    jsr chrout
    lda hexStringResult+1
    jsr chrout
    lda #$0d
    jmp chrout

.printLineTableAddress
    jsr k_primm
    !pet "lineTable: $",0

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
    jsr chrout
    lda #$0d
    jmp chrout

!src "src/system/c128.asm"
!src "src/converters/converters.asm"
!src "src/converters/calculators.asm"
!src "src/converters/decHelper.asm"
!src "src/backend/input/disk/commonDisk.asm"
!src "src/backend/input/disk/loadCharset.asm"
!src "src/backend/input/disk/loadDir.asm"
!src "src/backend/input/disk/loadSeq.asm"
!src "src/backend/input/disk/loadSectorList.asm"
!src "src/backend/logic/plainTextSectorParser.asm"
!src "src/frontend/output/textmode/vdcconsole.asm"
!src "src/frontend/logic/showDirectory.asm"
!src "src/frontend/logic/showTextfile.asm"
!src "src/frontend/output/textmode/initVdcText.asm"
!src "src/frontend/output/utf8.asm"

; a lineTable entry is a pointer into raw content to form a displayable line.
; lines can be 80 chars max
; an entry consists of:
; - 4 bytes: start of line. deviceNr (255 for REU, 254 for GeoRAM), trackNr (1-255), sectorNr (0-), offset inside sector
; - 1 byte: length of line

lineTable = *

