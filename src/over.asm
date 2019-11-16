;================
; Constants
;================

OVER_FRAMES         = 220

OVER_BG_COLOR       = #$00
OVER_FG_COLOR       = #$44

OVER_AUDIO_TONE     = 7
OVER_AUDIO_VOLUME   = 6 ; 15 is max
OVER_AUDIO_LENGTH   = 6
OVER_AUDIO_STEP     = 16

OVER_IMAGE_SIZE     = 9
OVER_IMAGE_LINE_SIZE = 8
OVER_IMAGE_LINES    = OVER_IMAGE_SIZE*OVER_IMAGE_LINE_SIZE
OVER_IMAGE_PADDING  = #(KERNEL_SCANLINES-SCORE_LINES-OVER_IMAGE_LINES)/2

OverInit:

    ; Setup logic and kernel
    SET_POINTER VBlankPtr, OverVerticalBlank
    SET_POINTER KernelPtr, OverKernel
    SET_POINTER OverScanPtr, OverOverScan

    ; Load Colors
    lda #OVER_BG_COLOR
    sta COLUBK
    lda #OVER_FG_COLOR
    sta COLUPF

    ; Load audio settings
    lda #OVER_AUDIO_TONE
    sta AUDC0
    lda #OVER_AUDIO_VOLUME
    sta AUDV0
    lda #0
    sta AUDC1
    sta AUDV1
    lda #0
    sta AudioStep

    ; Play first note
    lda OverAudio0,AudioStep
    sta AUDF0

    ; Setup frame counters
    lda #0
    sta Frame
    lda #OVER_AUDIO_STEP
    sta FrameTimer
    sta Temp+1

    rts

OverVerticalBlank:
    jsr ScoreUpdate
    rts

OverOverScan:
    jsr OverAudio
    jsr OverState
    rts

OverAudio:

    ldx FrameTimer
    cpx #0
    bne .over_audio_return

    ; Reset Timer
    ldx Temp+1
    REPEAT 3
    inx
    REPEND
    stx FrameTimer
    stx Temp+1

.over_audio_play:

    ; Increment melody position
    ldy AudioStep
    iny

    cpy #OVER_AUDIO_LENGTH
    beq .over_audio_mute_note

.over_audio_play_note:

    ; Save current position
    sty AudioStep

    ; Melody Line
    lda OverAudio0,y
    sta AUDF0
    lda #OVER_AUDIO_VOLUME
    sta AUDV0

    rts

.over_audio_mute_note:
    lda #0
    sta AUDF0
    sta AUDV0

.over_audio_return:
    rts

OverState:
    lda Frame
    cmp #OVER_FRAMES
    bne .over_state_return

;    jsr TitleInit
    jsr GameInit

.over_state_return:
    rts

OverKernel:

    ; Turn on display
    lda #0
    sta VBLANK

.over_kernel_score:

    ; Draw Score on top first (no update)
    jsr ScoreDraw

.over_kernel_init:
    ; Playfield Control
    lda CtrlPf
    and #%11111101 ; Use playfield foreground color
    ora #%00000001 ; Set mirroring
    sta CtrlPf
    sta CTRLPF

.over_kernel_top_padding:
    ; Top Padding
    jsr OverPadding

.over_kernel_image:
    ldx #OVER_IMAGE_SIZE-1

.over_kernel_image_next:
    lda OverImagePF2,x
    sta PF2
    lda OverImagePF1,x
    sta PF1
;    lda OverImagePF0,x
;    sta PF0

    ldy #OVER_IMAGE_LINE_SIZE
.over_kernel_image_loop:
    sta WSYNC
    dey
    bne .over_kernel_image_loop

    dex
    bpl .over_kernel_image_next

.over_kernel_bottom_padding:
    ; Bottom Padding
    jsr OverPadding

.over_kernel_return:
    sta WSYNC   ; This extra line is to account for constant rounding
    rts

OverPadding:
    lda #0
    sta PF0
    sta PF1
    sta PF2

    ldx #OVER_IMAGE_PADDING
.over_padding_loop:
    sta WSYNC
    dex
    bne .over_padding_loop

    rts

OverAssets:

    ; Assets
    include "over_image.asm"

OverAudio0:

    .BYTE #12   ; D#2
    .BYTE #13   ; D2
    .BYTE #17   ; A1
    .BYTE #22   ; F1
    .BYTE #26   ; D1
    .BYTE #26
