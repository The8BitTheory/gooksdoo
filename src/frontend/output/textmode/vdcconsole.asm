!zone vdcConsole

; write acc to current position in vram
; (convert acc to screencode and set vram position to screen-ram to use it in a print-like way)
;    ldx #31
;    jsr A_to_vdc_reg_X


!macro home {
}

!macro setCursorXY .xPos, .yPos {
    ;regs $18/$19 (dec 12/13) set vram address
    ldx #.xPos
    lda #.yPos
    asl
    tay
    lda screenLineOffset,y  ; lb. needed in Y
    pha
    iny
    lda screenLineOffset,y  ; hb. needed in A
    tax
    pla
    clc
    adc #.xPos
    tay
    
    txa
    adc #0

    jsr AY_to_vdc_regs_18_19
}

!macro printAcc {
    ldx #31
    jsr toScreencode
    jsr A_to_vdc_reg_X  ; no rts here. this is a macro, not a subroutine
}

!macro printString .nullTerminatedString {
    ldx #31
    ldy #0
-   lda .nullTerminatedString,y
    beq +
    jsr toScreencode        ; only modifies Acc
    jsr A_to_vdc_reg_X
    iny
    jmp -
+
}

home
    +setCursorXY 0,0
    rts

; fills screen-ram with 0 and attribute-ram with second charset, fc white, bc black
clearScreen
    jsr setBlockFill

    ; screen ram ($0000)
    lda #$20    ;space characters
    ldy #0
    ldx #0
    jsr A_to_vram_XXYY  ; write first byte

    ; 2000 bytes ($07d0)
    lda #$d0    ;lowbyte
    ldy #$07    ;highbyte
    jsr vdc_do_YYAA_cycles

    ; attribute ram ($0800)
    lda #$c2    ;white foreground, charset 1 (upper/lower)
    ldy #00
    ldx #08
    jsr A_to_vram_XXYY  ; write first byte

    ; 2000 bytes ($07d0)
    lda #$d0    ;lowbyte
    ldy #$07    ;highbyte
    jmp vdc_do_YYAA_cycles


; set lines 1 - 23 to charset1, text black data
; screen-ram
    lda #%10000000
    ldy #$50
    ldx #$08
    jsr A_to_vram_XXYY

    ;set count
    lda #$2f    ;lowbyte
    ldy #$07    ;highbyte
    jmp vdc_do_YYAA_cycles
    rts

drawTextfileBorder
    ; top-left corner
    lda #144
    ldx #0
    ldy #80
    jsr A_to_vram_XXYY

    ; top line
    jsr setBlockFill
    lda #142
    ldx #00
    ldy #81
    jsr A_to_vram_XXYY
    
    ldy #00
    lda #77
    jsr vdc_do_YYAA_cycles

    ; top-right corner
    lda #146
    ldx #0
    ldy #159
    jsr A_to_vram_XXYY

    ; vertical line on the left-hand side (22 lines, from 3rd line to last-but-one)
    lda #2
    sta .screenLineNr

-   lda .screenLineNr
    asl
    tay

    lda screenLineOffset,y  ; lb, needs to go into Y
    pha
    lda screenLineOffset+1,y    ; hb, needs to go into x
    tax
    pla
    tay
    dey ; minus 1, because line offsets are for text (which is indented 1 character)

    lda #147
    jsr A_to_vram_XXYY

    inc .screenLineNr
    lda .screenLineNr
    cmp #24
    bne -

    ; scroll-bar on the right-hand side
    ; first, arrow up
    lda #158
    ldx #0
    ldy #239
    jsr A_to_vram_XXYY

    ; scroll region
    lda #4  ; use offset from one line below and subtract 2
    sta .screenLineNr

-   lda .screenLineNr
    asl
    tay

    lda screenLineOffset,y  ; lb, needs to go into Y
    sta .tempY
    lda screenLineOffset+1,y    ; hb, needs to go into x
    sta .tempX

    sec
    lda .tempY
    sbc #2
    tay
    lda .tempX
    sbc #0
    tax

    lda #98
    jsr A_to_vram_XXYY

    inc .screenLineNr
    lda .screenLineNr
    cmp #25
    bne -

    ; arrow down on bottom of scrollbar
    lda #159
    ldx #$07
    ldy #$7f
    jsr A_to_vram_XXYY

    ; attribute-ram
    ; top, left and right border parts need to be inverted with black
    ; attribute ram ($0800)
    jsr setBlockFill

    lda #$c0    ;black foreground, charset 1 (upper/lower), reverse
    ldx #$08
    ldy #$50
    jsr A_to_vram_XXYY

    ; 79 bytes ()
    lda #79    ;lowbyte
    ldy #00    ;highbyte
    jsr vdc_do_YYAA_cycles

    ; vertical line on the left-hand side (22 lines, from 3rd line to last-but-one)
    lda #2
    sta .screenLineNr

-   lda .screenLineNr
    asl
    tay

    lda screenLineOffset,y  ; lb, needs to go into Y
    sta .tempY
    lda screenLineOffset+1,y    ; hb, needs to go into x
    sta .tempX
    
    dec .tempY
    
    clc
    lda .tempX
    adc #$08
    tax

    ldy .tempY

    lda #$c0
    jsr A_to_vram_XXYY

    inc .screenLineNr
    lda .screenLineNr
    cmp #24
    bne -

    ; vertical line on the right-hand side (22 lines, from 3rd line to last-but-one)
    lda #3
    sta .screenLineNr

-   lda .screenLineNr
    asl
    tay

    lda screenLineOffset,y  ; lb, needs to go into Y
    sta .tempY
    lda screenLineOffset+1,y    ; hb, needs to go into x
    sta .tempX
    
    sec
    lda .tempY
    sbc #2
    tay
    lda .tempX
    sbc #0
    
    clc
    ;lda .tempX
    adc #$08
    tax

    lda #$c0
    jsr A_to_vram_XXYY

    inc .screenLineNr
    lda .screenLineNr
    cmp #25
    bne -

    ; top row filled with spaces 
    jsr setBlockFill

    lda #$c3    ;charset 1 (upper/lower), color, reverse
    ldx #$08
    ldy #$00
    jsr A_to_vram_XXYY

    ; 79 bytes ()
    lda #79    ;lowbyte
    ldy #00    ;highbyte
    jsr vdc_do_YYAA_cycles

    ; bottom row
    lda #$c3    ;charset 1 (upper/lower), color, reverse
    ldx #$0f
    ldy #$80
    jsr A_to_vram_XXYY

    ; 79 bytes ()
    lda #79    ;lowbyte
    ldy #00    ;highbyte
    jmp vdc_do_YYAA_cycles

; Sectors: lastIndexed/total nr of sectors
; Buffer: firstSector / lastSector / firstline / lastline
; Screen: first line / lastline
drawStatusline
    ; set cursor to 
    +setCursorXY 0,24

    +printString .txtSector
    lda nrIndexedSectors
    ldx #0
    jsr printDecimal

    lda #'/'
    jsr printAcc

    ; print total nr of blocks
    lda fileNrBlocks
    ldx fileNrBlocks+1
    jsr printDecimal

    lda #' '
    jsr printAcc

    ; print "Lines indexed: #"
    +printString .txtLines
    lda nrIndexedSectorLines
    ldx nrIndexedSectorLines+1
    jsr printDecimal

    ; print ", buffered: x-y"
    +printString .txtBuffer
    lda firstBufferedLine
    ldx firstBufferedLine+1
    jsr printDecimal

    lda #'-'
    jsr printAcc

    lda lastBufferedLine
    ldx lastBufferedLine+1
    jsr printDecimal

    ; print ", displayed: x-y"
    +printString .txtScreen
    lda firstDisplayedLine
    ldx firstDisplayedLine+1
    jsr printDecimal
    lda #'-'
    jsr printAcc
    lda lastDisplayedLine
    ldx lastDisplayedLine+1
    jsr printDecimal

    rts

printAcc
    ldx #31
    jsr toScreencode
    jmp A_to_vdc_reg_X  ; no rts here. this is a macro, not a subroutine

printDecimal
    jsr makeItDec
    ldx #0
    stx .tempX
-   ldx .tempX
    lda decResult,x
    inx
    cpx #5
    beq +
    stx .tempX
    cmp #$30
    beq -
    +printAcc
    jmp -
+   jsr printAcc
    rts

printDirectory
    jsr home

    lda #$7f
    sta zp_directoryBank

    lda #$00
    sta .counter
    sta zp_memPtr
    lda #$04
    sta zp_memPtr+1
    lda #zp_memPtr
    sta c_fetch_zp

    ldy #0
    sty .screenLineNr

    ldy #0
-   ldx zp_directoryBank
    jsr c_fetch
    +printAcc
    iny
    
    dec .counter
    bne -
    rts

displayBuffer
    +setCursorXY 0,2

    lda #1
    sta firstDisplayedLine
    lda #0
    sta firstDisplayedLine+1
    sta lastDisplayedLine
    sta lastDisplayedLine+1

    ldx #2
    stx .screenLineNr
    ldx #0

.displayLine
    lda bufferTable,x
    sta zp_lineBufferPos
    inx
    lda bufferTable,x
    sta zp_lineBufferPos+1
    inx
    lda bufferTable,x
    sta displayLength
    inx

    stx .tempX

    cmp #0
    beq .lineFeed

.displayChar
    ldy #0
-   lda (zp_lineBufferPos),y
    iny
    sta displayValue
    jsr checkAsciiUtf8
    bcs +
    +printAcc
+   dec displayLength
    bne -

.lineFeed
    inc lastDisplayedLine
    bne +
    inc lastDisplayedLine+1

+   inc .screenLineNr
    lda .screenLineNr
    cmp #24
    beq .displayBufferDone

; set vram pointer to beginning of next line
    asl
    tay
    lda screenLineOffset,y  ; lb. needed in Y
    pha
    iny
    lda screenLineOffset,y  ; hb. needed in A
    tax
    pla
    tay
    txa
    jsr AY_to_vdc_regs_18_19

    ldx .tempX
    jmp .displayLine

.displayBufferDone
    rts


; ------------------------------------------------
; vdc library functions. taken from vdc-basic
; ------------------------------------------------
; read from vram
vram_AAYY_to_A ; read VDC RAM address AAYY into A
		jsr AY_to_vdc_regs_18_19
vram_to_A ; read VDC register 31 (VRAM data) into A
		ldx #31
vdc_reg_X_to_A ; read VDC register X into A
		stx vdc_reg
vdc_data_to_A ; read currently selected VDC register to A
		+vdc_lda
		rts

; write to vram
AY_to_vdc_regs_18_19 ; write A and Y to consecutive VDC registers 18 and 19 (VRAM address)
		ldx #18
AY_to_vdc_regs_Xp1 ; write A and Y to consecutive VDC registers X and X+1
		jsr A_to_vdc_reg_X
		tya
		inx
A_to_vdc_reg_X ; write A to VDC register X
		stx vdc_reg
A_to_vdc_data ; write A to currently selected VDC register
		+vdc_sta
		rts

A_to_vram_XXYY
		pha
		txa
		jsr AY_to_vdc_regs_18_19
		ldx #31
		pla
		jmp A_to_vdc_reg_X

setBlockFill
    ; clear BLOCK COPY register bit to get BLOCK FILL
    ldx #24
    jsr vdc_reg_X_to_A
    and #$7f
    jmp A_to_vdc_reg_X

setBlockCopy
    ; set BLOCK COPY register bit to get BLOCK COPY
    ldx #24
    jsr vdc_reg_X_to_A
    ora #128
    jmp A_to_vdc_reg_X

vdc_do_YYAA_cycles
		ldx #30	; cycle register
		stx vdc_reg
		tax	; check low byte
		beq +
			+vdc_sta	; copy/write partial page
+		tya	; check high byte
		beq +
			; copy/write whole pages
			lda #0
-				+vdc_sta
				dey
				bne -
+		rts

.screenLineNr     !byte 0
.counter    !byte 0
.lineStart  !byte 0
.tempX      !byte 0
.tempY      !byte 0

.txtOf      !text " of ",0
.txtSector  !text "Sectors indexed: ",0
.txtLines   !text "Lines indexed:",0
.txtBuffer  !text ",buffered:",0
.txtScreen  !text ",displayed:",0


displayLength !byte 0
screenLineOffset    !word   1,  81, 161, 241, 321, 401, 481, 561, 641, 721, 801, 881
                    !word 961,1041,1121,1201,1281,1361,1441,1521,1601,1681,1761,1841,1921
displayValue  !byte 0
firstDisplayedLine  !word 0
lastDisplayedLine   !word 0
