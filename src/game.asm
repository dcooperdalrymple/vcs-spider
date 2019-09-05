;================
; Constants
;================

GAME_BG_COLOR       = #$00
GAME_FG_COLOR       = #$0C

GAME_P0_COLOR       = #$56
GAME_P0_SIZE        = 8

GameInit:

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

    ldy #0
    lda PlayerSprite,y
    sta GRP0

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
    iny

.game_control_check_up:
    rol
    bmi .game_control_return
    dey

.game_control_return:

    ; Store new position
    stx PlayerPosition
    sty PlayerPosition+1

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

GameImage:              ; Web

    .BYTE %00000000     ; Reversed
    .BYTE %00000000     ; Normal
    .BYTE %00000011     ; First 4 bits reversed

    .BYTE %00000000
    .BYTE %00000000
    .BYTE %00111111

    .BYTE %00000000
    .BYTE %00000001
    .BYTE %11000010

    .BYTE %00000000
    .BYTE %00000001
    .BYTE %00000100

    .BYTE %00000000
    .BYTE %00000010
    .BYTE %00001000

    .BYTE %00000000
    .BYTE %00001100
    .BYTE %00001000

    .BYTE %00110000
    .BYTE %00110000
    .BYTE %00010000

    .BYTE %11100000
    .BYTE %11000000
    .BYTE %00100000

    .BYTE %00100000
    .BYTE %00111000
    .BYTE %00100000

    .BYTE %01000000
    .BYTE %00000111
    .BYTE %01000001

    .BYTE %01000000
    .BYTE %00000000
    .BYTE %10001110

    .BYTE %10000000
    .BYTE %00000000
    .BYTE %11110000

    .BYTE %00000000
    .BYTE %00000000
    .BYTE %00000011

    .BYTE %00000000
    .BYTE %00000000
    .BYTE %00111111

    .BYTE %00000000
    .BYTE %00000001
    .BYTE %11000010

    .BYTE %00000000
    .BYTE %00000001
    .BYTE %00000100

    .BYTE %00000000
    .BYTE %00000010
    .BYTE %00001000

    .BYTE %00000000
    .BYTE %00001100
    .BYTE %00001000

    .BYTE %00110000
    .BYTE %00110000
    .BYTE %00010000

    .BYTE %11100000
    .BYTE %11000000
    .BYTE %00100000

    .BYTE %00100000
    .BYTE %00111000
    .BYTE %00100000

    .BYTE %01000000
    .BYTE %00000111
    .BYTE %01000001

    .BYTE %01000000
    .BYTE %00000000
    .BYTE %10001110

    .BYTE %10000000
    .BYTE %00000000
    .BYTE %11110000

PlayerSprite: ; Sprites are reversed in y direction

    ; Up
    .BYTE %10011001
    .BYTE %10111101
    .BYTE %01111110
    .BYTE %00111100
    .BYTE %01111110
    .BYTE %10011001
    .BYTE %10111101
    .BYTE %10011001

    ; Right
    .BYTE %11000111
    .BYTE %00101000
    .BYTE %01111010
    .BYTE %11111111
    .BYTE %11111111
    .BYTE %01111010
    .BYTE %00101000
    .BYTE %11000111

    ; Down
    .BYTE %10011001
    .BYTE %10111101
    .BYTE %01111110
    .BYTE %00111100
    .BYTE %01111110
    .BYTE %10011001
    .BYTE %10111101
    .BYTE %10011001

    ; Left
    .BYTE %11100011
    .BYTE %00010100
    .BYTE %01011110
    .BYTE %11111111
    .BYTE %11111111
    .BYTE %01011110
    .BYTE %00010100
    .BYTE %11100011
