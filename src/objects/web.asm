;================
; Web (Playfield)
;================

; Constants

WEB_BG_COLOR        = #$00
WEB_FG_COLOR        = #$06

WEB_SIZE            = 30
WEB_LINES           = KERNEL_SCANLINES-SCORE_LINES
WEB_LINE            = WEB_LINES/WEB_SIZE

; Scanline Draw

WebDrawStart:

    ; Load Colors
    lda #WEB_BG_COLOR
    sta COLUBK
    lda #WEB_FG_COLOR
    sta COLUPF

    ; Mirror playfield and use standard playfield color
    lda CtrlPf
    and #%11111100
    ora #%00000001
    sta CtrlPf
    sta CTRLPF

    ; Initialize image index
    lda #0
    sta WebIndex
    lda #1
    sta WebDir

    rts

WebDraw:

    ldy WebIndex

    ; Draw Image
    lda WebImagePF0,y
    sta PF0
    lda WebImagePF1,y
    sta PF1
    lda WebImagePF2,y
    sta PF2

    ; Increment image index
    clc
    tya
    adc WebDir
    sta WebIndex

    cmp #WEB_SIZE/2
    bne .web_draw_return

    lda #-1
    sta WebDir

    dec WebIndex

.web_draw_return:
    rts

WebClean:

    ; Clear out playfield
    lda #0
    sta PF0
    sta PF1
    sta PF2

    rts

    ; Web Image
    include "objects/web_image.asm"
