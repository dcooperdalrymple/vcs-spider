;==================
; Swatter (player1)
;==================

; Constants

SWATTER_COLOR           = #$36
SWATTER_HOLD_COLOR      = #$30
SWATTER_SIZE            = 10
SWATTER_SPRITE_SIZE     = 10

SWATTER_WAIT_TIME       = 60*3 ; 60 frames per second
SWATTER_HOLD_TIME       = 60
SWATTER_ACTIVE_TIME     = 60/2

SWATTER_STATE_WAIT      = 0
SWATTER_STATE_HOLD      = 1
SWATTER_STATE_ACTIVE    = 2

; Initialization

SwatterInit:

    jsr SwatterReset

    rts

; Frame Update

SwatterUpdate:

.swatter_update_color:
    lda SwatterState
    cmp #SWATTER_STATE_HOLD
    bne .swatter_update_color_active
.swatter_update_color_hold:
    lda #SWATTER_HOLD_COLOR
    jmp .swatter_update_color_set
.swatter_update_color_active:
    lda #SWATTER_COLOR
.swatter_update_color_set:
    sta SwatterColor

.swatter_update_state:
    ldx FrameTimer+1
    cpx #0
    bne .swatter_update_return

    ldy SwatterState
    cpy #SWATTER_STATE_WAIT
    beq .swatter_update_state_wait
    cpy #SWATTER_STATE_HOLD
    beq .swatter_update_state_hold

    ; Else we're at the end of the active state
    jsr SwatterReset
    jmp .swatter_update_return

.swatter_update_state_wait:
    lda #SWATTER_STATE_HOLD
    ldx #SWATTER_HOLD_TIME
    jmp .swatter_update_state_set

.swatter_update_state_hold:
    lda #SWATTER_STATE_ACTIVE
    ldx #SWATTER_ACTIVE_TIME

.swatter_update_state_set:
    sta SwatterState
    stx FrameTimer+1

.swatter_update_return:
    rts

SwatterPosition:

    ; Set Position
    ldx #1              ; Object (player1)
    lda SwatterPos      ; X Position
    jsr PosObject

    rts

; Scanline Draw

SwatterDrawStart:

    ; Set player 1 to be quad size
    lda NuSiz1
    and #%11111000
    ora #%00000111
    sta NuSiz1
    sta NUSIZ1

    ; Set sprite color
    lda SwatterColor
    sta COLUP1

    ; Note: Doesn't need vertical delay

    ; Calculate starting position
    lda SwatterPos+1        ; Y Position
    lsr
    clc
    adc #SWATTER_SIZE
    sta SwatterDrawPos

    ; Initialize sprite index
    lda #0
    sta SwatterIndex

    rts

SwatterDraw:

    lda SwatterState
    cmp #SWATTER_STATE_WAIT
    beq .swatter_draw_return

    ldy SwatterIndex
    cpy #(SWATTER_SPRITE_SIZE*2)
    beq .swatter_draw_blank     ; At end of sprite
    bcs .swatter_draw_return    ; Completed drawing sprite
    cpy #0
    bne .swatter_draw_line

    ; Use half scanline
    lda Temp+1

    sbc SwatterDrawPos
    bpl .swatter_draw_return    ; Not yet to draw sprite

.swatter_draw_line:
    tya
    lsr
    bcs .swatter_draw_skip
    tay

    lda SwatterSprite,y
    sta GRP1

.swatter_draw_skip:
    ldy SwatterIndex
    iny
    sty SwatterIndex
    rts ; Early return

.swatter_draw_blank:
;    lda #0
;    sta GRP1

    ; Push index to be one above
    iny
    sty SwatterIndex

.swatter_draw_return:
    rts

SwatterClean:

    ; Clear out Player1 sprite
    lda #0
    sta GRP1

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
    adc #SWATTER_WAIT_TIME
    sta FrameTimer+1

    ; Set Random Position
    jsr Random
    lda Rand8           ; X Position
    and #$7f
    sta SwatterPos+0
    lda Rand16          ; Y Position
    and #$7e            ; Ensure that Y position is even
    sta SwatterPos+1

    rts

    ; Swatter Sprites
    include "objects/swatter_sprite.asm"
