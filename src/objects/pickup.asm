;================
; Pickup (ball)
;================

; Constants

PICKUP_SIZE         = 8
PICKUP_SPAWN_TIME   = 120

PICKUP_SAMPLE_LEN   = 16
PICKUP_SAMPLE_LEN_2 = 8
PICKUP_SAMPLE_C     = 4
PICKUP_SAMPLE_F_1   = 22
PICKUP_SAMPLE_F_2   = 23
PICKUP_SAMPLE_V     = 4

; Initialization

PickupInit:

    ; Initialize Timer
    lda #PICKUP_SPAWN_TIME
    sta FrameTimer+2

    ; Initial Line Control
    lda #0
    sta LineEnabled
    sta PickupPosY
    sta PickupPosX

    rts

; Frame Update

PickupUpdate:

    jsr PickupSample

    bit LineEnabled
    beq .pickup_update_hide
    bvs .pickup_update_on

.pickup_update_spawn:
    lda FrameTimer+2
    bpl .pickup_update_hide
    jsr PickupSpawn
    rts

.pickup_update_on:
    jsr PickupCollision

.pickup_update_hide:
    rts

PickupSpawn:
    lda #%01000000
    sta LineEnabled

.pickup_spawn_rand:
    jsr Random
    lda Rand8
    and #$7f
    sta PickupPosX
    tax
    lda Rand16
    and #$7f
    sta PickupPosY
    tay

    ; Make sure we're at a different y than spider
    cmp SpiderPosY
    bcc .pickup_spawn_set
    clc
    adc #SPIDER_SIZE
    cmp SpiderPosY
    bcs .pickup_spawn_set
    jmp .pickup_spawn_rand

.pickup_spawn_set:
    stx LinePosX
    sty LinePosY

    rts

PickupCollision:
    bit CXP0FB
    bvc .pickup_collision_return

.pickup_collision_set:
    ; Reset Timer
    lda #PICKUP_SPAWN_TIME
    sta FrameTimer+2

    ; Hide Ball
    jsr LineDisable

    ; Apply Player Buff
    ;...

    ; Play Sample
    lda #PICKUP_SAMPLE_LEN
    sta SampleStep
    lda #PICKUP_SAMPLE_C
    sta AUDC1
    lda #PICKUP_SAMPLE_F_1
    sta AUDF1
    lda #PICKUP_SAMPLE_V
    sta AUDV1

.pickup_collision_return:
    rts

PickupSample:
    lda SampleStep
    cmp #PICKUP_SAMPLE_LEN_2
    bne .pickup_sample_return

    lda AUDC1
    cmp #PICKUP_SAMPLE_C
    bne .pickup_sample_return

    lda #PICKUP_SAMPLE_F_2
    sta AUDF1

.pickup_sample_return:
    rts
