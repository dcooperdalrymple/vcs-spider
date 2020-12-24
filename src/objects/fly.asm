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
FLY_WIDTH = 32
FLY_LINE_SIZE = 4
FLY_LINES = #FLY_SIZE*FLY_LINE_SIZE ; 36
FLY_WEB_LINES = #FLY_SIZE*FLY_LINE_SIZE/WEB_LINE ; 6

FLY_BOUNDARY_LEFT = #4
FLY_BOUNDARY_RIGHT = #(KERNEL_WIDTH/2)-FLY_WIDTH-4

; Initialization

FlyInit:
    ;SET_POINTER FlyPtr, TitleBug
    lda #50
    sta FlyPosX
    lda #%10000000 ; 7 = direction, 8 = active
    sta FlyState
    rts

FlyUpdate:
    jsr FlyAnimation
    jsr FlyMovement
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

FlyDrawStart:
    bit FlyState
    bmi .fly_draw_start
    ;rts

.fly_draw_start:

    ; Set x pos
    lda FlyPosX
    ldx #0
    jsr PosObject
    lda FlyPosX
    clc
    adc #16
    ldx #1
    jsr PosObject

    sta WSYNC
    sta HMOVE

    ; Single sprite, double size
    lda #%00000101
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
    sta COLUP1

    ldx #FLY_LINE_SIZE
    ldy #FLY_SIZE-1
.fly_draw_line:
    lda (FlyPtr),y
    sta GRP0
    sta GRP1

.fly_draw_delay:
    dex
    sta WSYNC
    bne .fly_draw_delay

.fly_draw_index:
    ldx #FLY_LINE_SIZE
    dey
    bpl .fly_draw_line

.fly_draw_clean:
    lda #0
    sta GRP0
    sta GRP1

    ; Rest object x pos
    ldx #4
.fly_draw_pos_reset:
    lda XPositions,x
    jsr PosObject
    dex
    bpl .fly_draw_pos_reset

    ; Restore bug size
    lda #%00110101
    sta NUSIZ0
    lda #%00110111
    sta NUSIZ1

    ; Account for scanline difference
    ldx #(KERNEL_SCANLINES-SCORE_LINES-FLY_LINES)/2-2-5 ; Half scanline counter
    lda #FLY_WEB_LINES
    sta WebIndex

    ; Set final x positions
    sta WSYNC
    sta HMOVE

    rts
