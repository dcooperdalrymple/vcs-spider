;======================
; Bugs (missiles 0 & 1)
;======================

; Constants

BUG_SIZE            = 8
BUG_BOUNDARY        = BUG_SIZE
BUG_SPEED           = 2

BUG_COLOR_ACTIVE    = #$CC
BUG_COLOR_CAPTURE   = #$38

; Initialization

BugInit:

    ; Initialize Position
    ldx #1

.bug_init_pos:
    jsr Random

    lda Rand8
    and #$7f
    sta BugPosX,x

    lda Rand16
    and #$7f
    sta BugPosY,x

    dex
    bpl .bug_init_pos

    lda #1
    sta BugEnabled+0
    sta BugEnabled+1

    lda #BUG_COLOR_ACTIVE
    sta BugColor+0
    sta BugColor+1

    rts

; Frame Update

BugUpdate:

    ldx #1
.bug_update:
    stx Temp+0

    jsr BugMovement

    ldx Temp+0
    dex
    bpl .bug_update

    rts

BugMovement:

    ldx Temp+0
    lda BugEnabled,x
    cmp #1
    bne .bug_movement_return

.bug_movement_random:
    jsr Random
    and #%00000011
    sta Temp+1

.bug_movement_load:
    ; Load x and y values
    ldx Temp+0
    lda BugPosX,x
    ldy BugPosY,x
    tax

.bug_movement_x:
    ; Alter X Position
    lda Temp+1
    and #%00000001

.bug_movement_x_left:
    cmp #1
    bne .bug_movement_x_right
    dex
    dex
    jmp .bug_movement_y

.bug_movement_x_right:
    inx
    inx

.bug_movement_y:
    ; Alter Y Position
    lda Temp+1
    and #%00000010
    lsr

.bug_movement_y_up:
    cmp #1
    bne .bug_movement_y_down
    iny
    iny
    jmp .bug_movement_boundary

.bug_movement_y_down:
    dey
    dey

.bug_movement_boundary:

.bug_movement_boundary_left:
    cpx #BUG_BOUNDARY
    bcs .bug_movement_boundary_right
    ldx #BUG_BOUNDARY
    jmp .bug_movement_boundary_top

.bug_movement_boundary_right:
    cpx #(KERNEL_WIDTH/2)-BUG_BOUNDARY-BUG_SIZE
    bcc .bug_movement_boundary_top
    ldx #(KERNEL_WIDTH/2)-BUG_BOUNDARY-BUG_SIZE

.bug_movement_boundary_top:
    cpy #SCORE_LINES+BUG_BOUNDARY+(BUG_SIZE*2)
    bcs .bug_movement_boundary_bottom
    ldy #SCORE_LINES+BUG_BOUNDARY+(BUG_SIZE*2)
    jmp .bug_movement_store

.bug_movement_boundary_bottom:
    cpy #KERNEL_SCANLINES-BUG_BOUNDARY-BUG_SIZE
    bcc .bug_movement_store
    ldy #KERNEL_SCANLINES-BUG_BOUNDARY-BUG_SIZE

.bug_movement_store:
    txa
    ldx Temp+0
    sta BugPosX,x
    sty BugPosY,x

.bug_movement_return:
    rts

; Horizontal Positioning

BugPosition:

    ; Set Position of each missile
    ldy #1
.bug_position:

    ; Determine missile index
    clc
    ldx #2          ; Missile 0/1
    tya
    sta Temp
    txa
    adc Temp
    tax

    lda BugPosX,y
    jsr PosObject

    dey
    bpl .bug_position

    rts

; Scanline Draw

BugDrawStart:

    ; Setup half scanline positions
    ldy #1
.bug_draw_start_pos:
    lda BugPosY,y
    lsr
    sta BugDrawPosBottom,y

    adc #BUG_SIZE/2
    sta BugDrawPosTop,y

    dey
    bpl .bug_draw_start_pos

    rts

BugDraw:

    ldy #1
.bug_draw:
    lda BugEnabled,y
    cmp #1
    bne .bug_draw_return

    ; Divide scanline in half
    txa
    lsr

    cmp BugDrawPosTop,y
    beq .bug_draw_start

    cmp BugDrawPosBottom,y
    beq .bug_draw_end

    jmp .bug_draw_return

.bug_draw_start:
    lda BugColor,y
    sta COLUP0,y

    lda #%00000010
    sta ENAM0,y
    jmp .bug_draw_return

.bug_draw_end:
    lda #%00000000
    sta ENAM0,y

    lda #SPIDER_COLOR
    sta COLUP0,y

.bug_draw_return:
    dey
    bpl .bug_draw

    rts

BugClean:
    lda #0
    sta ENAM0
    rts
