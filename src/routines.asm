;=======================================
; Global Kernel Subroutines
;=======================================

;=======================================
; PosObject
; ---------
; A - holds the X position of the object
; X - holds which object to position
;   0 = player0
;   1 = player1
;   2 = missile0
;   3 = missile1
;   4 = Ball
;=======================================

PosObject:
    sec
    sta WSYNC
.posobject_divide_loop:
    sbc #15
    bcs .posobject_divide_loop
    eor #7
    REPEAT 4
        asl
    REPEND
    sta.wx HMP0,x
    sta RESP0,x
    rts

;=======================================
; Random
; ---------
; Uses: A
; Sets 16-bit number in Rand8/16
; Returns: A
;
; Sourced from https://www.randomterrain.com/atari-2600-lets-make-a-game-spiceware-10.html
;=======================================

Random:
    lda Rand8
    lsr
    rol Rand16
    bcc .random_noeor
    eor #$B4
.random_noeor:
    sta Rand8
    eor Rand16
    rts

;=======================================
; BinBcdConvert
; ---------
; Input: A
; Uses: A,X,Y,Temp0/1/2
; Converts binary value to decimal value (BCD)
; Returns X,Y
; Sourced from http://www.6502.org/source/integers/hex2dec-more.htm
;=======================================

BinBcdConvert:
    sta Temp+0

    clc
    sed                 ; Switch to decimal mode

    lda #0              ; Clear result
    sta Temp+1
    sta Temp+2

    ldx #8              ; Number of source bits
.bin_bcd_convert_bit:
    asl Temp+0          ; Shift out one bit

    lda Temp+1          ; And add into result
    adc Temp+1
    sta Temp+1

    lda Temp+2          ; Propagating any carry
    adc Temp+2
    sta Temp+2

    dex                 ; Repeat for next bit
    bne .bin_bcd_convert_bit

    cld                 ; Back to binary

    ldx Temp+1          ; Load result into registers
    ldy Temp+2

    rts
