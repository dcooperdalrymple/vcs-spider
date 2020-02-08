;======================
; Level Logic
;======================

; Constants

LEVEL_MIN       = 0
LEVEL_MAX       = 3

LevelInit:

    ; Set beginning level by difficulty switches treated as binary
    lda SWCHB
    REPEAT 6
    lsr
    REPEND
    and #%00000011
    sta LevelCurrent

    jsr LevelLoad

    rts

LevelUpdate:

    ; Check if score is high enough
    ldy LevelCurrent
    lda ScoreValue+1
    cmp LevelVars+0,y
    bcc .level_update_return

    ; Check if we haven't reached the final level
    lda LevelCurrent
    cmp #LEVEL_MAX
    bcs .level_update_return

    inc LevelCurrent
    jsr LevelLoad

.level_update_return:
    rts

LevelLoad:
    ldy LevelCurrent

    ; Background Color
    lda LevelVars+4,y
    sta WebColor+0

    ; Web Color
    lda LevelVars+8,y
    sta WebColor+1

    rts

LevelVars:

    ; Score needed
    .BYTE #$10
    .BYTE #$20
    .BYTE #$40
    .BYTE #$FF

    ; Background Color
    .BYTE #$00
    .BYTE #$60
    .BYTE #$50
    .BYTE #$30

    ; Web Color
    .BYTE #$06
    .BYTE #$64
    .BYTE #$54
    .BYTE #$34

    ; Bug Speed

    ; Swatter Wait

    ; Swatter Damage
