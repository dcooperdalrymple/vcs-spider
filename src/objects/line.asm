;================
; Line (ball)
;================

; Constants

LINE_SIZE       = 8
#if SYSTEM = NTSC
LINE_VEL_X      = 4
LINE_VEL_Y      = 4
#endif
#if SYSTEM = PAL
LINE_VEL_X      = 3
LINE_VEL_Y      = 3
#endif

LINE_AUDIO_C    = 8
LINE_AUDIO_F    = 1
LINE_AUDIO_V    = 4

#if SYSTEM = NTSC
LINE_SAMPLE_LEN = 8
#endif
#if SYSTEM = PAL
LINE_SAMPLE_LEN = 7
#endif
LINE_SAMPLE_C   = 3
LINE_SAMPLE_F   = 1
LINE_SAMPLE_V   = 4

; Initialization

LineInit:

    ; Initial Line Control
    lda #0
    sta LineEnabled
    ;sta LinePosX
    ;sta LinePosY

    ; Initial direction
    ;lda #0
    ;sta LineVelocity+0
    ;lda #LINE_VEL_Y
    ;sta LineVelocity+1

    ; Disable line at start
    ;lda #-1
    ;sta LineDrawPos+0
    ;sta LineDrawPos+1

    rts

; Frame Update

LineUpdate:
    jsr LineControl
    jsr LineObject
    jsr LineCollision
    rts

LineControl:

    ; If in two player mode, no fire is required
    bit GameType
    bmi .line_control_check_enabled

.line_control_check_fire:
    ; Check if Fire Button on controller 0 is pressed
    lda INPT4
    bmi .line_control_skip

.line_control_check_enabled:
    bit LineEnabled
    bmi .line_control_skip

    bit GameType
    bmi .line_control_check_ctrl_1

.line_control_check_ctrl_0:
    lda SpiderCtrl
    jmp .line_control_check_ctrl

.line_control_check_ctrl_1:
    lda SWCHA
    eor #$ff ; invert bits
    REPEAT 4
    asl
    REPEND
    and #%11110000

.line_control_check_ctrl:
    sta Temp+3
    bne .line_control_fire

.line_control_skip:
    rts

.line_control_fire:
    jsr LineEnable

.line_control_x:
    lda #%11000000
    bit Temp+3
    beq .line_control_x_none
.line_control_x_right:
    bpl .line_control_x_left
    lda #LINE_VEL_X
    jmp .line_control_x_store
.line_control_x_left:
    lda #-LINE_VEL_X
    jmp .line_control_x_store
.line_control_x_none:
    lda #0
.line_control_x_store:
    sta LineVelocity

.line_control_y:
    lda Temp+3
    and #%00110000
    beq .line_control_y_none
.line_control_y_down:
    cmp #%00100000
    bne .line_control_y_up
    lda #-LINE_VEL_Y
    jmp .line_control_y_store
.line_control_y_up:
    lda #LINE_VEL_Y
    jmp .line_control_y_store
.line_control_y_none:
    lda #0
.line_control_y_store:
    sta LineVelocity+1

.line_control_position:

    ldx #0 ; offsetX
    ldy #0 ; offsetY

    lda Temp+3

.line_control_position_left:
    cmp #%01000000
    bne .line_control_position_right

    ldx #0
    ldy #SPIDER_SIZE-LINE_SIZE/2
    jmp .line_control_position_store

.line_control_position_right:
    cmp #%10000000
    bne .line_control_position_top

    ldx #SPIDER_SIZE-LINE_SIZE/2
    ldy #SPIDER_SIZE-LINE_SIZE/2
    jmp .line_control_position_store

.line_control_position_top:
    cmp #%00010000
    bne .line_control_position_bottom

    ldx #SPIDER_SIZE/2
    ldy #SPIDER_SIZE
    jmp .line_control_position_store

.line_control_position_bottom:
    cmp #%00100000
    bne .line_control_position_top_right

    ldx #SPIDER_SIZE/2
    jmp .line_control_position_store

.line_control_position_top_right:
    cmp #%10010000
    bne .line_control_position_bottom_right

    ldx #SPIDER_SIZE
    ldy #SPIDER_SIZE+LINE_SIZE*2
    jmp .line_control_position_store

.line_control_position_bottom_right:
    cmp #%10100000
    bne .line_control_position_bottom_left

    ldx #SPIDER_SIZE-LINE_SIZE/2
    ldy #0
    jmp .line_control_position_store

.line_control_position_bottom_left:
    cmp #%01100000
    bne .line_control_position_top_left

    ; No Offset
    ldx #LINE_SIZE/2
    ldy #LINE_SIZE/2
    jmp .line_control_position_store

.line_control_position_top_left:
    cmp #%01010000
    bne .line_control_position_store

    ldx #0
    ldy #SPIDER_SIZE+LINE_SIZE*3/2

.line_control_position_store:

    ; Apply offsetX to playerX
    lda SpiderPosX
    stx Temp
    clc
    adc Temp
    tax

    ; Apply offsetY to playerY
    lda SpiderPosY
    sty Temp
    clc
    adc Temp
    tay

    stx LinePosX
    sty LinePosY

.line_control_return:
    rts

LineObject:

    ; Check if line is enabled
    bit LineEnabled
    bpl .line_object_return

    ; Load position
    ldx LinePosX
    ldy LinePosY

.line_object_boundary:
.line_object_boundary_left:
    cpx #LINE_VEL_X
    bcc .line_object_disable
.line_object_boundary_right:
    cpx #160-LINE_VEL_X-1
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
    sta LinePosX

    tya
    clc
    adc LineVelocity+1
    sta LinePosY

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
    lda #LINE_SAMPLE_LEN
    sta SampleStep
    lda #LINE_SAMPLE_C
    sta AUDC1
    lda #LINE_SAMPLE_F
    sta AUDF1
    lda #LINE_SAMPLE_V
    sta AUDV1

.line_collision_return:
    rts

; Scanline Draw

LineDrawStart:

    bit LineEnabled
    bmi .line_draw_start

    lda #-1
    sta LineDrawPos+0
    sta LineDrawPos+1
    rts

.line_draw_start:
    ; Determine if we need to use vertical delay (oven line)
    lda LinePosY
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

LineEnable:
    lda #%10000000
    sta LineEnabled

    lda SampleStep
    bne .line_enable_return

    ; Play line audio
    lda #LINE_AUDIO_C
    sta AUDC1
    lda #LINE_AUDIO_F
    sta AUDF1
    lda #LINE_AUDIO_V
    sta AUDV1

.line_enable_return:
    rts

LineDisable:
    lda #0
    sta LineEnabled

    ldx SampleStep
    bne .line_disable_return

    ; Mute audio
    ;lda #0
    sta AUDV1
    ;sta AUDF1
    ;sta AUDC1

.line_disable_return:
    rts
