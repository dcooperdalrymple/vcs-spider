;================
; Constants
;================

GAME_BG_COLOR       = #$00
GAME_FG_COLOR       = #$0C

GAME_P0_COLOR       = #$56
GAME_P0_SIZE        = 8
GAME_P0_BOUNDARY    = GAME_P0_SIZE

GameInit:

    ; Setup state and kernel
    lda #STATE_GAME
    sta State

    lda #KERNEL_GAME
    sta KernelType

    ; Load Colors
    lda #GAME_BG_COLOR
    sta COLUBK
    lda #GAME_FG_COLOR
    sta COLUPF
    lda #GAME_P0_COLOR
    sta COLUP0

    ; Mute Audio
    lda #0
    sta AUDC0
    sta AUDV0
    sta AUDF0
    sta AUDC1
    sta AUDV1
    sta AUDF1

    ; Initial Player Control
    lda #50
    sta PlayerPosition
    sta PlayerPosition+1

    ; Setup Player Sprite
    SET_POINTER PlayerPtr, GamePlayerSprite

    ; Setup Image
    SET_POINTER ImagePtr, GameImage
    lda #0
    sta ImageVisible

    rts

GameVerticalBlank:
    jsr GameControl
    jsr GameObjects
    rts

GameOverScan:
    rts

GameControl:
    ldx PlayerPosition
    ldy PlayerPosition+1
    lda SWCHA

.game_control_check_right:
    bmi .game_control_check_left
    inx

.game_control_check_left:
    rol
    bmi .game_control_check_down
    dex

.game_control_check_down:
    rol
    bmi .game_control_check_up
    dey

.game_control_check_up:
    rol
    bmi .game_control_sprite
    iny

.game_control_sprite:
    lda #%00000000 ; First 2 bits are left or right, second 2 bits are up or down

.game_control_sprite_x:
    cpx PlayerPosition
    bcc .game_control_sprite_left
    beq .game_control_sprite_y
    bcs .game_control_sprite_right

.game_control_sprite_left:
    ora #%10000000
    jmp .game_control_sprite_y

.game_control_sprite_right:
    ora #%01000000

.game_control_sprite_y:
    cpy PlayerPosition+1
    bcc .game_control_sprite_down
    beq .game_control_boundary
    bcs .game_control_sprite_up

.game_control_sprite_down:
    ora #%00010000
    jmp .game_control_boundary

.game_control_sprite_up:
    ora #%00100000

.game_control_boundary:
    ; Check Playfield Boundaries

.game_control_boundary_left:
    cpx #GAME_P0_BOUNDARY
    bcs .game_control_boundary_right
    ldx #GAME_P0_BOUNDARY

.game_control_boundary_right:
    ;cpx #KERNEL_WIDTH-GAME_P0_BOUNDARY-GAME_P0_SIZE
    ;bcc .game_control_boundary_top
    ;ldx #KERNEL_WIDTH-GAME_P0_BOUNDARY-GAME_P0_SIZE

.game_control_boundary_top:
    cpy #GAME_P0_BOUNDARY
    bcs .game_control_boundary_bottom
    ldy #GAME_P0_BOUNDARY

.game_control_boundary_bottom:
    cpy #KERNEL_SCANLINES-GAME_P0_BOUNDARY-GAME_P0_SIZE
    bcc .game_control_store
    ldy #KERNEL_SCANLINES-GAME_P0_BOUNDARY-GAME_P0_SIZE

.game_control_store:
    ; Store new position
    stx PlayerPosition
    sty PlayerPosition+1

.game_control_sprite_assign:
    ; Skip if no change
    cmp #%00000000
    beq .game_control_return

.game_control_sprite_assign_left:
    cmp #%10000000
    bne .game_control_sprite_assign_right
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*6
    jmp .game_control_return

.game_control_sprite_assign_right:
    cmp #%01000000
    bne .game_control_sprite_assign_top
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*2
    jmp .game_control_return

.game_control_sprite_assign_top:
    cmp #%00100000
    bne .game_control_sprite_assign_bottom
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*0
    jmp .game_control_return

.game_control_sprite_assign_bottom:
    cmp #%00010000
    bne .game_control_sprite_assign_top_right
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*4
    jmp .game_control_return

.game_control_sprite_assign_top_right:
    cmp #%01100000
    bne .game_control_sprite_assign_bottom_right
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*1
    jmp .game_control_return

.game_control_sprite_assign_bottom_right:
    cmp #%01010000
    bne .game_control_sprite_assign_bottom_left
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*3
    jmp .game_control_return

.game_control_sprite_assign_bottom_left:
    cmp #%10010000
    bne .game_control_sprite_assign_top_left
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*5
    jmp .game_control_return

.game_control_sprite_assign_top_left:
    cmp #%10100000
    bne .game_control_return
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*7

.game_control_return:
    rts

GameObjects:

.game_objects_player:

    ldx #0                  ; Object (player0)
    lda PlayerPosition      ; X Position
    jsr PosObject

    ; Set final x position
    sta WSYNC
    sta HMOVE

    rts

    ; Game Background
    include "game_image.asm"

    ; Game Player Sprites
    include "game_player.asm"
