;======================
; Fly
;======================

#if SYSTEM = NTSC
FLY_COLOR = #$56
#endif
#if SYSTEM = PAL
FLY_COLOR = #$86
#endif
FLY_BW_COLOR = #$0E

FLY_SIZE = 9
FLY_WIDTH = 16
FLY_LINE_SIZE = #WEB_LINE/2
FLY_LINES = #FLY_SIZE*FLY_LINE_SIZE ; 36
FLY_WEB_LINES = #FLY_SIZE*FLY_LINE_SIZE/WEB_LINE ; 6

FLY_BOUNDARY_LEFT = #4
FLY_BOUNDARY_RIGHT = #(KERNEL_WIDTH/2)-FLY_WIDTH-4

FLY_SCORE_HIT = #2
FLY_SCORE_DESTROY = #16
FLY_HEALTH = #64

; Initialization

FlyInit:
    ;SET_POINTER FlyPtr, TitleBug
    lda #50
    sta FlyPosX
    lda #%00000000 ; 7 = direction, 8 = active, 0-1 = health
    sta FlyState
    rts

FlyUpdate:
    bit FlyState
    bpl .fly_update_return

    jsr FlyAnimation
    jsr FlyMovement
    jsr FlyPosition

.fly_update_return:
    rts

FlyAnimation:
    lda AudioStep
    and #%00000001
    beq .fly_animation_2
.fly_animation_1:
    SET_POINTER FlyPtr, TitleBug
    rts
.fly_animation_2:
    SET_POINTER FlyPtr, TitleBug+#FLY_SIZE
    rts

FlyMovement:
    bit FlyState
    bvs .fly_movement_right
.fly_movement_left:
    dec FlyPosX
    jmp .fly_movement_boundary
.fly_movement_right:
    inc FlyPosX

.fly_movement_boundary:
    lda FlyPosX
.fly_movement_boundary_left:
    cmp #FLY_BOUNDARY_LEFT
    bcs .fly_movement_boundary_right

    lda FlyState
    ora #%01000000
    sta FlyState

    rts

.fly_movement_boundary_right:
    cmp #FLY_BOUNDARY_RIGHT
    bcc .fly_movement_return

    lda FlyState
    and #%10111111
    sta FlyState

.fly_movement_return:
    rts

FlyPosition:
    lda FlyPosX
    clc
    adc #FLY_WIDTH/2
    sta FlyPosX+1

    ldx #1
.fly_position_loop:
    lda XPositions,x
    sta FlyPosXBackup,x
    lda FlyPosX,x
    sta XPositions,x
    dex
    bpl .fly_position_loop

    rts

FlyDrawStart:
    bit FlyState
    bmi .fly_draw_start
    rts

.fly_draw_start:

    ; Single sprite, double size
    lda #%00000000
    sta NUSIZ0
    sta NUSIZ1

    ; No reflect P0
    lda #0
    sta REFP0
    ; Reflect P1
    lda #$FF
    sta REFP1

    ; Check b/w
    lda SWCHB
    and #%00001000
    beq .fly_draw_bw
.fly_draw_color:
    lda FlyState
    and #%00000011
    tay
    lda FlyColors,y
    jmp .fly_draw_color_set
.fly_draw_bw:
    lda #FLY_BW_COLOR
.fly_draw_color_set:
    sta COLUP0
    sta COLUP1

    sta WSYNC
    ; Load background colors
    lda WebColor+0
    sta COLUBK
    lda WebColor+1
    sta COLUPF

    lda #FLY_SIZE-1
    sta Temp+3
.fly_draw_routine:

    ; Alternate between line and web
    and #%00000001
    sta WSYNC
    beq .fly_draw_line
.fly_draw_web:
    ldy WebIndex
    lda WebImagePF0,y
    sta PF0
    lda WebImagePF1,y
    sta PF1
    lda WebImagePF2,y
    sta PF2
    inc WebIndex
    jmp .fly_draw_sprite

.fly_draw_line:
    lda #%00000010 ; Default on
    cpx LineDrawPos+1 ; Top
    bcs .fly_draw_line_off
    cpx LineDrawPos+0 ; Bottom
    bcc .fly_draw_line_off
    jmp .fly_draw_line_set
.fly_draw_line_off:
    lda #%00000000
.fly_draw_line_set:
    sta ENABL

.fly_draw_sprite:
    sta WSYNC
    ldy Temp+3
    lda (FlyPtr),y
    sta GRP0
    sta GRP1

    dex
    sta WSYNC

.fly_draw_index:
    dec Temp+3
    lda Temp+3
    bpl .fly_draw_routine

.fly_draw_clean:
    ; Turn off sprites
    lda #0
    sta GRP0
    sta GRP1

    ; Restore bug size
    lda #%00110101
    sta NUSIZ0
    lda #%00110111
    sta NUSIZ1

    ; Restore player colors
    lda SpiderColor
    sta COLUP0
    lda SwatterColor
    sta COLUP1

    ; Backup scanline counter
    stx Temp+3

    ; Rest object x pos
    ldx #1
.fly_draw_pos_backup:
    lda FlyPosXBackup,x
    sta XPositions,x
    dex
    bpl .fly_draw_pos_backup

    sta HMCLR
    ldx #1
.fly_draw_pos_reset:
    lda XPositions,x
    jsr PosObject
    dex
    bpl .fly_draw_pos_reset

    ; Set final x positions
    sta WSYNC
    sta HMOVE

    ; Check Collision for fly damage
    jsr FlyDamage

    ; Restore scanline counter
    ldx Temp+3
    dex ; Account for scanline difference

    rts

FlyDamage:
    ; Check Collision
    bit CXP0FB
    bvs .fly_damage_do
    bit CXP1FB
    bvc .fly_damage_return
    
.fly_damage_do:

    ; Disable Line
    jsr LineDisable

    ; Reduce damage or destroy
    lda FlyState
    and #%00000011
    beq .fly_damage_destroy
    dec FlyState ; Damage

    ; Add points to score
    clc
    lda ScoreValue+1
    adc #FLY_SCORE_HIT
    sta ScoreValue+1

    jmp .fly_damage_return

.fly_damage_destroy:
    lda #0
    sta FlyState

    ; Add to health
    clc
    lda ScoreValue
    adc #FLY_HEALTH
    bcc .fly_damage_hp_skip
    lda #$ff
.fly_damage_hp_skip:
    sta ScoreValue

    ; Add points to score
    clc
    lda ScoreValue+1
    adc #FLY_SCORE_DESTROY
    sta ScoreValue+1

.fly_damage_return:
    sta CXCLR ; Reset Collisions
    rts

FlyColors:
#if SYSTEM = NTSC
    .BYTE #$26
    .BYTE #$36
    .BYTE #$46
#endif
#if SYSTEM = PAL
    .BYTE #$26
    .BYTE #$46
    .BYTE #$66
#endif
    .BYTE #FLY_COLOR
