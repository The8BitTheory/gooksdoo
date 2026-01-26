!zone initVdcText

initVdcTextmode
    jsr loadCharsetFromDisk

    ; arguments: ram-source, vram-target, nr of characters to copy
    ; copy from 45056 ($b000) to $3000 in vram, copy 256 bytes
+   lda #$00
    sta arg1  
    sta arg2
    lda #$b0
    sta arg1+1

    lda #$30
    sta arg2+1

    lda #$00
    sta arg3
    lda #$01
    sta arg3+1

    jsr doSlow
    jsr .vcc
    jsr .setColors
    jmp doFast

.setColors
    ; light grey background
    lda #$0f    ;light grey background
    ldx #26
    jsr A_to_vdc_reg_X

    rts


; arguments: ram-source, vram-target, nr of characters to copy
.vcc ; copy charset from RAM to VRAM
    ;jsr remember_mem_conf
    ; get low byte of RAM pointer into Y and clear base pointer's low byte instead
    ldy arg1
    ldx #0
    stx arg1
---     ; set VRAM pointer
      ldx #18
      lda arg2 + 1
      stx vdc_reg
      sta vdc_data
      inx
      lda arg2
      stx vdc_reg
      sta vdc_data
      ldx #31 ; prepare VRAM access
      stx vdc_reg
      ; prepare target address for next iteration
      clc
      adc #16
      sta arg2
      bcc +
        inc arg2 + 1
+     ; set loop counter (TODO - make bytes per character an optional parameter?)
      lda #8  ; character size
      sta arg3 + 1
      ldx #0  ; ROMs and I/O
      ; loop to copy a single character pattern
--        ; read byte from RAM
        sta $ff01 ; full RAM (A is dummy)
        lda (arg1), y
        ; increment RAM pointer
        iny
        beq .fix_hi
.back       ; write byte to VRAM
        stx $ff00 ; ROMs and I/O
        +vdc_sta
        ; check whether done with this char
        dec arg3 + 1
        bne --
        lda #0
        +vdc_sta
      ; all characters done?
      dec arg3
      bne ---
      rts

.fix_hi
    inc arg1 + 1
    jmp .back

