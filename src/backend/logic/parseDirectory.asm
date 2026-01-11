!zone parseDirectory
; this creates the lineTable entries for properly displaying the directory
; it only parses a given number of lines, starting at a given number (usually the last "parsed" line)
; data is parsed from $1:0400

.readNextByte
    ldx zp_directoryBank
    ldy #0
    jsr c_fetch

.skipNextByte
    inc zp_directoryAddress
    bne +
    inc zp_directoryAddress+1

+   rts

parseDirectory
    lda #zp_directoryAddress
    sta c_fetch_zp

    ; skip 5 bytes (8 really, but 2 were skipped by bload itself)
    ; one of these is the reverse-flag for screen output. we ignore that
    jsr .skipNextByte
    jsr .skipNextByte
    jsr .skipNextByte
    jsr .skipNextByte
    jsr .skipNextByte

    ; read diskname
    jsr .handleDiskName


; parsing dir entries until end of dir
-   jsr .skipNextByte    ;$01
    jsr .skipNextByte    ;$01

    jsr .readNextByte
    sta .fileSize
    pha
    jsr .readNextByte
    sta .fileSize+1
    tax
    pla
    ;ldx .fileSize+1
    jsr makeItDec
    jsr .skipZeroes
    sty zp_tempX

    jsr .readNextByte    ; space if dir entry, B ($42) if end of dir (B of BLOCKS FREE)
    cmp #' '
    bne +
    jsr .handleDirEntry ; name and type is parsed here
    jmp -

; parsing dir entries done
; fileSize already contains the nr of free bytes
+   sta zp_tempA
    lda .fileSize
    ldx .fileSize+1
    jsr makeItDec
    jsr .skipZeroes

    clc
    tya
    adc #<decResult
    sta zp_memPtr
    lda #>decResult
    adc #0
    sta zp_memPtr+1
    jsr printHeaderLineUntilTab

    lda #' '
    jsr printAcc

    jsr .handleDirEnd

    lda #<.blocksFree
    sta zp_memPtr
    lda #>.blocksFree
    sta zp_memPtr+1
    jsr printHeaderLineUntilTab

    +writeLnToDir txtEmptyLine
    +writeLnToDir txtEmptyLine
    +writeLnToDir txtDot

    clc
    lda dirAddress
    adc #1
    sta zp_directoryAddress
    lda dirAddress+1
    adc #0
    sta zp_directoryAddress+1
    
    rts

.handleDirEntry   ;blocks, name, type
    sta .parsedChar    ; the character parsed recently

    lda #0
    sta .linePos

    ; write blocks. zp_tempX was written after .skipZeroes
-   ldy zp_tempX
    lda decResult,y
    beq +
    jsr writeToVisibleLine
    inc zp_tempX
    jmp -

+   lda .parsedChar        ; this is the space character that was parsed but not displayed
    jsr writeToVisibleLine
    jsr writeToVisibleLine    ; write a second space character. makes the directory appear better imho

-   jsr readNextByte        ; can be quote or space
    cmp #$22                ; is quote?
    beq +
    jsr writeToVisibleLine
    jmp -

    
+   jsr writeToVisibleLine
    
    ; parse filename
    ldy #0  ; index for filename
    sty zp_tempY
-   jsr readNextByte    ; the first byte should be a quote char
    cmp #$22
    beq .filenameDone   ; null byte. we're done with parsing the entry line
    ldy zp_tempY
    sta .filename,y                ; if yes, write to filename
    inc zp_tempY
    jsr writeToVisibleLine
    jmp -

.filenameDone
    jsr writeToVisibleLine    ; the trailing quotes character

    ldy zp_tempY
    ;iny
    lda #0
    sta .filename,y             ; conclude .filename with null byte

-   jsr readNextByte
    cmp #' '    ; when space characters end, we'll parse the filetype
    bne +
    jsr writeToVisibleLine
    jmp -

; here comes the filetype. PRG, SEQ, REL, USR, DEL, ...
; seq should be opened when pressing return (it's either a textfile or a gopher file)
; directories should be opened and listed
; all other filetypes should not do anything at the moment
+   sta .filetype
    jsr writeToVisibleLine
-   jsr readNextByte
    beq .createGopherLine
    jsr writeToVisibleLine
    jmp -

.createGopherLine
    lda .filetype
    cmp #'S'
    beq +
    lda #'i'
    jmp ++
+   lda #$30
++  jsr writeToDirectory

    ldx #0
    stx zp_tempX
-   ldx zp_tempX
    lda .visibleLine,x
    jsr writeToDirectory
    inc zp_tempX
    dec .linePos
    bne -
    
    lda .filetype
    cmp #'S'
    beq +
    +writeLnToDir txtTrail
    rts

    
+   lda .txtTab
    jsr writeToDirectory

    ; selector
    lda #'/'
    jsr writeToDirectory
    ldx #0
    stx zp_tempX
-   ldx zp_tempX
    lda .filename,x
    beq +
    jsr writeToDirectory
    inc zp_tempX
    jmp -

    
+   lda .txtTab
    jsr writeToDirectory

    ; host
    ldx #0
    stx zp_tempX
-   ldx zp_tempX
    lda .txtDevice,x
    beq +
    jsr writeToDirectory
    inc zp_tempX
    jmp -

+   lda .txtTab
    jsr writeToDirectory

    ; port
    clc
    lda deviceNumber
    adc #$30
    jsr writeToDirectory
    ;lda .txtTab
    ;jsr writeToDirectory
    ;lda #' '
    ;jsr writeToDirectory
    lda #$0d
    jsr writeToDirectory
    lda #$0a
    jsr writeToDirectory

    rts

.handleDiskName
    jsr .skipNextByte   ; this should be the quote char
    ldx #0
    stx zp_tempX

-   jsr .readNextByte    ; this should be a quote char
    cmp #$22            ; quote character (ending the filename)
    beq +
    ldx zp_tempX
    sta .diskname,x
    inc zp_tempX
    jmp -

+   .skipNextByte
    .skipNextByte
    .skipNextByte

    jsr .readNextByte
    sta .diskId
    jsr .readNextByte
    sta .diskId+1

    .skipNextByte   ; zero byte, ending the diskname line

+   rts

; string is also 24 bytes long. BLOCKS FREE with trailing spaces
.handleDirEnd
    ldx #0
    stx zp_tempX
    lda zp_tempA
    sta .blocksFree,x
    inc zp_tempX

-   jsr readNextByte    ; this should be a quote char
    beq +
    ldx zp_tempX
    sta .blocksFree,x
    inc zp_tempX
    lda zp_tempX
    cmp #26
    beq +
    jmp -

+   rts
    nop

.initDirectoryGopherOutput
    lda zp_contentAddress
    sta zp_directoryAddress
    sta dirAddress
    lda zp_contentAddress+1
    sta zp_directoryAddress+1
    sta dirAddress+1

    lda #0
    sta zp_linecount
    sta zp_linecount+1
    sta zp_responseSize
    sta zp_responseSize+1
    
    lda #$31
    sta zp_pageType

    rts

writeToDirectory
    ldx zp_contentBank
    ldy #0
    jsr c_stash

    inc zp_directoryAddress
    bne +
    inc zp_directoryAddress+1
    
+   inc zp_responseSize
    bne +
    inc zp_responseSize+1

+   rts

.skipZeroes
    ; skip leading zeroes. if all zeroes, keep the last one (so we display "0" blocks)
    ldx #0
    ldy #0
-   lda decResult,x
    cmp #$30
    bne +
    iny
+   inx
    cpx #4
    bne -

    rts

writeToVisibleLine
    ldx .linePos
    sta .visibleLine,x
    inc .linePos
    rts

.filename       !fill 17,0  ; reserve one more byte, that will always be null
.filetype       !byte 0     ; one byte to store filetype. first char of whatever it is
.diskname       !fill 17,0  ; null-terminated diskname string
.diskId         !fill 3,0   ; null-terminated diskId string
.blocksFree     !fill 26,0
.fileSize       !word 0
.txtDirOfDisk   !text "Diskname: ",0
.txtDash        !text " - ",0
.txtTab         !byte $09
.visibleLine    !fill 32,0
.linePos        !byte 0
.txtDevice      !text "device",0
.parsedChar     !byte 0
