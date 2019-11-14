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
