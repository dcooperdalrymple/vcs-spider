;======================
; Score (playfield)
;======================

; Constants

SCORE_BG_COLOR      = #$00
SCORE_LABEL_COLOR   = #$0f
SCORE_LEVEL_COLOR   = #$44
SCORE_HEALTH_COLOR  = #$C8

SCORE_LABEL_SIZE    = 5
SCORE_DIGIT_SIZE    = 5
SCORE_LINE_SIZE     = 2
SCORE_LINES         = SCORE_LABEL_SIZE+1+SCORE_DIGIT_SIZE*SCORE_LINE_SIZE+3

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

    ; Current Level Digit
    lda LevelCurrent
    clc
    adc #1
    and #$0f
    sta Temp
    asl
    asl
    adc Temp
    sta ScoreDigitOnes

    ; Health Bar
    lda ScoreValue+0
    beq .score_update_bar_empty

    REPEAT 4
    lsr
    REPEND
    cmp #8
    bcs .score_update_bar_top

.score_update_bar_bottom:
    tax
    lda ScoreBar,x
    ldy #$00
    jmp .score_update_bar_store

.score_update_bar_top:
    and #%00000111
    tax
    lda #$ff
    ldy ScoreBarFlip,x
    jmp .score_update_bar_store

.score_update_bar_empty:
    lda #0
    ldy #0

.score_update_bar_store:
    sta ScoreBarGfx+0
    sty ScoreBarGfx+1

.score_update_end:
    rts

; Draw loop (uses SCORE_LINES scanlines)

ScoreDraw:

    ; Load Colors
    lda #SCORE_BG_COLOR
    sta COLUBK
    lda #SCORE_LABEL_COLOR
    sta COLUPF
    sta COLUP0
    sta COLUP1

    ; Set Non-Mirror
    lda CtrlPf
    and #%11111100
    ora #%00000010
    sta CtrlPf
    sta CTRLPF

    sta WSYNC

    ldx #SCORE_LABEL_SIZE-1
.score_draw_label:
    lda ScoreLevel,x
    ldy ScoreHealth,x

    sta PF1
    sleep 28
    sty PF1

    dex
    sta WSYNC
    bpl .score_draw_label

    ; Clear labels and setup color
    lda #0
    sta PF1
    sta WSYNC

    lda #SCORE_LEVEL_COLOR
    sta COLUPF
    sta COLUP0
    lda #SCORE_HEALTH_COLOR
    sta COLUP1

    sta WSYNC

    ldx #SCORE_DIGIT_SIZE
.score_draw_digit:

    ldy ScoreDigitOnes
    lda ScoreDigits,y
    and #$f0
    sta ScoreDigitGfx
    ldy #0

    sta WSYNC
    sta PF1
    sty PF2

    lda ScoreBarGfx+0
    ldy ScoreBarGfx+1
    sleep 30
    sta PF1
    sty PF2

    lda ScoreDigitGfx
    ldy #0
    sta WSYNC
    sta PF1
    sty PF2

    inc ScoreDigitOnes

    lda ScoreBarGfx+0
    ldy ScoreBarGfx+1
    sleep 28
    sta PF1
    sty PF2

    dex
    bne .score_draw_digit

    lda #0
    sta WSYNC
    sta PF1
    sta PF2

    rts

ScoreBar:
    .BYTE #%10000000
    .BYTE #%11000000
    .BYTE #%11100000
    .BYTE #%11110000
    .BYTE #%11111000
    .BYTE #%11111100
    .BYTE #%11111110
    .BYTE #%11111111

ScoreBarFlip:
    .BYTE #%00000001
    .BYTE #%00000011
    .BYTE #%00000111
    .BYTE #%00001111
    .BYTE #%00011111
    .BYTE #%00111111
    .BYTE #%01111111
    .BYTE #%11111111

    include "objects/score_digits.asm"
    include "objects/score_level.asm"
    include "objects/score_health.asm"
