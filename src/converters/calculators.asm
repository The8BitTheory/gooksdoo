!zone calculators

 ; result A=lo, Y=hi
multiply
    lda #%00001110
    sta $ff00


    lda #$00
    tay
    beq .enterLoop

.doAdd:
    clc
    adc multiply16
    tax

    tya
    adc multiply16+1
    tay
    txa

.loop:
    asl multiply16
    rol multiply16+1
.enterLoop:  ; accumulating multiply entry point (enter with .A=lo, .Y=hi)
    lsr multiply8
    bcs .doAdd
    bne .loop

    rts

multiply16   !word 0
multiply8    !byte 0