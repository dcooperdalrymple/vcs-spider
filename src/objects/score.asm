;======================
; Score (playfield)
;======================

; Constants

SCORE_BG_COLOR      = #$00
SCORE_FG_0_COLOR    = #$44
SCORE_FG_1_COLOR    = #$C8

SCORE_CHAR_SIZE     = 5
SCORE_LINE_SIZE     = 2
SCORE_LINES         = SCORE_CHAR_SIZE*SCORE_LINE_SIZE+3

; Initialization

ScoreInit:

    ; Health Score
    lda #$FF
    sta ScoreValue+0

    ; Game Score
    lda #0
    sta ScoreValue+1

    rts

; Frame Update

ScoreUpdate:

    ldx #1
.score_update_loop:

    ; Ones Digit
    lda ScoreValue,x
    and #$0f
    sta Temp
    asl
    asl
    adc Temp
    sta ScoreDigitOnes,x

    ; Tens Digit
    lda ScoreValue,x
    and #$f0
    lsr
    lsr
    sta Temp
    lsr
    lsr
    adc Temp
    sta ScoreDigitTens,x

    dex
    bpl .score_update_loop

.score_update_end:
    rts

; Draw loop (uses SCORE_LINES scanlines)

ScoreDraw:

    ; Load Colors
    lda #SCORE_BG_COLOR
    sta COLUBK
    lda #SCORE_FG_0_COLOR
    sta COLUPF
    sta COLUP0
    lda #SCORE_FG_1_COLOR
    sta COLUP1

    ; Set Non-Mirror and p0/p1 color
    lda CtrlPf
    and #%11111100
    ora #%00000010
    sta CtrlPf
    sta CTRLPF

    ;sta WSYNC

    ldx #SCORE_CHAR_SIZE

.score_draw_line:

    ; 1st Value
    ldy ScoreDigitTens
    lda ScoreDigits,y
    and #$f0
    sta ScoreGfx
    ldy ScoreDigitOnes
    lda ScoreDigits,y
    and #$0f
    ora ScoreGfx
    sta ScoreGfx

    sta WSYNC
    sta PF1

    ; 2nd Value
    ldy ScoreDigitTens+1
    lda ScoreDigits,y
    and #$f0
    sta ScoreGfx+1
    ldy ScoreDigitOnes+1
    lda ScoreDigits,y
    and #$0f
    ora ScoreGfx+1
    sta ScoreGfx+1

    sleep 12
    sta PF1

    ldy ScoreGfx
    sta WSYNC

    sty PF1

    inc ScoreDigitOnes
    inc ScoreDigitOnes+1
    inc ScoreDigitTens
    inc ScoreDigitTens+1

    sleep 12
    dex
    sta PF1

    bne .score_draw_line
    sta WSYNC

    ; Clear
    lda #0
    sta PF1

    sta WSYNC

    rts

    include "objects/score_digits.asm"
