!zone commonDisk

; this calls setnam first. for that it needs a=filename length, x=filename LB, y=filename HB to be set
; for setlfs, it needs "diskLoadDeviceNumber" set to call setLFS. If zero, last used device is used ($ba)
; for setbnk, it needs diskLoadDataBank and diskLoadFilenameBank to be set
; for load itself, it needs diskLoadAddress and diskLoadAddress+1 to be set

chrout = $ffd2
chkout = $ffc9  ; x=logFn, sets device for chrout

chkin = $ffc6
chrin = $ffcf

open = $ffc0
close = $ffc3

clrchn = $ffcc

setnam = $ffbd
setlfs = $ffba
setbnk = $ff68

setNamLfsBnk
    JSR setnam     ; call SETNAM

    lda diskLoadFileNr
    bne +
    LDA #$02      ; default to file number 2
    ;LDX $BA       ; last used device number
+   ldx diskLoadDeviceNr
    BNE +
    LDX #$08      ; default to device 8
+   ldy diskLoadSecAddr
    bne +
    LDY #$00      ; secondary address 0     ; 0=load to x/y address, 1=load to header address
+   JSR setlfs     ; call SETLFS

    lda diskLoadDataBank  ; bank to load data to
    ldx diskLoadFilenameBank  ; bank of filename
    jmp setbnk ; call SETBNK

openForInput
    jsr open           ; open
    bcs.error
    ldx diskLoadFileNr  
    jsr chkin           ; chkin
    bcs .error
    rts

openForOutput
    jsr open           ; open
    bcs .error
    ldx diskLoadFileNr
    jsr chkout           ;chkout
    bcs .error
    rts

printHash
    
    rts

getHash

    rts


readStatusChannel
    lda #1 ;filenr
    ldx diskLoadDeviceNr ; device
    bne +
    ldx #8
+   ldy #15 ; secondary device
    jsr setlfs   ; setLFS

    lda #0      ;kein name
    jsr setnam   ; setNAM

    jsr open ; open
    ldx #1 ;filenr
    jsr chkin ;chkin

    ldx #0
-   jsr chrin ;input
    sta diskStatus,x
    cpx #2
    bcs +
    sta .statusCode,x
+   inx
    bit $90 ;status testen
    bvc -

    jsr clrchn ;clrch
    lda #1
    jsr close ;close

    lda #<.statusCode
    sta zp_memPtr
    lda #>.statusCode
    sta zp_memPtr+1
    jsr twoCharsToDeviceNr

    rts

closeDiskFile
        bcs .error

        ; write to content address here
        ; the error page writes the correct contentAddress itself
        ;lda $ae
        ;sta zp_contentAddress
        ;lda $af
        ;sta zp_contentAddress+1

.close
        lda diskLoadFileNr
        bne +
        LDA #$02      ; filenumber 2
+       JSR close     ; call CLOSE

        JSR clrchn     ; call CLRCHN
        RTS

.error
        ; Accumulator contains BASIC error code
        sta fileOpError

        ; most likely errors:
        ; A = $05 (DEVICE NOT PRESENT)

        ; for further information, the drive error channel has to be read
        jsr readStatusChannel
        ;jsr printDiskStatus
        
        Jmp .close    ; even if OPEN failed, the file has to be closed
        ;jmp createFileNotFoundPage

.readerror
        ;... error handling for read errors ...
        sta fileOpError

        ; for further information, the drive error channel has to be read
        jsr readStatusChannel
        ;jsr printDiskStatus

        jmp .close


;printDiskStatus
;    ldx #0
;-   lda diskStatus,x
;    cmp #$0d
;    beq +
;    jsr bsout
;    inx
;    jmp -

;+   jsr bsout   ;print the CR
;    rts


fileOpError     !byte 0
diskStatus  !fill 64
.statusCode !word 0     ; st

diskLoadFileNr          !byte 0
diskLoadDeviceNr        !byte 0
diskLoadSecAddr         !byte 0
diskLoadDataBank        !byte 0
diskLoadFilenameBank    !byte 0
diskLoadAddress         !word 0     ; the address in bank "diskLoadDataBank" that's used to write the data to
