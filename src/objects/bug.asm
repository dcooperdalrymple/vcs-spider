;======================
; Bugs (missiles 0 & 1)
;======================

; Constants

BUG_SIZE            = 8
BUG_BOUNDARY        = BUG_SIZE
BUG_SPEED           = 2
BUG_STUN_LENGTH     = 120
BUG_POINTS          = 4

BUG_COLOR_ACTIVE    = #$CC
BUG_COLOR_STUN      = #$38

BUG_SAMPLE_LEN      = 30
BUG_SAMPLE_C        = 3
BUG_SAMPLE_F        = 20
BUG_SAMPLE_V        = 4

; Initialization

BugInit:

    ; Initialize Bugs
    ldx #1

.bug_init_loop:
    jsr BugReset

    dex
    bpl .bug_init_loop

    rts

BugReset:   ; x = bug (0 or 1)

    ; Set random position
    jsr Random

    lda Rand8
    and #$7f
    sta BugPosX,x

    lda Rand16
    and #$7f
    sta BugPosY,x

    ; Set as active
    lda #0
    sta BugStunned,x

    ; Reset Color
    lda #BUG_COLOR_ACTIVE
    sta BugColor,x

    rts

; Frame Update

BugUpdate:

    ldx #1
.bug_update_loop:
    stx Temp+0

    lda BugStunned,x
    cmp #0
    beq .bug_update_active

.bug_update_stunned:
    dec BugStunned,x
    jsr BugStunCollision
    jmp .bug_update_next

.bug_update_active:
    jsr BugMovement
    jsr BugCollision

.bug_update_next:
    ldx Temp+0
    dex
    bpl .bug_update_loop

    rts

BugMovement:

.bug_movement_random:
    jsr Random
    and #%00000011
    sta Temp+1

.bug_movement_load:
    ; Load x and y values
    ldx Temp+0
    lda BugPosX,x
    ldy BugPosY,x
    tax

.bug_movement_x:
    ; Alter X Position
    lda Temp+1
    and #%00000001

.bug_movement_x_left:
    cmp #1
    bne .bug_movement_x_right
    dex
    dex
    jmp .bug_movement_y

.bug_movement_x_right:
    inx
    inx

.bug_movement_y:
    ; Alter Y Position
    lda Temp+1
    and #%00000010
    lsr

.bug_movement_y_up:
    cmp #1
    bne .bug_movement_y_down
    iny
    iny
    jmp .bug_movement_boundary

.bug_movement_y_down:
    dey
    dey

.bug_movement_boundary:

.bug_movement_boundary_left:
    cpx #BUG_BOUNDARY
    bcs .bug_movement_boundary_right
    ldx #BUG_BOUNDARY
    jmp .bug_movement_boundary_top

.bug_movement_boundary_right:
    cpx #(KERNEL_WIDTH/2)-BUG_BOUNDARY-BUG_SIZE
    bcc .bug_movement_boundary_top
    ldx #(KERNEL_WIDTH/2)-BUG_BOUNDARY-BUG_SIZE

.bug_movement_boundary_top:
    cpy #SCORE_LINES+BUG_BOUNDARY+(BUG_SIZE*2)
    bcs .bug_movement_boundary_bottom
    ldy #SCORE_LINES+BUG_BOUNDARY+(BUG_SIZE*2)
    jmp .bug_movement_store

.bug_movement_boundary_bottom:
    cpy #KERNEL_SCANLINES-BUG_BOUNDARY-BUG_SIZE
    bcc .bug_movement_store
    ldy #KERNEL_SCANLINES-BUG_BOUNDARY-BUG_SIZE

.bug_movement_store:
    txa
    ldx Temp+0
    sta BugPosX,x
    sty BugPosY,x

.bug_movement_return:
    rts

BugCollision:

    cpx #1
    beq .bug_collision_m1

.bug_collision_m0:
    ; Collision for M0 (V set)
    bit CXM0P
    bvs .bug_collision_active
    rts

.bug_collision_m1:
    ; Collision for M1 (N set)
    bit CXM1P
    bmi .bug_collision_active
    rts

.bug_collision_active:
    dec ScoreValue
    rts

BugStunCollision:

    cpx #1
    beq .bug_stun_collision_m1

.bug_stun_collision_m0:
    ; Collision for M0 (V set)
    bit CXM0P
    bvs .bug_stun_collision_active
    rts

.bug_stun_collision_m1:
    ; Collision for M1 (N set)
    bit CXM1P
    bmi .bug_stun_collision_active
    rts

.bug_stun_collision_active:
    ; Add points to score
    clc
    lda ScoreValue+1
    adc #BUG_POINTS
    sta ScoreValue+1

    ; Reset bug
    jsr BugReset

    ; Play sample
    jsr BugSample

    rts

; Horizontal Positioning

BugPosition:

    ; Set Position of each missile
    ldy #1
.bug_position:

    ; Determine missile index
    clc
    ldx #2          ; Missile 0/1
    tya
    sta Temp
    txa
    adc Temp
    tax

    lda BugPosX,y
    jsr PosObject

    dey
    bpl .bug_position

    rts

; Scanline Draw

BugDrawStart:

    ; Set missile 0 to be 4 clock size
    lda NuSiz0
    ora #%00110000
    sta NuSiz0
    sta NUSIZ0

    ; Set missile 1 to be 4 clock size
    lda NuSiz1
    ora #%00110000
    sta NuSiz1
    sta NUSIZ1

    ; Setup half scanline positions
    ldy #1
.bug_draw_start_pos:
    lda BugPosY,y
    lsr
    sta BugDrawPosBottom,y

    adc #BUG_SIZE/2
    sta BugDrawPosTop,y

    dey
    bpl .bug_draw_start_pos

    rts

BugDraw:

    ; Load half scanline
;    lda Temp+1

.bug_draw_0:
    ldy #%00000000

    ; Check top and bottom y pos
    cmp BugDrawPosTop+0
    bcs .bug_draw_0_off

    cmp BugDrawPosBottom+0
    bcc .bug_draw_0_off

.bug_draw_0_on:
    ldy #%00000010

.bug_draw_0_off:
    sty ENAM0

.bug_draw_1:
    ldy #%00000000

    ; Check top and bottom y pos
    cmp BugDrawPosTop+1
    bcs .bug_draw_1_off

    cmp BugDrawPosBottom+1
    bcc .bug_draw_1_off

.bug_draw_1_on:
    ldy #%00000010

.bug_draw_1_off:
    sty ENAM1

.bug_draw_return:
    rts

BugClean:
    lda #0
    sta ENAM0
    sta ENAM1
    rts

BugSample:
    lda #BUG_SAMPLE_LEN
    sta SampleStep
    lda #BUG_SAMPLE_C
    sta AUDC1
    lda #BUG_SAMPLE_F
    sta AUDF1
    lda #BUG_SAMPLE_V
    sta AUDV1
    rts
