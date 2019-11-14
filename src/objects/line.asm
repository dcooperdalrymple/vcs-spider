;================
; Line (ball)
;================

; Constants

LINE_COLOR       = #$0E
LINE_SIZE        = 2
LINE_DISTANCE    = 64    ; Distance from player
LINE_VEL_X       = 2
LINE_VEL_Y       = 3

; Variables

    SEG.U line_vars
    org $98

LineEnabled         ds 1
LinePosition        ds 2
LineVelocity        ds 2
LineStartPos        ds 2

    SEG
    org $F000

; Initialization

LineInit:

    ; Load Colors
    lda #LINE_COLOR
    sta COLUP1

    ; Initial Line Control
    lda #0
    sta LineEnabled
    sta LinePosition
    sta LinePosition+1
    sta LineVelocity
    sta LineVelocity+1
    sta LineStartPos
    sta LineStartPos+1

    rts

; Frame Update

LineUpdate:
    jsr LineControl
    jsr LineObject
    rts

LineControl:

    ; Check if Fire Button on controller 1 is pressed
    lda INPT4
    bmi .line_control_skip

    lda LineEnabled
    cmp #1
    beq .line_control_skip

    lda PlayerControl
    cmp #0
    bne .line_control_fire

.line_control_skip:
    jmp .line_control_return

.line_control_fire:
    lda #1
    sta LineEnabled

.line_control_x:
    lda PlayerControl
    and #%11000000
    beq .line_control_x_none
.line_control_x_left:
    cmp #%10000000
    bne .line_control_x_right

    lda #-LINE_VEL_X
    jmp .line_control_x_store
.line_control_x_right:
    lda #LINE_VEL_X
    jmp .line_control_x_store
.line_control_x_none:
    lda #0
.line_control_x_store:
    sta LineVelocity

.line_control_y:
    lda PlayerControl
    and #%00110000
    beq .line_control_y_none
.line_control_y_up:
    cmp #%00100000
    bne .line_control_y_down

    lda #LINE_VEL_Y
    jmp .line_control_y_store
.line_control_y_down:
    lda #-LINE_VEL_Y
    jmp .line_control_y_store
.line_control_y_none:
    lda #0
.line_control_y_store:
    sta LineVelocity+1

.line_control_position:

    ldx #0 ; offsetX
    ldy #0 ; offsetY

    lda PlayerControl
    and #%11110000

.line_control_position_left:
    cmp #%10000000
    bne .line_control_position_right

    ldx #LINE_SIZE
    ldy #GAME_P0_SIZE
    jmp .line_control_position_store

.line_control_position_right:
    cmp #%01000000
    bne .line_control_position_top

    ldx #GAME_P0_SIZE*2
    ldy #GAME_P0_SIZE
    jmp .line_control_position_store

.line_control_position_top:
    cmp #%00100000
    bne .line_control_position_bottom

    ldx #GAME_P0_SIZE+LINE_SIZE/2
    ldy #GAME_P0_SIZE*2
    jmp .line_control_position_store

.line_control_position_bottom:
    cmp #%00010000
    bne .line_control_position_top_right

    ldx #GAME_P0_SIZE+LINE_SIZE/2
    jmp .line_control_position_store

.line_control_position_top_right:
    cmp #%01100000
    bne .line_control_position_bottom_right

    ldx #GAME_P0_SIZE*2
    ldy #GAME_P0_SIZE*2
    jmp .line_control_position_store

.line_control_position_bottom_right:
    cmp #%01010000
    bne .line_control_position_bottom_left

    ldx #GAME_P0_SIZE*2
    jmp .line_control_position_store

.line_control_position_bottom_left:
    cmp #%10010000
    bne .line_control_position_top_left

    ; No Offset
    jmp .line_control_position_store

.line_control_position_top_left:
    cmp #%10100000
    bne .line_control_position_store

    ldx #LINE_SIZE
    ldy #GAME_P0_SIZE*2

.line_control_position_store:

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

    stx LinePosition
    sty LinePosition+1
    stx LineStartPos
    sty LineStartPos+1

.line_control_return:
    rts

LineObject:

    ; Check if missile is enabled
    lda LineEnabled
    cmp #1
    bne .game_objects_return

    ; Load position
    ldx LinePosition
    ldy LinePosition+1

.line_object_distance:

    ; Check distance from player with absolute value differences

.line_object_distance_x:
    txa
    clc
    sbc LineStartPos
    bcs .line_object_distance_x_check
    eor #$FF    ; C flag is clear here
    adc #$01    ; form two's complement
.line_object_distance_x_check: ; Jumps to if positive
    cmp #LINE_DISTANCE
    bcs .line_object_disable

.line_object_distance_y:
    tya
    clc
    sbc LineStartPos+1
    bcs .line_object_distance_y_check
    eor #$FF    ; C flag is clear here
    adc #$01    ; form two's complement
.line_object_distance_y_check: ; Jumps to if positive
    cmp #LINE_DISTANCE
    bcs .line_object_disable

.line_object_boundary:
.line_object_boundary_left:
    cpx #LINE_VEL_X
    bcc .line_object_disable
.line_object_boundary_right:
    cpx #160-LINE_VEL_X
    bcs .line_object_disable
.line_object_boundary_bottom:
    cpy #LINE_VEL_Y
    bcc .line_object_disable
.line_object_boundary_top:
    cpy #KERNEL_SCANLINES-LINE_VEL_Y
    bcs .line_object_disable

.line_object_velocity:

    ; Apply Velocity
    txa
    clc
    adc LineVelocity
    sta LinePosition

    tya
    clc
    adc LineVelocity+1
    sta LinePosition+1

    ; Set Line Position
    ldx #1                  ; Object (missile1)
    lda LinePosition     ; X Position
    jsr PosObject

    jmp .line_object_return

.line_object_disable:
    lda #0
    sta LineEnabled

.line_object_return:
    rts

; Scanline Draw

LineDrawStart:

    ; Set missile 0 to be 2 clock size (4/5 bits)
    lda NUSIZ1
    and #%11001111
    ora #%00010000
    sta NUSIZ1

    rts

LineDraw:

    ; Check if visible
    lda LineEnabled
    cmp #1
    bne .line_draw_off

    ; Check y position
    txa
    sbc LinePosition+1
    cmp #LINE_SIZE*2
    bcc .line_draw_on

.line_draw_off:
    lda #%00000000
    jmp .line_draw_write

.line_draw_on:
    lda #%00000010

.line_draw_write:
    sta ENAM1

.line_draw_return:
    rts

LineClean:

    ; Clear out Line
    lda #0
    sta ENAM1

    rts
