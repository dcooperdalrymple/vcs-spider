;======================
; Bugs (missiles 0 & 1)
;======================

; Constants

BUG_SIZE            = 8
BUG_BOUNDARY        = #(BUG_SIZE)
BUG_STUN_LENGTH     = 120
BUG_POINTS          = 4
BUG_HP              = 3

#if SYSTEM = NTSC
BUG_ACTIVE_COLOR    = #$CC
BUG_ACTIVE_BW_COLOR = #$0C
BUG_STUN_COLOR      = #$38
BUG_STUN_BW_COLOR   = #$08
#endif
#if SYSTEM = PAL
BUG_ACTIVE_COLOR    = #$5C
BUG_ACTIVE_BW_COLOR = #$0C
BUG_STUN_COLOR      = #$48
BUG_STUN_BW_COLOR   = #$08
#endif

#if SYSTEM = NTSC
BUG_SAMPLE_LEN      = 30
#endif
#if SYSTEM = PAL
BUG_SAMPLE_LEN      = 25
#endif
BUG_SAMPLE_C        = 3
BUG_SAMPLE_F        = 20
BUG_SAMPLE_V        = 4

BUG_COL_SAMPLE_LEN  = 1
BUG_COL_SAMPLE_C    = 8
BUG_COL_SAMPLE_F    = 8
BUG_COL_SAMPLE_V    = 3

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
    bmi .bug_reset_v

.bug_reset_h:
    and #$7f
    sta BugPosX,x

    lda Rand16
    bmi .bug_reset_h_bottom
.bug_reset_h_top:
    lda #BUG_BOUNDARY
    jmp .bug_reset_h_y
.bug_reset_h_bottom:
    lda #KERNEL_SCANLINES-SCORE_LINES-BUG_BOUNDARY
.bug_reset_h_y:
    sta BugPosY,x
    jmp .bug_reset_active

.bug_reset_v:
    and #$7f
    sta BugPosY,x

    lda Rand16
    bmi .bug_reset_v_right

.bug_reset_v_left:
    lda #BUG_BOUNDARY
    jmp .bug_reset_v_x
.bug_reset_v_right:
    lda #(KERNEL_WIDTH/2)-BUG_BOUNDARY
.bug_reset_v_x:
    sta BugPosX,x

.bug_reset_active:
    ; Set as active
    lda #0
    sta BugStunned,x

    rts

; Frame Update

BugUpdate:

    ldx #1
.bug_update_loop:
    stx Temp+0

    lda BugStunned,x
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
    ldx Temp+0

.bug_movement_x:
    ldy BugSpeed

    ; Alter X Position
    lda Temp+1
    and #%00000001

.bug_movement_x_check:
    cmp #1
    bne .bug_movement_x_right

.bug_movement_x_left:
    dec BugPosX,x
    dey
    bne .bug_movement_x_left

    jmp .bug_movement_y

.bug_movement_x_right:
    inc BugPosX,x
    dey
    bne .bug_movement_x_right

.bug_movement_y:
    ldy BugSpeed

    ; Alter Y Position
    lda Temp+1
    and #%00000010
    lsr

.bug_movement_y_check:
    cmp #1
    bne .bug_movement_y_down

.bug_movement_y_up:
    inc BugPosY,x
    dey
    bne .bug_movement_y_up

    jmp .bug_movement_boundary

.bug_movement_y_down:
    dec BugPosY,x
    dey
    bne .bug_movement_y_down

.bug_movement_boundary:
    lda BugPosX,x
    ldy BugPosY,x

.bug_movement_boundary_left:
    cmp #BUG_BOUNDARY
    bcs .bug_movement_boundary_right
    lda #BUG_BOUNDARY
    jmp .bug_movement_boundary_top

.bug_movement_boundary_right:
    cmp #(KERNEL_WIDTH/2)-BUG_BOUNDARY
    bcc .bug_movement_boundary_top
    lda #(KERNEL_WIDTH/2)-BUG_BOUNDARY

.bug_movement_boundary_top:
    cpy #BUG_BOUNDARY
    bcs .bug_movement_boundary_bottom
    ldy #BUG_BOUNDARY
    jmp .bug_movement_store

.bug_movement_boundary_bottom:
    bit FlyState
    bmi .bug_movement_boundary_bottom_fly

    cpy #KERNEL_SCANLINES-SCORE_LINES-BUG_BOUNDARY
    bcc .bug_movement_store
    ldy #KERNEL_SCANLINES-SCORE_LINES-BUG_BOUNDARY
    jmp .bug_movement_store

.bug_movement_boundary_bottom_fly:
    cpy #KERNEL_SCANLINES-SCORE_LINES-BUG_BOUNDARY-FLY_LINES
    bcc .bug_movement_store
    ldy #KERNEL_SCANLINES-SCORE_LINES-BUG_BOUNDARY-FLY_LINES

.bug_movement_store:
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

    ; Reduce players score
    lda ScoreValue
    beq .bug_collision_score_skip
    dec ScoreValue
.bug_collision_score_skip:

    ; Play collision sound
    lda #BUG_COL_SAMPLE_LEN
    sta SampleStep
    lda #BUG_COL_SAMPLE_C
    sta AUDC1
    lda #BUG_COL_SAMPLE_F
    sta AUDF1
    lda #BUG_COL_SAMPLE_V
    sta AUDV1

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
    ; Add health to player
    clc
    lda ScoreValue
    adc #BUG_HP
    bcc .bug_stun_collision_active_hp_skip
    lda #$ff
.bug_stun_collision_active_hp_skip:
    sta ScoreValue

    ; Add points to score
    clc
    lda ScoreValue+1
    adc #BUG_POINTS
    sta ScoreValue+1

    ; Reset bug
    jsr BugReset

    ; Play sample
    lda #BUG_SAMPLE_LEN
    sta SampleStep
    lda #BUG_SAMPLE_C
    sta AUDC1
    lda #BUG_SAMPLE_F
    sta AUDF1
    lda #BUG_SAMPLE_V
    sta AUDV1

    rts

; Scanline Draw

BugDrawStart:

    ldy #1
.bug_draw_start_loop:

    ; Set missile 0 & 1 to be 8 clock size
    ;lda NuSiz0,y
    ;ora #%00110000
    ;sta NuSiz0,y
    ;sta NUSIZ0,y

    ; Setup half scanline positions
    lda BugPosY,y
    lsr
    sta BugDrawPosBottom,y

    adc #BUG_SIZE/2
    sta BugDrawPosTop,y

    dey
    bpl .bug_draw_start_loop

    rts
