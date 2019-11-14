;=================
; Spider (player0)
;=================

; Constants

SPIDER_COLOR       = #$56
SPIDER_SIZE        = 8
SPIDER_BOUNDARY    = SPIDER_SIZE

; Variables

    SEG.U spider_vars
    org $93

PlayerPtr           ds 2
PlayerPosition      ds 2
PlayerControl       ds 1

    SEG
    org $F000

; Initialization

SpiderInit:

    ; Load Colors
    lda #SPIDER_COLOR
    sta COLUP0

    ; Initial Player Control
    lda #50
    sta PlayerPosition
    sta PlayerPosition+1

    ; Setup Player Sprite
    SET_POINTER PlayerPtr, GamePlayerSprite

    rts

; Frame Update

SpiderUpdate:
    jsr SpiderControl
    jsr SpiderObject
    rts

SpiderControl:

    ; Control Position
    ldx PlayerPosition
    ldy PlayerPosition+1
    lda SWCHA

.spider_control_check_right:
    bmi .spider_control_check_left
    inx

.spider_control_check_left:
    rol
    bmi .spider_control_check_down
    dex

.spider_control_check_down:
    rol
    bmi .spider_control_check_up
    dey

.spider_control_check_up:
    rol
    bmi .spider_control_sprite
    iny

.spider_control_sprite:
    ; Control Sprite
    lda #%00000000 ; First 2 bits are left or right, second 2 bits are up or down

.spider_control_sprite_x:
    cpx PlayerPosition
    bcc .spider_control_sprite_left
    beq .spider_control_sprite_y
    bcs .spider_control_sprite_right

.spider_control_sprite_left:
    ora #%10000000
    jmp .spider_control_sprite_y

.spider_control_sprite_right:
    ora #%01000000

.spider_control_sprite_y:
    cpy PlayerPosition+1
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
    sta PlayerControl

.spider_control_boundary:
    ; Check Playfield Boundaries

.spider_control_boundary_left:
    cpx #SPIDER_BOUNDARY
    bcs .spider_control_boundary_right
    ldx #SPIDER_BOUNDARY

.spider_control_boundary_right:
    cpx #151-SPIDER_BOUNDARY-SPIDER_SIZE ; #KERNEL_WIDTH/2-SPIDER_BOUNDARY-SPIDER_SIZE
    bcc .spider_control_boundary_top
    ldx #151-SPIDER_BOUNDARY-SPIDER_SIZE

.spider_control_boundary_top:
    cpy #SPIDER_BOUNDARY
    bcs .spider_control_boundary_bottom
    ldy #SPIDER_BOUNDARY

.spider_control_boundary_bottom:
    cpy #KERNEL_SCANLINES-SPIDER_BOUNDARY-SPIDER_SIZE
    bcc .spider_control_store
    ldy #KERNEL_SCANLINES-SPIDER_BOUNDARY-SPIDER_SIZE

.spider_control_store:
    ; Store new position
    stx PlayerPosition
    sty PlayerPosition+1

.spider_control_sprite_assign:
    ; Skip if no change
    cmp #%00000000
    beq .spider_control_return

.spider_control_sprite_assign_left:
    cmp #%10000000
    bne .spider_control_sprite_assign_right
    SET_POINTER PlayerPtr, GamePlayerSprite+#SPIDER_SIZE*6
    jmp .spider_control_return

.spider_control_sprite_assign_right:
    cmp #%01000000
    bne .spider_control_sprite_assign_top
    SET_POINTER PlayerPtr, GamePlayerSprite+#SPIDER_SIZE*2
    jmp .spider_control_return

.spider_control_sprite_assign_top:
    cmp #%00100000
    bne .spider_control_sprite_assign_bottom
    SET_POINTER PlayerPtr, GamePlayerSprite+#SPIDER_SIZE*0
    jmp .spider_control_return

.spider_control_sprite_assign_bottom:
    cmp #%00010000
    bne .spider_control_sprite_assign_top_right
    SET_POINTER PlayerPtr, GamePlayerSprite+#SPIDER_SIZE*4
    jmp .spider_control_return

.spider_control_sprite_assign_top_right:
    cmp #%01100000
    bne .spider_control_sprite_assign_bottom_right
    SET_POINTER PlayerPtr, GamePlayerSprite+#SPIDER_SIZE*1
    jmp .spider_control_return

.spider_control_sprite_assign_bottom_right:
    cmp #%01010000
    bne .spider_control_sprite_assign_bottom_left
    SET_POINTER PlayerPtr, GamePlayerSprite+#SPIDER_SIZE*3
    jmp .spider_control_return

.spider_control_sprite_assign_bottom_left:
    cmp #%10010000
    bne .spider_control_sprite_assign_top_left
    SET_POINTER PlayerPtr, GamePlayerSprite+#SPIDER_SIZE*5
    jmp .spider_control_return

.spider_control_sprite_assign_top_left:
    cmp #%10100000
    bne .spider_control_return
    SET_POINTER PlayerPtr, GamePlayerSprite+#SPIDER_SIZE*7

.spider_control_return:
    rts

SpiderObject:

    ; Set Player Position
    ldx #0                  ; Object (player0)
    lda PlayerPosition      ; X Position
    jsr PosObject

    rts

; Scanline Draw

SpiderDrawStart:

    ; Set player 0 to be double size
    lda NUSIZ0
    and #%11111000
    ora #%00000101
    sta NUSIZ0

    rts

SpiderDraw:

    txa
    sbc PlayerPosition+1

    ; Sync up to horizontal line
    sta WSYNC

    cmp #SPIDER_SIZE*2
    bcc .spider_draw_line

.game_kernel_player_blank:

    ; Draw empty sprite
    lda #0
    sta GRP0
    jmp .spider_draw_return

.spider_draw_line:

    ; Load sprite line
    and #%11111110
    lsr ; Divide by 2
    tay
    lda (PlayerPtr),y
    sta GRP0

.spider_draw_return:
    rts

SpiderClean:

    ; Clear out Player sprite
    lda #0
    sta GRP0

    rts


    ; Spider Sprites
    include "game_player.asm"
