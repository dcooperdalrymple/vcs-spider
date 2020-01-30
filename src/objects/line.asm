;================
; Line (ball)
;================

; Constants

LINE_SIZE       = 4
LINE_DISTANCE   = 64    ; Distance from player
LINE_VEL_X      = 4
LINE_VEL_Y      = 4

LINE_AUDIO_C    = 8
LINE_AUDIO_F    = 1
LINE_AUDIO_V    = 4

LINE_SAMPLE_LEN = 8
LINE_SAMPLE_C   = 3
LINE_SAMPLE_F   = 1
LINE_SAMPLE_V   = 4

; Initialization

LineInit:

    ; Initial Line Control
    lda #0
    sta LineEnabled
    sta LinePos+0
    sta LinePos+1
    sta LineVelocity+0
    sta LineVelocity+1
    sta LineStartPos+0
    sta LineStartPos+1
    sta LineDrawPos+0
    sta LineDrawPos+1

    rts

; Frame Update

LineUpdate:
    jsr LineControl
    jsr LineObject
    jsr LineCollision
    rts

LineControl:

    ; Check if Fire Button on controller 1 is pressed
    lda INPT4
    bmi .line_control_skip

    bit LineEnabled
    bmi .line_control_skip

    lda SpiderCtrl
    cmp #0
    bne .line_control_fire

.line_control_skip:
    jmp .line_control_return

.line_control_fire:
    jsr LineEnable

.line_control_x:
    lda SpiderCtrl
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
    lda SpiderCtrl
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

    lda SpiderCtrl
    and #%11110000

.line_control_position_left:
    cmp #%10000000
    bne .line_control_position_right

    ldx #LINE_SIZE
    ldy #SPIDER_SIZE
    jmp .line_control_position_store

.line_control_position_right:
    cmp #%01000000
    bne .line_control_position_top

    ldx #SPIDER_SIZE*2
    ldy #SPIDER_SIZE
    jmp .line_control_position_store

.line_control_position_top:
    cmp #%00100000
    bne .line_control_position_bottom

    ldx #SPIDER_SIZE
    ldy #SPIDER_SIZE*2
    jmp .line_control_position_store

.line_control_position_bottom:
    cmp #%00010000
    bne .line_control_position_top_right

    ldx #SPIDER_SIZE
    jmp .line_control_position_store

.line_control_position_top_right:
    cmp #%01100000
    bne .line_control_position_bottom_right

    ldx #SPIDER_SIZE*2
    ldy #SPIDER_SIZE*2
    jmp .line_control_position_store

.line_control_position_bottom_right:
    cmp #%01010000
    bne .line_control_position_bottom_left

    ldx #SPIDER_SIZE*2
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
    ldy #SPIDER_SIZE*2

.line_control_position_store:

    ; Apply offsetX to playerX
    lda SpiderPos
    stx Temp
    clc
    adc Temp
    tax

    ; Apply offsetY to playerY
    lda SpiderPos+1
    sty Temp
    clc
    adc Temp
    tay

    stx LinePos
    sty LinePos+1
    stx LineStartPos
    sty LineStartPos+1

.line_control_return:
    rts

LineObject:

    ; Check if line is enabled
    bit LineEnabled
    bpl .line_object_return

    ; Load position
    ldx LinePos
    ldy LinePos+1

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
    sta LinePos

    tya
    clc
    adc LineVelocity+1
    sta LinePos+1

    jmp .line_object_return

.line_object_disable:
    jsr LineDisable

.line_object_return:
    rts

LineCollision:

    lda #BUG_STUN_LENGTH

.line_collision_m0:
    bit CXM0FB
    bvc .line_collision_m1

    ; Set stun timer
    sta BugStunned+0

    ; Disable line
    jsr LineDisable
    jmp .line_collision_sample

.line_collision_m1:
    bit CXM1FB
    bvc .line_collision_return

    ; Set stun timer
    sta BugStunned+1

    ; Disable line
    jsr LineDisable

.line_collision_sample:
    jsr LineSample

.line_collision_return:
    rts

LinePosition:

    ; Set Line Position
    ldx #4                  ; Object (ball)
    lda LinePos        ; X Position
    jsr PosObject

    rts

; Scanline Draw

LineDrawStart:

    ; Set ball size to be 4 clocks (4/5 bits)
    lda CtrlPf
    and #%11001111
    ora #%00100000
    sta CtrlPf
    sta CTRLPF

    ; Determine if we need to use vertical delay (oven line)
    lda LinePos+1
    lsr
    bcc .line_draw_start_nodelay

    ldy #1
    jmp .line_draw_start_set_delay

.line_draw_start_nodelay:
    ldy #0

.line_draw_start_set_delay:
    sty VDELBL

.line_draw_start_pos:
    ; Calculate starting position
    clc
    sta LineDrawPos+0
    adc #LINE_SIZE/2
    sta LineDrawPos+1

    rts

LineDraw:

    ldy #%00000000

    ; Check if visible
    bit LineEnabled
    bpl .line_draw_off

    ; Load half scanline
;    lda Temp+1

    ; Top
    cmp LineDrawPos+1
    bcs .line_draw_off

    ; Bottom
    cmp LineDrawPos+0
    bcc .line_draw_off

.line_draw_on:
    ldy #%00000010

.line_draw_off:
    sty ENABL

    rts

LineClean:

    ; Clear out Line
    lda #0
    sta ENABL

    rts

LineEnable:
    lda #%10000000
    sta LineEnabled

    lda SampleStep
    cmp #0
    bne .line_enable_return

    jsr LineAudioPlay

.line_enable_return:
    rts

LineDisable:
    lda #0
    sta LineEnabled

    lda SampleStep
    cmp #0
    bne .line_disable_return

    jsr LineAudioMute

.line_disable_return:
    rts

LineAudioPlay:
    lda #LINE_AUDIO_C
    sta AUDC1
    lda #LINE_AUDIO_F
    sta AUDF1
    lda #LINE_AUDIO_V
    sta AUDV1
    rts

LineAudioMute:
    lda #0
    sta AUDV1
    sta AUDF1
    sta AUDC1
    rts

LineSample:
    lda #LINE_SAMPLE_LEN
    sta SampleStep
    lda #LINE_SAMPLE_C
    sta AUDC1
    lda #LINE_SAMPLE_F
    sta AUDF1
    lda #LINE_SAMPLE_V
    sta AUDV1
    rts
