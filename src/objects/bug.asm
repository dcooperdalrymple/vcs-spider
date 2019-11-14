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

    ; Initial Position
    lda #60
    sta BugPos
    sta BugPos+1

    lda #1
    sta BugEnabled

    lda #BUG_COLOR_ACTIVE
    sta BugColor

    rts

; Frame Update

BugUpdate:
    jsr BugMovement
    rts

BugMovement:

    lda BugEnabled
    cmp #1
    bne .bug_movement_return

.bug_movement_random:
    jsr Random
    and #%00000011
    sta Temp

.bug_movement_load:
    ; Load x and y values
    ldx BugPos
    ldy BugPos+1

.bug_movement_x:
    ; Alter X Position
    lda Temp
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
    lda Temp
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
    stx BugPos
    sty BugPos+1

.bug_movement_return:
    rts

; Horizontal Positioning

BugPosition:

    ; Set Position
    ldx #2          ; Missile 0
    lda BugPos
    jsr PosObject

    rts

; Scanline Draw

BugDrawStart:

    ; Setup half scanline positions
    lda BugPos+1    ; Y Position
    lsr
    sta BugDrawPos

    adc #BUG_SIZE/2
    sta BugDrawPos+1

    rts

BugDraw:

    lda BugEnabled
    cmp #1
    bne .bug_draw_return

    ; Divide y in half
    txa
    lsr

    cmp BugDrawPos+1
    beq .bug_draw_start

    cmp BugDrawPos
    beq .bug_draw_end

    rts

.bug_draw_start:
    lda BugColor
    sta COLUP0

    lda #%00000010
    sta ENAM0
    rts

.bug_draw_end:
    lda #%00000000
    sta ENAM0

    lda #SPIDER_COLOR
    sta COLUP0

    rts

.bug_draw_return:
    rts

BugClean:
    lda #0
    sta ENAM0
    rts
