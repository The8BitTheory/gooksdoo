toScreencode
    cmp #64 ;A  
    bmi .screencodeDone       ; < A (so, must be a digit. don't change)

    cmp #96 ;a  ; < a (so, must be an uppercase letter. subtract 64
    bpl +
    sec
    sbc #64
    jmp .screencodeDone

+   cmp #127 ; <z (so, must be a lowercase letter)
    bpl .screencodeDone
    sec
    sbc #32

.screencodeDone
    rts


twoCharsToDeviceNr
    lda #2
    sta .nrBytes
+   dec .nrBytes    ; convert into index. last index (or only) is single digit, next index (if existing) is 10s
    ldy .nrBytes
    lda (zp_memPtr),y     ; eg $38 for 8
    sec
    sbc #$30
    bmi .invalidPort
    sta .deviceNr
    dey
    bmi .portToDeviceNrDone1Digit
    lda (zp_memPtr),y     ; eg $31 for 1
    sec
    sbc #$30
    bmi .invalidPort
    beq .portToDeviceNrDone2Digits
    tax
    lda #0
-   clc
    adc #10
    dex
    beq .portToDeviceNrDone2Digits
    jmp -


.portToDeviceNrDone2Digits
    clc
    adc .deviceNr
.portToDeviceNrDone1Digit
    sta deviceNumber
    rts

.invalidPort
    rts

.nrBytes        !byte 0     ; used for converting port to device nr
.deviceNr       !byte 0     ; temporary value. if successful, written to deviceNumber
.deviceKey      !text "device",$9,$0