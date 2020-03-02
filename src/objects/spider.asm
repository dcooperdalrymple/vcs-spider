;=================
; Spider (player0)
;=================

; Constants

SPIDER_COLOR        = #$56
SPIDER_BW_COLOR     = #$0E
SPIDER_COL_COLOR    = #$44
SPIDER_COL_BW_COLOR = #$08

SPIDER_SPRITE_SIZE  = 16
SPIDER_SIZE         = #SPIDER_SPRITE_SIZE
SPIDER_VEL_X        = 2
SPIDER_VEL_Y        = 2

; Initialization

SpiderInit:

    ; Initialize Position in center of screen
    lda #(KERNEL_WIDTH/4)-SPIDER_SIZE-1
    sta SpiderPosX
    lda #(KERNEL_SCANLINES-SCORE_LINES)/2-SPIDER_SIZE-1
    sta SpiderPosY

    ; Initial direction
    lda #%00010000
    sta SpiderCtrl

    ; Setup Sprite
    SET_POINTER SpiderPtr, SpiderSprite

    rts

; Frame Update

SpiderUpdate:

SpiderControl:

    ; Control Position
    ldx SpiderPosX
    ldy SpiderPosY
    lda SWCHA

.spider_control_check_right:
    bmi .spider_control_check_left

    REPEAT #SPIDER_VEL_X
    inx
    REPEND

.spider_control_check_left:
    rol
    bmi .spider_control_check_down

    REPEAT #SPIDER_VEL_X
    dex
    REPEND

.spider_control_check_down:
    rol
    bmi .spider_control_check_up

    REPEAT #SPIDER_VEL_Y
    dey
    REPEND

.spider_control_check_up:
    rol
    bmi .spider_control_sprite

    REPEAT #SPIDER_VEL_Y
    iny
    REPEND

.spider_control_sprite:
    ; Control Sprite
    lda #%00000000
    ; 7th bit: right
    ; 6th bit: left
    ; 5th bit: down
    ; 4th bit: up

.spider_control_sprite_x:
    cpx SpiderPosX
    bcc .spider_control_sprite_left
    beq .spider_control_sprite_y
    bcs .spider_control_sprite_right

.spider_control_sprite_left:
    ora #%01000000
    jmp .spider_control_sprite_y

.spider_control_sprite_right:
    ora #%10000000

.spider_control_sprite_y:
    cpy SpiderPosY
    bcc .spider_control_sprite_down
    beq .spider_control_sprite_store
    bcs .spider_control_sprite_up

.spider_control_sprite_down:
    ora #%00100000
    jmp .spider_control_sprite_store

.spider_control_sprite_up:
    ora #%00010000

.spider_control_sprite_store:
    cmp #%00000000
    beq .spider_control_boundary
    sta SpiderCtrl

.spider_control_boundary:
    ; Check Playfield Boundaries

.spider_control_boundary_left:
    cpx #SPIDER_VEL_X
    bcs .spider_control_boundary_right
    ldx #SPIDER_VEL_X
    jmp .spider_control_boundary_top

.spider_control_boundary_right:
    cpx #(KERNEL_WIDTH/2)-SPIDER_SIZE-SPIDER_VEL_X
    bcc .spider_control_boundary_top
    ldx #(KERNEL_WIDTH/2)-SPIDER_SIZE-SPIDER_VEL_X

.spider_control_boundary_top:
    cpy #SPIDER_VEL_Y+2
    bcs .spider_control_boundary_bottom
    ldy #SPIDER_VEL_Y+2
    jmp .spider_control_store

.spider_control_boundary_bottom:
    cpy #KERNEL_SCANLINES-SCORE_LINES-SPIDER_SIZE-SPIDER_VEL_Y-17
    bcc .spider_control_store
    ldy #KERNEL_SCANLINES-SCORE_LINES-SPIDER_SIZE-SPIDER_VEL_Y-17

.spider_control_store:
    ; Store new position
    stx SpiderPosX
    sty SpiderPosY

.spider_control_sprite_assign:
    ; Skip if no change
    cmp #%00000000
    beq .spider_control_return

    ldx #%00000000  ; For reflection

    bit SpiderCtrl
    bmi .spider_control_sprite_assign_right
    bvc .spider_control_sprite_assign_top

.spider_control_sprite_assign_left:
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*1
    ldx #%00001000
    jmp .spider_control_reflect

.spider_control_sprite_assign_right:
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*1
    jmp .spider_control_reflect

.spider_control_sprite_assign_top:
    cmp #%00010000
    bne .spider_control_sprite_assign_bottom
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*0
    jmp .spider_control_reflect

.spider_control_sprite_assign_bottom:
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*2
    jmp .spider_control_reflect

.spider_control_reflect:
    stx REFP0

.spider_control_return:
;    rts

SpiderCollision:
    ldy #SPIDER_COLOR

    ; Check b/w
    lda SWCHB
    and #%00001000
    bne .spider_collision_m0

    ldy #SPIDER_BW_COLOR

.spider_collision_m0:
    ; Check stun status
    ldx BugStunned
    bne .spider_collision_m1

    ; Collision for M0 (V set)
    bit CXM0P
    bvs .spider_collision_active

.spider_collision_m1:
    ; Check stun status
    ldx BugStunned+1
    bne .spider_collision_return

    ; Collision for M1 (N set)
    bit CXM1P
    bmi .spider_collision_active

    jmp .spider_collision_return

.spider_collision_active:
    ldy #SPIDER_COL_COLOR

    ; Check b/w
    lda SWCHB
    and #%00001000
    bne .spider_collision_return

    ldy #SPIDER_COL_BW_COLOR

.spider_collision_return:
    sty SpiderColor

.spider_update_return:
    rts

; Scanline Draw

SpiderDrawStart:

    ; Set player 0 to be quad size
    ;lda NuSiz0
    ;and #%11111000
    ;ora #%00000101
    ;sta NuSiz0
    ;sta NUSIZ0

    ; Set sprite color
    lda SpiderColor
    sta COLUP0

    ; Determine if we need to use vertical delay (odd line)
    lda SpiderPosY     ; Y Position
    lsr
    bcs .spider_draw_start_nodelay

    ldy #1
    jmp .spider_draw_start_set_delay

.spider_draw_start_nodelay:
    ldy #0

.spider_draw_start_set_delay:
    sty VDELP0

.spider_draw_start_pos:
    ; Calculate starting position
    clc
    adc #SPIDER_SIZE
    sta SpiderDrawPos

    ; Initialize sprite index and line buffer
    lda #SPIDER_SPRITE_SIZE
    sta SpiderIndex
    lda #0
    sta SpiderLine

    rts
