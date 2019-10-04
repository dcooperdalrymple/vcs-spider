;================
; Constants
;================

GAME_BG_COLOR       = #$00
GAME_FG_COLOR       = #$06

GAME_P0_COLOR       = #$56
GAME_P0_SIZE        = 8
GAME_P0_BOUNDARY    = GAME_P0_SIZE

GAME_M1_COLOR       = #$0E
GAME_M1_SIZE        = 2
GAME_M1_DISTANCE    = 64    ; Distance from player
GAME_M1_VEL_X       = 2
GAME_M1_VEL_Y       = 3

GameInit:

    ; Setup logic and kernel
    SET_POINTER VBlankPtr, GameVerticalBlank
    SET_POINTER KernelPtr, GameKernel
    SET_POINTER OverScanPtr, GameOverScan

    ; Load Colors
    lda #GAME_BG_COLOR
    sta COLUBK
    lda #GAME_FG_COLOR
    sta COLUPF
    lda #GAME_P0_COLOR
    sta COLUP0
    lda #GAME_M1_COLOR
    sta COLUP1

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

    ; Initial Missile Control

    lda #0
    sta MissileEnabled
    sta MissilePosition
    sta MissilePosition+1
    sta MissileVelocity
    sta MissileVelocity+1
    sta MissileStartPos
    sta MissileStartPos+1

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
    beq .game_control_sprite_store
    bcs .game_control_sprite_up

.game_control_sprite_down:
    ora #%00010000
    jmp .game_control_sprite_store

.game_control_sprite_up:
    ora #%00100000

.game_control_sprite_store:
    cmp #%00000000
    beq .game_control_boundary
    sta PlayerControl

.game_control_boundary:
    ; Check Playfield Boundaries

.game_control_boundary_left:
    cpx #GAME_P0_BOUNDARY
    bcs .game_control_boundary_right
    ldx #GAME_P0_BOUNDARY

.game_control_boundary_right:
    cpx #151-GAME_P0_BOUNDARY-GAME_P0_SIZE ; #KERNEL_WIDTH/2-GAME_P0_BOUNDARY-GAME_P0_SIZE
    bcc .game_control_boundary_top
    ldx #151-GAME_P0_BOUNDARY-GAME_P0_SIZE

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
    beq .game_control_missile

.game_control_sprite_assign_left:
    cmp #%10000000
    bne .game_control_sprite_assign_right
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*6
    jmp .game_control_missile

.game_control_sprite_assign_right:
    cmp #%01000000
    bne .game_control_sprite_assign_top
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*2
    jmp .game_control_missile

.game_control_sprite_assign_top:
    cmp #%00100000
    bne .game_control_sprite_assign_bottom
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*0
    jmp .game_control_missile

.game_control_sprite_assign_bottom:
    cmp #%00010000
    bne .game_control_sprite_assign_top_right
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*4
    jmp .game_control_missile

.game_control_sprite_assign_top_right:
    cmp #%01100000
    bne .game_control_sprite_assign_bottom_right
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*1
    jmp .game_control_missile

.game_control_sprite_assign_bottom_right:
    cmp #%01010000
    bne .game_control_sprite_assign_bottom_left
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*3
    jmp .game_control_missile

.game_control_sprite_assign_bottom_left:
    cmp #%10010000
    bne .game_control_sprite_assign_top_left
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*5
    jmp .game_control_missile

.game_control_sprite_assign_top_left:
    cmp #%10100000
    bne .game_control_missile
    SET_POINTER PlayerPtr, GamePlayerSprite+#GAME_P0_SIZE*7

.game_control_missile:

    ; Check if Fire Button on controller 1 is pressed
    lda INPT4
    bmi .game_control_missile_skip

    lda MissileEnabled
    cmp #1
    beq .game_control_missile_skip

    lda PlayerControl
    cmp #0
    bne .game_control_missile_fire

.game_control_missile_skip:
    jmp .game_control_return

.game_control_missile_fire:
    lda #1
    sta MissileEnabled

.game_control_missile_x:
    lda PlayerControl
    and #%11000000
    beq .game_control_missile_x_none
.game_control_missile_x_left:
    cmp #%10000000
    bne .game_control_missile_x_right

    lda #-GAME_M1_VEL_X
    jmp .game_control_missile_x_store
.game_control_missile_x_right:
    lda #GAME_M1_VEL_X
    jmp .game_control_missile_x_store
.game_control_missile_x_none:
    lda #0
.game_control_missile_x_store:
    sta MissileVelocity

.game_control_missile_y:
    lda PlayerControl
    and #%00110000
    beq .game_control_missile_y_none
.game_control_missile_y_up:
    cmp #%00100000
    bne .game_control_missile_y_down

    lda #GAME_M1_VEL_Y
    jmp .game_control_missile_y_store
.game_control_missile_y_down:
    lda #-GAME_M1_VEL_Y
    jmp .game_control_missile_y_store
.game_control_missile_y_none:
    lda #0
.game_control_missile_y_store:
    sta MissileVelocity+1

.game_control_missile_position:

    ldx #0 ; offsetX
    ldy #0 ; offsetY

    lda PlayerControl
    and #%11110000

.game_control_missile_position_left:
    cmp #%10000000
    bne .game_control_missile_position_right

    ldx #GAME_M1_SIZE
    ldy #GAME_P0_SIZE
    jmp .game_control_missile_position_store

.game_control_missile_position_right:
    cmp #%01000000
    bne .game_control_missile_position_top

    ldx #GAME_P0_SIZE*2
    ldy #GAME_P0_SIZE
    jmp .game_control_missile_position_store

.game_control_missile_position_top:
    cmp #%00100000
    bne .game_control_missile_position_bottom

    ldx #GAME_P0_SIZE+GAME_M1_SIZE/2
    ldy #GAME_P0_SIZE*2
    jmp .game_control_missile_position_store

.game_control_missile_position_bottom:
    cmp #%00010000
    bne .game_control_missile_position_top_right

    ldx #GAME_P0_SIZE+GAME_M1_SIZE/2
    jmp .game_control_missile_position_store

.game_control_missile_position_top_right:
    cmp #%01100000
    bne .game_control_missile_position_bottom_right

    ldx #GAME_P0_SIZE*2
    ldy #GAME_P0_SIZE*2
    jmp .game_control_missile_position_store

.game_control_missile_position_bottom_right:
    cmp #%01010000
    bne .game_control_missile_position_bottom_left

    ldx #GAME_P0_SIZE*2
    jmp .game_control_missile_position_store

.game_control_missile_position_bottom_left:
    cmp #%10010000
    bne .game_control_missile_position_top_left

    ; No Offset
    jmp .game_control_missile_position_store

.game_control_missile_position_top_left:
    cmp #%10100000
    bne .game_control_missile_position_store

    ldx #GAME_M1_SIZE
    ldy #GAME_P0_SIZE*2

.game_control_missile_position_store:

    ; Apply offsetX to playerX
    lda PlayerPosition
    stx Temp
    clc
    adc Temp
    tax

    ; Apply offsetY to playerY
    lda PlayerPosition+1
    sty Temp
    clc
    adc Temp
    tay

    stx MissilePosition
    sty MissilePosition+1
    stx MissileStartPos
    sty MissileStartPos+1

.game_control_return:
    rts

GameObjects:

    sta HMCLR

.game_objects_player:

    ; Set Player Position
    ldx #0                  ; Object (player0)
    lda PlayerPosition      ; X Position
    jsr PosObject

.game_objects_missile:

    ; Check if missile is enabled
    lda MissileEnabled
    cmp #1
    bne .game_objects_return

    ; Load position
    ldx MissilePosition
    ldy MissilePosition+1

.game_objects_missile_distance:

    ; Check distance from player with absolute value differences

.game_objects_missile_distance_x:
    txa
    clc
    sbc MissileStartPos
    bcs .game_objects_missile_distance_x_check
    eor #$FF    ; C flag is clear here
    adc #$01    ; form two's complement
.game_objects_missile_distance_x_check: ; Jumps to if positive
    cmp #GAME_M1_DISTANCE
    bcs .game_objects_missile_disable

.game_objects_missile_distance_y:
    tya
    clc
    sbc MissileStartPos+1
    bcs .game_objects_missile_distance_y_check
    eor #$FF    ; C flag is clear here
    adc #$01    ; form two's complement
.game_objects_missile_distance_y_check: ; Jumps to if positive
    cmp #GAME_M1_DISTANCE
    bcs .game_objects_missile_disable

.game_objects_missile_boundary:
.game_objects_missile_boundary_left:
    cpx #GAME_M1_VEL_X
    bcc .game_objects_missile_disable
.game_objects_missile_boundary_right:
    cpx #160-GAME_M1_VEL_X
    bcs .game_objects_missile_disable
.game_objects_missile_boundary_bottom:
    cpy #GAME_M1_VEL_Y
    bcc .game_objects_missile_disable
.game_objects_missile_boundary_top:
    cpy #KERNEL_SCANLINES-GAME_M1_VEL_Y
    bcs .game_objects_missile_disable

.game_objects_missile_velocity:

    ; Apply Velocity
    txa
    clc
    adc MissileVelocity
    sta MissilePosition

    tya
    clc
    adc MissileVelocity+1
    sta MissilePosition+1

    ; Set Missile Position
    ldx #1                  ; Object (missile1)
    lda MissilePosition     ; X Position
    jsr PosMissile

    jmp .game_objects_return

.game_objects_missile_disable:
    lda #0
    sta MissileEnabled

.game_objects_return:

    ; Set final x position
    sta WSYNC
    sta HMOVE

    rts

GameKernel:

    ; Playfield Control
    lda #%00000001 ; Mirrored
    sta CTRLPF

    ; Set player 0 to be double size and missile 0 to be 2 clock size (4/5 bits)
    lda NUSIZ0
    and #%11111000
    ora #%00000101
    sta NUSIZ0

    ; Set missile 0 to be 2 clock size (4/5 bits)
    lda NUSIZ1
    and #%11001111
    ora #%00010101
    sta NUSIZ1

    ; Turn on display
    lda #0
    sta VBLANK

    ; Setup Image Index
    lda #0
    sta ImageIndex

    ; Start Counters
    ldx #KERNEL_SCANLINES ; Scanline Counter
;    ldy #0 ; Image Counter

.game_kernel:

;=======================================
; Player
;=======================================

.game_kernel_player:

    txa
    sbc PlayerPosition+1

    ; Sync up to horizontal line
    sta WSYNC

    cmp #GAME_P0_SIZE*2
    bcc .game_kernel_player_draw

.game_kernel_player_blank:

    ; Draw empty sprite
    lda #0
    sta GRP0
    jmp .game_kernel_player_skip

.game_kernel_player_draw:

    ; Load sprite line
    and #%11111110
    lsr ; Divide by 2
    tay
    lda (PlayerPtr),y
    sta GRP0

.game_kernel_player_skip:

;=======================================
; Missile
;=======================================

.game_kernel_missile:

    ; Check if visible
    lda MissileEnabled
    cmp #1
    bne .game_kernel_missile_off

    ; Check y position
    txa
    sbc MissilePosition+1
    cmp #GAME_M1_SIZE*2
    bcc .game_kernel_missile_on

.game_kernel_missile_off:
    lda #%00000000
    jmp .game_kernel_missile_write

.game_kernel_missile_on:
    lda #%00000010

.game_kernel_missile_write:
    sta ENAM1

;=======================================
; Playfield Image
;=======================================

.game_kernel_image:

    ; Check to see if new playfield needs to be loaded
    txa
    and #%00000111
    bne .game_kernel_image_skip

.game_kernel_image_load:

    ldy ImageIndex

    ; Draw Image
    lda GameImagePF0,y ; 3
    sta PF0 ; 1
    lda GameImagePF1,y ; 3
    sta PF1 ; 1
    lda GameImagePF2,y ; 3
    sta PF2 ; 1

    iny ; 2
    sty ImageIndex

.game_kernel_image_skip:

.game_kernel_line:
    dex
    bne .game_kernel

.game_kernel_clean:

    ; Clear out playfield
    lda #0
    sta PF0
    sta PF1
    sta PF2

    ; Clear out Player sprite
    sta GRP0

    ; Clear out Missile
    sta ENAM1

    sta WSYNC

.game_kernel_return:
    rts

GameAssets:

    ; Game Background
    include "game_image.asm"

    ; Game Player Sprites
    include "game_player.asm"
