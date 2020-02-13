;================
; Web (Playfield)
;================

; Constants

WEB_BG_COLOR        = #$00
WEB_FG_COLOR        = #$02

WEB_SIZE            = 28
WEB_LINES           = KERNEL_SCANLINES-SCORE_LINES
WEB_LINE            = WEB_LINES/WEB_SIZE

; Scanline Draw

WebDrawStart:

    ; Load Colors
    lda WebColor+1
    sta COLUPF

    ; Mirror playfield and use standard playfield color
    ;lda CtrlPf
    ;and #%11111100
    ;ora #%00000001
    ;sta CtrlPf
    ;sta CTRLPF

    ; Initialize image index
    lda #0
    sta WebIndex

    rts
