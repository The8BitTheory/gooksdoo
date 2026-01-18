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
    ldy #.yPos
    lda screenLineOffset,y
    tay
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

printDirectory
    +setCursorXY 0,0

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
    sty .lineNr

    ldy #0
-   ldx zp_directoryBank
    jsr c_fetch
    +printAcc
    iny
    
    dec .counter
    bne -
    rts

displayLineFromCurrentSector
    lda lastDisplayedLine
    sta multiply16
    lda lastDisplayedLine+1
    sta multiply16+1
    lda #lineTableIncr      ; size of lineTable entry
    sta multiply8
    jsr multiply     ; result A=lo, Y=hi
    jsr calcZpLineTable

    ldy #3
    lda (zp_lineTable),y
    pha
    ;sta .lineStart
    
    iny
    lda (zp_lineTable),y
    tax
    ;sta .lineLength

    pla
    tay

    ;ldy .lineStart
-   lda sectorData,y
    jsr chrout
    iny
    beq +       ; y is running over. sector data is at an end
    dex
    bne -

    lda #$0d
    jsr chrout

+   rts

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


.lineNr     !byte 0
.counter    !byte 0
.lineStart  !byte 0
.lineLength !byte 0


screenLineOffset   !word   0,  80, 160, 240, 320, 400, 480, 560, 640, 720, 800, 880
                    !word 960,1040,1120,1200,1280,1360,1440,1520,1600,1680,1760,1840,1920

