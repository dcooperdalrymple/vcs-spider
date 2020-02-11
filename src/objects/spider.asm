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
    sta SpiderPos
    lda #(KERNEL_SCANLINES-SCORE_LINES)/2-SPIDER_SIZE-1
    sta SpiderPos+1

    ; Setup Sprite
    SET_POINTER SpiderPtr, SpiderSprite

    rts

; Frame Update

SpiderUpdate:
    jsr SpiderControl
    jsr SpiderCollision
    rts

SpiderControl:

    ; Control Position
    ldx SpiderPos
    ldy SpiderPos+1
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
    lda #%00000000 ; First 2 bits are left or right, second 2 bits are up or down

.spider_control_sprite_x:
    cpx SpiderPos
    bcc .spider_control_sprite_left
    beq .spider_control_sprite_y
    bcs .spider_control_sprite_right

.spider_control_sprite_left:
    ora #%10000000
    jmp .spider_control_sprite_y

.spider_control_sprite_right:
    ora #%01000000

.spider_control_sprite_y:
    cpy SpiderPos+1
    bcc .spider_control_sprite_down
    beq .spider_control_sprite_store
    bcs .spider_control_sprite_up

.spider_control_sprite_down:
    ora #%00010000
    jmp .spider_control_sprite_store

.spider_control_sprite_up:
    ora #%00100000

.spider_control_sprite_store:
    cmp #%00000000
    beq .spider_control_boundary
    sta SpiderCtrl

.spider_control_boundary:
    ; Check Playfield Boundaries

.spider_control_boundary_left:
    cpx #SPIDER_VEL_X+1
    bcs .spider_control_boundary_right
    ldx #SPIDER_VEL_X+1
    jmp .spider_control_boundary_top

.spider_control_boundary_right:
    cpx #(KERNEL_WIDTH/2)-SPIDER_SIZE-SPIDER_VEL_X-3
    bcc .spider_control_boundary_top
    ldx #(KERNEL_WIDTH/2)-SPIDER_SIZE-SPIDER_VEL_X-3

.spider_control_boundary_top:
    cpy #SPIDER_VEL_Y+11
    bcs .spider_control_boundary_bottom
    ldy #SPIDER_VEL_Y+11
    jmp .spider_control_store

.spider_control_boundary_bottom:
    cpy #KERNEL_SCANLINES-SCORE_LINES-SPIDER_SIZE-SPIDER_VEL_Y-17
    bcc .spider_control_store
    ldy #KERNEL_SCANLINES-SCORE_LINES-SPIDER_SIZE-SPIDER_VEL_Y-17

.spider_control_store:
    ; Store new position
    stx SpiderPos
    sty SpiderPos+1

; TODO: Optimize this somehow?
.spider_control_sprite_assign:
    ; Skip if no change
    cmp #%00000000
    beq .spider_control_return

    ldx #%00000000  ; For reflection

.spider_control_sprite_assign_left:
    cmp #%10000000
    bne .spider_control_sprite_assign_right
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*1
    ldx #%00001000
    jmp .spider_control_reflect

.spider_control_sprite_assign_right:
    cmp #%01000000
    bne .spider_control_sprite_assign_top
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*1
    jmp .spider_control_reflect

.spider_control_sprite_assign_top:
    cmp #%00100000
    bne .spider_control_sprite_assign_bottom
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*0
    jmp .spider_control_reflect

.spider_control_sprite_assign_bottom:
    cmp #%00010000
    bne .spider_control_sprite_assign_top_right
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*2
    jmp .spider_control_reflect

.spider_control_sprite_assign_top_right:
    cmp #%01100000
    bne .spider_control_sprite_assign_bottom_right
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*1
    jmp .spider_control_reflect

.spider_control_sprite_assign_bottom_right:
    cmp #%01010000
    bne .spider_control_sprite_assign_bottom_left
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*1
    jmp .spider_control_reflect

.spider_control_sprite_assign_bottom_left:
    cmp #%10010000
    bne .spider_control_sprite_assign_top_left
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*1
    ldx #%00001000
    jmp .spider_control_reflect

.spider_control_sprite_assign_top_left:
    cmp #%10100000
    bne .spider_control_reflect
    SET_POINTER SpiderPtr, SpiderSprite+#SPIDER_SPRITE_SIZE*1
    ldx #%00001000

.spider_control_reflect:
    stx REFP0

.spider_control_return:
    rts

SpiderCollision:
    ldy #SPIDER_COLOR

    ; Check b/w
    lda SWCHB
    REPEAT 4
    lsr
    REPEND
    bcs .spider_collision_m0

    ldy #SPIDER_BW_COLOR

.spider_collision_m0:
    ; Check stun status
    ldx BugStunned
    cpx #0
    bne .spider_collision_m1

    ; Collision for M0 (V set)
    bit CXM0P
    bvs .spider_collision_active

.spider_collision_m1:
    ; Check stun status
    ldx BugStunned+1
    cpx #0
    bne .spider_collision_return

    ; Collision for M1 (N set)
    bit CXM1P
    bmi .spider_collision_active

    jmp .spider_collision_return

.spider_collision_active:
    ldy #SPIDER_COL_COLOR

    ; Check b/w
    lda SWCHB
    REPEAT 4
    lsr
    REPEND
    bcs .spider_collision_return

    ldy #SPIDER_COL_BW_COLOR

.spider_collision_return:
    sty SpiderColor
    rts

SpiderPosition:

    ; Set Position
    ldx #0              ; Object (player0)
    lda SpiderPos       ; X Position
    jsr PosObject

    rts

; Scanline Draw

SpiderDrawStart:

    ; Set player 0 to be quad size
    lda NuSiz0
    and #%11111000
    ora #%00000101
    sta NuSiz0
    sta NUSIZ0

    ; Set sprite color
    lda SpiderColor
    sta COLUP0

    ; Determine if we need to use vertical delay (odd line)
    lda SpiderPos+1    ; Y Position
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
    lda #0
    sta SpiderIndex
    sta SpiderLine

    rts

SpiderClean:

    ; Clear out Player0 sprite
    lda #0
    sta GRP0

    rts
