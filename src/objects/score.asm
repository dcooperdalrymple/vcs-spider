;======================
; Score (playfield)
;======================

; Constants

SCORE_BG_COLOR      = #$00
SCORE_FG_COLOR      = #$0f

SCORE_CHAR_SIZE     = 5
SCORE_LINE_SIZE     = 2
SCORE_LINES         = SCORE_CHAR_SIZE*SCORE_LINE_SIZE+3

; Initialization

ScoreInit:

    ; Reset Scores
    lda #0
    sta ScoreValue
    sta ScoreValue+1

    ; Setup frame counters
    lda #$ff
    sta FrameTimer

    rts

; Frame Update

ScoreUpdate:

    ldx FrameTimer
    dex
    cpx #1
    bne .score_update_timer_skip

    ldy ScoreValue
    iny
    sty ScoreValue

    ldx #$ff

.score_update_timer_skip:
    stx FrameTimer
    stx ScoreValue+1

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
    lda #SCORE_FG_COLOR
    sta COLUPF

    ; Set Non-Mirror
    lda #%00000000  ; Last digit to 0
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
