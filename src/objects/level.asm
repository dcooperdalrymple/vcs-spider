;======================
; Level Logic
;======================

; Constants

LEVELS          = 20

LevelInit:

    ; Set beginning level by difficulty switches treated as binary
    lda SWCHB
    REPEAT 6 ; shift to 0-3
    lsr
    REPEND
    clc ; multiply by 5
    sta Temp
    asl
    asl
    adc Temp
    sta LevelCurrent

    jsr LevelLoad

    rts

LevelUpdate:

    ; Calculate Desired score: level*4+23
    lda LevelCurrent
    asl ; x2
    asl ; x2
    adc #23 ; +23

    ; Check if score is high enough
    cmp ScoreValue+1
    bcs .level_update_return

    ; Check if we haven't reached the final level
    lda LevelCurrent
    cmp #LEVELS-1
    bcc .level_update_next

    ; Force score to 99
    lda #99
    sta ScoreValue+1

    ; Show Win Screen
    sec ; Define win
    jsr OverInit
    rts

.level_update_next:

    ; Reset score
    lda #0
    sta ScoreValue+1

    inc LevelCurrent
    jsr LevelLoad

.level_update_return:

    jsr LevelLoadColor ; Always update color (for b/w support)

    rts

LevelLoad:

    ; Game Audio Step: 9-(level/4)
    lda LevelCurrent
    lsr ; /2
    lsr ; /2
    sta Temp
    lda #GAME_AUDIO_STEP+1
    clc
    sbc Temp
    sta GameAudioStep

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

    ; Swatter Hold Time: 60-(level*2)

    lda LevelCurrent
    asl ; x2
    sta Temp
    lda #60
    clc
    sbc Temp
    sta SwatterHoldTime

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
    and #%00001000
    beq .level_load_bw

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

#if SYSTEM = NTSC
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
    .BYTE #$08      ; rgb(126, 126, 126)
    .BYTE #$0A      ; rgb(162, 162, 162)
    .BYTE #$0C      ; rgb(199, 199, 199)
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
    .BYTE #$52      ; rgb(87, 0, 103)  Extreme
    .BYTE #$54      ; rgb(125, 5, 140)
    .BYTE #$00      ; rgb(0, 0, 0)
    .BYTE #$00      ; rgb(0, 0, 0)
    .BYTE #$00      ; rgb(0, 0, 0)
#endif
#if SYSTEM = PAL
LevelDataBk:        ; Background Color
    .BYTE #$00      ; rgb(0, 0, 0)      Easy
    .BYTE #$30      ; rgb(0, 21, 1)
    .BYTE #$90      ; rgb(0, 31, 2) *
    .BYTE #$50      ; rgb(0, 33, 2)
    .BYTE #$70      ; rgb(0, 36, 3)
    .BYTE #$B0      ; rgb(0, 16, 58)    Medium
    .BYTE #$80      ; rgb(0, 0, 114)
    .BYTE #$D0      ; rgb(13, 0, 130)
    .BYTE #$80      ; rgb(45, 0, 74)
    .BYTE #$20      ; rgb(25, 2, 0)     Hard
    .BYTE #$20      ; rgb(26, 2, 0)
    .BYTE #$20      ; rgb(55, 0, 0)
    .BYTE #$20      ; rgb(56, 0, 0)
    .BYTE #$60      ; rgb(68, 0, 8)
    .BYTE #$40      ; rgb(71, 0, 0)
    .BYTE #$80      ; rgb(45, 0, 74)    Extreme
    .BYTE #$80      ; rgb(45, 0, 74)
    .BYTE #$08      ; rgb(126, 126, 126)
    .BYTE #$0A      ; rgb(162, 162, 162)
    .BYTE #$0C      ; rgb(199, 199, 199)
LevelDataPf:        ; Web Color
    .BYTE #$06      ; rgb(91, 91, 91)   Easy
    .BYTE #$34      ; rgb(48, 89, 0)
    .BYTE #$54      ; rgb(8, 107, 0)
    .BYTE #$74      ; rgb(0, 112, 12)
    .BYTE #$94      ; rgb(0, 105, 87)
    .BYTE #$B2      ; rgb(0, 49, 110)   Medium
    .BYTE #$D4      ; rgb(3, 60, 214)
    .BYTE #$B4      ; rgb(0, 85, 162)
    .BYTE #$A4      ; rgb(85, 15, 201)
    .BYTE #$22      ; rgb(94, 8, 0)     Hard
    .BYTE #$42      ; rgb(115, 0, 0)
    .BYTE #$62      ; rgb(111, 0, 31)
    .BYTE #$64      ; rgb(150, 6, 64)
    .BYTE #$44      ; rgb(152, 19, 0)
    .BYTE #$24      ; rgb(131, 39, 0)
    .BYTE #$82      ; rgb(87, 0, 103)  Extreme
    .BYTE #$84      ; rgb(125, 5, 140)
    .BYTE #$00      ; rgb(0, 0, 0)
    .BYTE #$00      ; rgb(0, 0, 0)
    .BYTE #$00      ; rgb(0, 0, 0)
#endif
