;======================
; Level Logic
;======================

; Constants

LEVELS          = 19

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

    ; Calculate Desired score: (level+2)*5
    lda LevelCurrent
    clc
    adc #2 ; +2
    sta Temp
    asl ; x2
    asl ; x2
    adc Temp ; x1

    ; Check if score is high enough
    cmp ScoreValue+1
    bcs .level_update_return

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

    ; Bug Speed: level/4+2
    lda LevelCurrent
    lsr ; /2
    lsr ; /2
    adc #2
    sta BugSpeed

    ; Swatter Wait Time Min (adds random 0-128): (20-level)*10
    lda #20
    clc
    sbc LevelCurrent
    asl ; x2
    sta Temp
    asl ; x2
    asl ; x2
    adc Temp
    sta SwatterWaitTime

    ; Swatter Hit Damage: level*3+$10
    lda LevelCurrent
    clc
    sta Temp
    asl ; x2
    adc Temp
    adc #$10
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

    ; Easy: 1-5
    ; Medium: 6-9
    ; Hard: 10-15
    ; Extreme: 16-19

LevelDataBk:        ; Background Color
    .BYTE #$00      ; rgb(0, 0, 0)      Easy
    .BYTE #$D0      ; rgb(0, 21, 1)
    .BYTE #$A0      ; rgb(0, 31, 2) *
    .BYTE #$C0      ; rgb(0, 33, 2)
    .BYTE #$B0      ; rgb(0, 36, 3)
    .BYTE #$90      ; rgb(0, 16, 58)    Medium
    .BYTE #$80      ; rgb(0, 0, 114)
    .BYTE #$60      ; rgb(13, 0, 130)
    .BYTE #$50      ; rgb(45, 0, 74)
    .BYTE #$10      ; rgb(25, 2, 0)     Hard
    .BYTE #$E0      ; rgb(26, 2, 0)
    .BYTE #$20      ; rgb(55, 0, 0)
    .BYTE #$F0      ; rgb(56, 0, 0)
    .BYTE #$40      ; rgb(68, 0, 8)
    .BYTE #$30      ; rgb(71, 0, 0)
    .BYTE #$50      ; rgb(45, 0, 74)    Extreme
    .BYTE #$50      ; rgb(45, 0, 74)
    .BYTE #$00      ; rgb(0, 0, 0)
    .BYTE #$00      ; rgb(0, 0, 0)

LevelDataPf:        ; Web Color
    .BYTE #$06      ; rgb(91, 91, 91)   Easy
    .BYTE #$D4      ; rgb(48, 89, 0)
    .BYTE #$C4      ; rgb(8, 107, 0)
    .BYTE #$B4      ; rgb(0, 112, 12)
    .BYTE #$A4      ; rgb(0, 105, 87)
    .BYTE #$92      ; rgb(0, 49, 110)   Medium
    .BYTE #$84      ; rgb(3, 60, 214)
    .BYTE #$94      ; rgb(0, 85, 162)
    .BYTE #$64      ; rgb(85, 15, 201)
    .BYTE #$22      ; rgb(94, 8, 0)     Hard
    .BYTE #$32      ; rgb(115, 0, 0)
    .BYTE #$42      ; rgb(111, 0, 31)
    .BYTE #$44      ; rgb(150, 6, 64)
    .BYTE #$34      ; rgb(152, 19, 0)
    .BYTE #$24      ; rgb(131, 39, 0)
    .BYTE #$54      ; rgb(125, 5, 140)  Extreme
    .BYTE #$56      ; rgb(161, 34, 177)
    .BYTE #$08      ; rgb(126, 126, 126)
    .BYTE #$0A      ; rgb(162, 162, 162)
