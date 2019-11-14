;================
; Web (Playfield)
;================

; Constants

WEB_BG_COLOR        = #$00
WEB_FG_COLOR        = #$06

WEB_SIZE            = KERNEL_SCANLINES-SCORE_LINES
WEB_LINE            = WEB_SIZE/30

; Variables

    SEG.U web_vars
    org $92

WebIndex            ds 1

    SEG
    org $F4A2

; Scanline Draw

WebDrawStart:

    ; Load Colors
    lda #WEB_BG_COLOR
    sta COLUBK
    lda #WEB_FG_COLOR
    sta COLUPF

    ; Mirror playfield
    lda #%00000001 ; Mirrored
    sta CTRLPF

    ; Initialize image index
    lda #0
    sta WebIndex

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

    ; Increment and store image index
    iny
    sty WebIndex

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
