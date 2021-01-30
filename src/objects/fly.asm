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

; Initialization

FlyInit:
    ;SET_POINTER FlyPtr, TitleBug
    lda #50
    sta FlyPosX
    lda #%00000000 ; 7 = direction, 8 = active
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
    lda #FLY_COLOR
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

    ldy #FLY_SIZE-1
.fly_draw_line:

    tya
    and #%00000001
    sta WSYNC
    beq .fly_draw_skip
.fly_draw_web:
    ldx WebIndex
    lda WebImagePF0,x
    sta PF0
    lda WebImagePF1,x
    sta PF1
    lda WebImagePF2,x
    sta PF2
    inc WebIndex
.fly_draw_skip:

.fly_draw_sprite:
    sta WSYNC
    lda (FlyPtr),y
    sta GRP0
    sta GRP1

    sta WSYNC
    ; Draw ball?

.fly_draw_index:
    dey
    bpl .fly_draw_line

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

    ; Account for scanline difference
    ldx #(KERNEL_SCANLINES-SCORE_LINES-FLY_LINES)/2-2-5 ; Half scanline counter
    ;lda #FLY_WEB_LINES
    ;sta WebIndex

    rts
