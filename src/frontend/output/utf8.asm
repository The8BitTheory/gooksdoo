!zone utf8

.invalidSequence
    ; set accumulator value to question mark here
    lda #$3f ; ?
    jmp .exitShow


checkAsciiUtf8
    ; check for 0xxxxxxx    -> ascii is most common. check with minimal speed impact.
    lda displayValue
    bmi +   ;set. check for utf8 sequences
    jmp .exitShow     ; not set. return unchanged

    ; valid utf-8 sequence of any length?
    ; save acc, we'll have to continue working with AND, which will overwrite the acc value
+   sta .keeper
    and #%11100000
    cmp #%11000000
    beq +
    jmp .check3ByteSeqs ; bit 5 set, must be 3 or 4 byte sequence
    
    ; c0 and c1 are invalid utf-8 sequence starters. $c2-$df are valid
+   lda displayValue
    cmp #$C0
    beq .invalidSequence
    cmp #$C1
    beq .invalidSequence
    ora #%11100000  
    cmp #%11100000  ; true for $e0 and up
    beq .invalidSequence

    jmp .autoMapToAscii

    ; decode common 2-byte sequences to ascii table entries here. 11 bits
    ; use zp_tempCalc as working variables as they are unused in copy routines
    ; acc holds parsed value. get 5 lower bits
    ; next value to read holds 6 bits. forms lower byte with 2 lower bits of current acc value
    
    ;sta .keeper
    ; read next value
    jsr .readNextSeqByte

    cmp #$84    ; Ä
    bne +
    lda #196
    jmp .exitShow

+   cmp #$9f    ; ß
    bne +
    lda #223
    jmp .exitShow

+   cmp #$a4    ; ä
    bne +
    lda #228
    jmp .exitShow

+   cmp #$b6    ; ö
    bne +
    lda #246
    jmp .exitShow

+   cmp #$bc    ; ü
    bne +
    lda #252
    jmp .exitShow

+   cmp #$96    ; Ö
    bne +
    lda #214
    jmp .exitShow

+   cmp #$9c    ; Ü
    bne .invalidSequence2Bytes
    lda #220
    jmp .exitShow


.autoMapToAscii
    jsr .readNextSeqByte
    sta zp_tempCalc

+   and #%11000000  ; follow-up byte always start with 10
    cmp #%10000000
    bne .invalidSequence2Bytes

    ; drop 2 highest bits from second byte
    asl zp_tempCalc
    asl zp_tempCalc

    lda displayValue
    ror ; lowest bit into carry
    ror zp_tempCalc ; carry into highest bit
    ror
    ror zp_tempCalc
    and #%00000111
    sta zp_tempCalc+1

    lda zp_tempCalc+1
    beq +
    jmp .invalidSequence
    
+   lda zp_tempCalc
    jmp .exitShow


.invalidSequence2Bytes
    nop
.invalidSequence3Bytes
    nop
.invalidSequence4Bytes
    jmp .invalidSequence


.check3ByteSeqs
    lda displayValue
    and #%11110000
    cmp #%11100000
    bne .check4ByteSeq   ; bit 4 set, must be 4-byte sequence
    ; decode common 3-byte sequences to ascii table entries here. 16 bits

;    sta .keeper
    jsr .readNextSeqByte
    sta .keeper+1

    cmp #$80
    beq .read3ByteSeq80
    cmp #$81
    beq .read3ByteSeq81
    jmp .invalidSequence3Bytes

.read3ByteSeq80
    ;sta .keeper
    jsr .readNextSeqByte
    sta .keeper+2

    cmp #$98
    bne +
    lda #$27    ; '
    jmp .exitShow

+   cmp #$99
    bne +
    lda #$27    ; '
    jmp .exitShow

+   cmp #$9e
    bne +
    lda #$22    ; "
    jmp .exitShow

+   cmp #$9c
    bne +
    lda #$22    ; "
    jmp .exitShow

+   cmp #$93
    bne +
    lda #$2d    ; -
    jmp .exitShow

+   cmp #$94
    bne +
    lda #$2d
    jmp .exitShow

+   cmp #$9d
    bne .invalidSequence3Bytes
    lda #$22    ; "
    jmp .exitShow
    ; $e2 80 99
    ; $e2 80 9e -> "
    ; $e2 80 9c -> "
    ; $e2 80 9d -> "

.read3ByteSeq81
    ;sta .keeper
    jsr .readNextSeqByte
    sta .keeper+2

    cmp #$a0    ; $e2 81 a0 -> &nbsp just ignore
    bne .invalidSequence3Bytes
    jmp .exitSkip
    rts

    ; bit 3 must be unset for a valid 4-byte sequence start byte
.check4ByteSeq
    lda displayValue
    and #%11111000
    cmp #%11110000
    bne .invalidSequence4Bytes    ; bit 3 set, not a valid utf-8 start byte
    ; decode common 4-byte sequences to ascii table entries here. 21 bits

    jmp .exitShow

.readNextSeqByte
    lda (zp_lineBufferPos),y
    iny
    dec displayLength
    rts

.exitShow
    clc
    rts

.exitSkip
    sec
    rts

.keeper !word 0,0
