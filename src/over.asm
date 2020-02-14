;================
; Constants
;================

OVER_BG_COLOR       = #$00
OVER_FG_COLOR       = #$44
OVER_FG_BW_COLOR    = #$06

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

    ; Load audio settings
    lda #OVER_AUDIO_TONE
    sta AUDC0
    ;lda #OVER_AUDIO_VOLUME
    ;sta AUDV0
    lda #0
    ;sta AUDC1
    sta AUDV1

    ; Set initial button state
    ;lda #0
    sta InputState

    ; Setup frame counters
    lda #1
    sta FrameTimer
    lda #OVER_AUDIO_STEP
    sta SampleStep
    lda #OVER_AUDIO_LENGTH
    sta AudioStep

    rts

OverVerticalBlank:
    jsr ScoreUpdate

    ; Load Colors
    lda #OVER_BG_COLOR
    sta COLUBK

    ; Check b/w
    lda SWCHB
    and #%00001000
    beq .over_bw

.over_color:
    lda #OVER_FG_COLOR
    sta COLUPF

    rts

.over_bw:
    ; Load b/w Colors
    lda #OVER_FG_BW_COLOR
    sta COLUPF

    rts

OverOverScan:
    jsr OverAudio
    jsr OverState
    rts

OverAudio:

    lda FrameTimer
    bne .over_audio_return

    ; Reset Timer
    REPEAT 3
    inc SampleStep
    REPEND
    lda SampleStep
    sta FrameTimer

.over_audio_play:

    ; Increment melody position
    ldy AudioStep
    beq .over_audio_mute_note
    dec AudioStep
    dey

.over_audio_play_note:

    ; Melody Line
    lda OverAudio0,y
    sta AUDF0
    lda #OVER_AUDIO_VOLUME
    sta AUDV0

    rts

.over_audio_mute_note:
    lda #0
    ;sta AUDF0
    sta AUDV0

.over_audio_return:
    rts

OverState:

    ; Check to see if audio has finished
    lda AudioStep
    bne .over_state_return

    ldx #1
.over_state:
    ; Check if Fire Button on controller 1 is released
    lda INPT4,x
    bmi .over_state_check

.over_state_on:
    lda #1
    sta InputState,x
    rts

.over_state_check:
    lda InputState,x
    bne .over_state_next

.over_state_loop:
    dex
    bpl .over_state
    rts

.over_state_next:
    ; Button is released, load title screen
    jsr TitleInit

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
    ;lda CtrlPf
    ;and #%11111101 ; Use playfield foreground color
    ;ora #%00000001 ; Set mirroring
    ;sta CtrlPf
    lda #%00000001
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
    sta WSYNC ; Add extra line to get to 262
    jsr OverPadding

.over_kernel_return:
    sta WSYNC   ; This extra line is to account for constant rounding
    rts

OverPadding:
    lda #0
    ;sta PF0
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

    .BYTE #26   ; D1
    .BYTE #26
    .BYTE #22   ; F1
    .BYTE #17   ; A1
    .BYTE #13   ; D2
    .BYTE #12   ; D#2
