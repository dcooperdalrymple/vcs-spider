;======================
; Level Logic
;======================

; Constants

LEVELS          = 4

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
    cmp LevelDataScore,y
    bcc .level_update_return

    ; Reset score
    lda #0
    sta ScoreValue+1

    ; Check if we haven't reached the final level
    lda LevelCurrent
    cmp #LEVELS-1
    bcs .level_update_return

    inc LevelCurrent
    jsr LevelLoad

.level_update_return:

    jsr LevelLoadColor ; Always update color (for b/w support)

    rts

LevelLoad:
    ldy LevelCurrent

    ; Bug Speed
    lda LevelDataBug,y
    sta BugSpeed

    ; Swatter Wait Time
    lda LevelDataSwatterWait,y
    sta SwatterWaitTime

    ; Swatter Hit Damage
    lda LevelDataSwatterDamage,y
    sta SwatterHitDamage

    rts

LevelLoadColor:
    ldy LevelCurrent

    ; check b/w
    lda SWCHB
    REPEAT 4
    lsr
    REPEND
    bcc .level_load_bw

.level_load_color:

    ; Background Color
    lda LevelDataBk,y
    sta WebColor+0

    ; Web Color
    lda LevelDataPf,y
    sta WebColor+1

    rts

.level_load_bw:

    ; Background Color
    lda #WEB_BG_COLOR
    sta WebColor+0

    ; Web Color
    lda #WEB_FG_COLOR
    sta WebColor+1

    rts

LevelDataScore:     ; Score needed
    .BYTE #10
    .BYTE #20
    .BYTE #40
    .BYTE #99

LevelDataBk:        ; Background Color
    .BYTE #$00
    .BYTE #$60
    .BYTE #$50
    .BYTE #$30

LevelDataPf:        ; Web Color
    .BYTE #$06
    .BYTE #$64
    .BYTE #$54
    .BYTE #$34

LevelDataBug:       ; Bug Speed
    .BYTE #2
    .BYTE #3
    .BYTE #4
    .BYTE #5

LevelDataSwatterWait: ; Swatter Wait Time Min (adds random 0-128)
    .BYTE #180
    .BYTE #150
    .BYTE #120
    .BYTE #60

LevelDataSwatterDamage: ; Swatter Damage
    .BYTE #$10
    .BYTE #$18
    .BYTE #$20
    .BYTE #$40
