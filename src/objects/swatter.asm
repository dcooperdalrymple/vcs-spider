;==================
; Swatter (player1)
;==================

; Constants

SWATTER_COLOR           = #$30
SWATTER_BW_COLOR        = #$0E
SWATTER_HOLD_COLOR      = #$36
SWATTER_HOLD_BW_COLOR   = #$04

SWATTER_SPRITE_SIZE     = #20
SWATTER_SIZE            = #SWATTER_SPRITE_SIZE*2

SWATTER_HOLD_TIME       = 60
SWATTER_ACTIVE_TIME     = 60/2

SWATTER_STATE_WAIT      = #%00000000
SWATTER_STATE_HOLD      = #%10000000
SWATTER_STATE_ACTIVE    = #%11000000

SWATTER_HOLD_SAMPLE_C   = 2
SWATTER_HOLD_SAMPLE_V   = 4
SWATTER_HOLD_SAMPLE_F_MIN   = 21 ; Starting frequency
SWATTER_HOLD_SAMPLE_F_MAX   = 1
SWATTER_HOLD_SAMPLE_LEN = #SWATTER_HOLD_TIME/(SWATTER_HOLD_SAMPLE_F_MIN-SWATTER_HOLD_SAMPLE_F_MAX) ; Time between each frequency

SWATTER_ACTIVE_SAMPLE_LEN   = 20
SWATTER_ACTIVE_SAMPLE_C     = 8 ; 15
SWATTER_ACTIVE_SAMPLE_F     = 12 ; 5
SWATTER_ACTIVE_SAMPLE_V     = 4

SWATTER_HIT_SAMPLE_LEN   = 20
SWATTER_HIT_SAMPLE_C     = 3
SWATTER_HIT_SAMPLE_F     = 6
SWATTER_HIT_SAMPLE_V     = 4

; Initialization

;SwatterInit:
;    jsr SwatterReset
;    rts

; Frame Update

SwatterUpdate:

    ; Check b/w
    lda SWCHB
    and #%00001000
    beq .swatter_update_bw

.swatter_update_color:
    lda SwatterState
    cmp #SWATTER_STATE_ACTIVE
    bne .swatter_update_color_hold
.swatter_update_color_active:
    lda #SWATTER_COLOR
    jmp .swatter_update_color_set
.swatter_update_color_hold:
    lda #SWATTER_HOLD_COLOR
    jmp .swatter_update_color_set

.swatter_update_bw:
    lda SwatterState
    cmp #SWATTER_STATE_HOLD
    bne .swatter_update_bw_active
.swatter_update_bw_hold:
    lda #SWATTER_HOLD_BW_COLOR
    jmp .swatter_update_color_set
.swatter_update_bw_active:
    lda #SWATTER_BW_COLOR

.swatter_update_color_set:
    sta SwatterColor

.swatter_update_hold_sample:
    ldy SwatterState
    cpy #SWATTER_STATE_HOLD
    bne .swatter_update_state

    dec SwatterSampleCount
    bne .swatter_update_state

    lda #SWATTER_HOLD_SAMPLE_LEN
    sta SwatterSampleCount

    dec SwatterSampleF
    ldy SwatterSampleF
    jsr SwatterHoldSample

.swatter_update_state:
    ldx FrameTimer+1
    bne .swatter_update_collision

    ldy SwatterState
    cpy #SWATTER_STATE_WAIT
    beq .swatter_update_state_wait

    cpy #SWATTER_STATE_HOLD
    beq .swatter_update_state_hold

    ; Else we're at the end of the active state
    jsr SwatterReset
    jmp .swatter_update_return

.swatter_update_state_wait:
    ldy #SWATTER_HOLD_SAMPLE_F_MIN
    sty SwatterSampleF
    jsr SwatterHoldSample

    lda #SWATTER_HOLD_SAMPLE_LEN
    sta SwatterSampleCount

    lda #SWATTER_STATE_HOLD
    ldx SwatterHoldTime
    jmp .swatter_update_state_set

.swatter_update_state_hold:
    ; Play Swatter Active Sample
    lda #SWATTER_ACTIVE_SAMPLE_LEN
    sta SampleStep
    lda #SWATTER_ACTIVE_SAMPLE_C
    sta AUDC1
    lda #SWATTER_ACTIVE_SAMPLE_F
    sta AUDF1
    lda #SWATTER_ACTIVE_SAMPLE_V
    sta AUDV1

    lda #SWATTER_STATE_ACTIVE
    ldx #SWATTER_ACTIVE_TIME

.swatter_update_state_set:
    sta SwatterState
    stx FrameTimer+1

.swatter_update_collision:
    ; Check 1 frame after active
    lda SwatterState
    cmp #SWATTER_STATE_ACTIVE
    bne .swatter_update_return
    ldx FrameTimer+1
    cpx #SWATTER_ACTIVE_TIME-1
    bne .swatter_update_return

    jsr SwatterCollision

.swatter_update_return:
    rts

SwatterCollision:
    bit CXM0P
    bmi .swatter_collision_m0

    bit CXM1P
    bvs .swatter_collision_m1

    bit CXPPMM
    bmi .swatter_collision_p0

    rts

.swatter_collision_m0:
    ldx #0
    jmp .swatter_collision_bug_reset

.swatter_collision_m1:
    ldx #1

.swatter_collision_bug_reset:
    jsr BugReset
    jmp .swatter_collision_active

.swatter_collision_p0:

    lda ScoreValue
    cmp SwatterHitDamage
    bcc .swatter_collision_p0_zero
    ;beq .swatter_collision_p0_zero

    clc
    sbc SwatterHitDamage
    jmp .swatter_collision_p0_set

.swatter_collision_p0_zero:
    lda #0

.swatter_collision_p0_set:
    sta ScoreValue

.swatter_collision_active:
    ; Player swatter hit sample
    lda #SWATTER_HIT_SAMPLE_LEN
    sta SampleStep
    lda #SWATTER_HIT_SAMPLE_C
    sta AUDC1
    lda #SWATTER_HIT_SAMPLE_F
    sta AUDF1
    lda #SWATTER_HIT_SAMPLE_V
    sta AUDV1

    rts

; Scanline Draw

SwatterDrawStart:

    ; Set sprite color
    lda SwatterColor
    sta COLUP1

    ; Hide swatter if wait state
    bit SwatterState
    bmi .swatter_draw_start

    lda #-1
    sta SwatterIndex
    ;sta SwatterDrawPos
    lda #0
    sta SwatterLine

    rts

.swatter_draw_start:

    ; Note: Doesn't need vertical delay

    ; Calculate starting position
    lda SwatterPosY         ; Y Position
    lsr
    clc
    adc #SWATTER_SPRITE_SIZE
    sta SwatterDrawPos

    ; Initialize sprite index
    lda #SWATTER_SPRITE_SIZE-1
    sta SwatterIndex
    lda #0
    sta SwatterLine

    rts

SwatterReset:
    ; Initialize Swatter State
    lda #SWATTER_STATE_WAIT
    sta SwatterState

    ; Set Wait Timer
    jsr Random
    lda Rand8
    and #$3f
    clc
    adc SwatterWaitTime
    sta FrameTimer+1

    ; Set Random Position
    jsr Random
    lda Rand8           ; X Position
    and #$7f
    sta SwatterPosX
    lda Rand16          ; Y Position
    and #$7e            ; Ensure that Y position is even
    sta SwatterPosY

    rts

SwatterHoldSample:
    lda #SWATTER_HOLD_SAMPLE_LEN
    sta SampleStep
    lda #SWATTER_HOLD_SAMPLE_C
    sta AUDC1
    lda #SWATTER_HOLD_SAMPLE_V
    sta AUDV1

    sty AUDF1 ; Store value of y as frequency

    rts
