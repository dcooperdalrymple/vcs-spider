;================
; Constants
;================

TITLE_LINE_SIZE     = 8
TITLE_DATA_SIZE     = %00000100
TITLE_BORDER        = 1
TITLE_PAD           = 4
TITLE_IMAGE         = 6
TITLE_GAP           = 2

TITLE_BG_COLOR      = #$70
TITLE_BD_COLOR      = #$7E
TITLE_FG_COLOR      = #$0E

TITLE_AUDIO_0_TONE    = 4
TITLE_AUDIO_0_VOLUME  = 4
TITLE_AUDIO_1_VOLUME  = 7
TITLE_AUDIO_LENGTH    = 16
TITLE_AUDIO_STEP      = 9

TitleInit:

    ; Setup logic and kernel
    SET_POINTER VBlankPtr, TitleVerticalBlank
    SET_POINTER KernelPtr, TitleKernel
    SET_POINTER OverScanPtr, TitleOverScan

    ; Load Colors
    lda #TITLE_BG_COLOR
    sta COLUBK
    lda #TITLE_FG_COLOR
    sta COLUPF

    ; Load audio settings

    ; Melody Line
    lda #TITLE_AUDIO_0_TONE
    sta AUDC0
    lda #TITLE_AUDIO_0_VOLUME
    sta AUDV0

    ; Drums and Bass
    lda #0
    sta AUDC1
    sta AUDV1

    ; Make it so that we play the first note immediately
    lda #TITLE_AUDIO_LENGTH-1
    sta AudioStep
    lda #1
    sta FrameTimer

    rts

TitleVerticalBlank:
    rts

TitleOverScan:
    jsr TitleAudio
    jsr TitleState
    rts

TitleAudio:

    ldx FrameTimer
    cpx #0
    bne .title_audio_return

    ; Reset Timer
    ldx #TITLE_AUDIO_STEP
    stx FrameTimer

.title_audio_play:

    ; Increment melody position
    ldy AudioStep
    iny

    ; Check if we're at the end of the melody
    cpy #TITLE_AUDIO_LENGTH
    bne .title_audio_play_note

    ; Loop our audio step
    ldy #0

.title_audio_play_note:

    ; Save current position
    sty AudioStep

    ; Basic Melody Line
    lda TitleAudio0,y
    sta AUDF0

    ; Drums and Bass
    lda TitleTone1,y
    cmp #$FF
    beq .title_audio_play_note_1_mute

    sta AUDC1
    lda TitleAudio1,y
    sta AUDF1
    lda #TITLE_AUDIO_1_VOLUME
    sta AUDV1

    jmp .title_audio_return

.title_audio_play_note_1_mute:

    lda #0
    sta AUDF1
    sta AUDC1
    sta AUDV1

.title_audio_return:
    rts

TitleState:
    ; Check if Fire Button on controller 1 is pressed
    lda INPT4
    bmi .title_state_return

    jsr GameInit

.title_state_return:
    rts

TitleKernel:

    ; Playfield Control
    lda #%00000000 ; No mirroring
    sta CTRLPF

    ; Start Counters
    ldx #KERNEL_IMAGE_LINE ; Scanline Counter
    ldy #0 ; Image Counter

    ; Turn on display
    lda #0
    sta VBLANK

    sta WSYNC

.title_kernel_image:

    ; 76 machine cycles per scanline
    sta WSYNC

.title_kernel_image_load: ; 66 cycles

    ; First half of image
    lda TitleImage,y ; 5
    sta PF0 ; 4
    lda TitleImage+1,y ; 5
    sta PF1 ; 4
    lda TitleImage+2,y ; 5
    sta PF2 ; 4

    sleep 6

    ; Second half of image
    lda TitleImage+3,y ; 5
    sta PF0 ; 4
    lda TitleImage+4,y ; 5
    sta PF1 ; 4
    lda TitleImage+5,y ; 5
    sta PF2 ; 4

.title_kernel_image_index: ; 4 cycles

    dex ; 2
    bne .title_kernel_image ; 2

.title_kernel_image_index_next: ; 6 cycles

    ; Restore scanline counter
    ldx #KERNEL_IMAGE_LINE ; 2

    tya ; 2
    clc ; 2
    adc #KERNEL_IMAGE_FULL_DATA ; 2
    tay ; 2
    cpy #KERNEL_IMAGE_SIZE*KERNEL_IMAGE_FULL_DATA
    bne .title_kernel_image ; 2

.title_kernel_image_clean:

    ; Clear out playfield
    lda #0
    sta PF0
    sta PF1
    sta PF2

.title_kernel_image_return:
    rts

TitleAssets:

    ; Assets
    include "title_image.asm"

TitleAudio0:

    .BYTE #15   ; B
    .BYTE #19   ; G
    .BYTE #23   ; E
    .BYTE #19   ; G
    .BYTE #14   ; C
    .BYTE #19
    .BYTE #23
    .BYTE #19
    .BYTE #12   ; D
    .BYTE #19
    .BYTE #23
    .BYTE #19
    .BYTE #14   ; C
    .BYTE #19
    .BYTE #23
    .BYTE #19

TitleTone1:

    .BYTE #15   ; Electronic Rumble
    .BYTE #$FF
    .BYTE #1    ; Low Pure Tone
    .BYTE #1
    .BYTE #8    ; White Noise
    .BYTE #1
    .BYTE #1
    .BYTE #$FF
    .BYTE #$FF
    .BYTE #15
    .BYTE #$FF
    .BYTE #$FF
    .BYTE #8
    .BYTE #$FF
    .BYTE #1
    .BYTE #1

TitleAudio1:

    .BYTE #29   ; Kick
    .BYTE #$FF
    .BYTE #31   ; C
    .BYTE #31
    .BYTE #7    ; Snare
    .BYTE #31
    .BYTE #31
    .BYTE #$FF
    .BYTE #$FF
    .BYTE #29
    .BYTE #$FF
    .BYTE #$FF
    .BYTE #7
    .BYTE #$FF
    .BYTE #23   ; F
    .BYTE #24   ; E