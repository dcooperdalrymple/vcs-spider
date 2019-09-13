;================
; Constants
;================

LOGO_FRAMES         = 180

LOGO_BG_COLOR       = #$A2
LOGO_FG_COLOR       = #$5E

LOGO_AUDIO_0_TONE   = 4
LOGO_AUDIO_0_VOLUME = 15 ; 15 is max
LOGO_AUDIO_1_TONE   = 1
LOGO_AUDIO_1_VOLUME = 3
LOGO_AUDIO_LENGTH   = 12
LOGO_AUDIO_STEP     = 8

LogoInit:

    ; Setup logic and kernel
    SET_POINTER VBlankPtr, LogoVerticalBlank
    SET_POINTER KernelPtr, LogoKernel
    SET_POINTER OverScanPtr, LogoOverScan

    ; Load Colors
    lda #LOGO_BG_COLOR
    sta COLUBK
    lda #LOGO_FG_COLOR
    sta COLUPF

    ; Load audio settings
    lda #LOGO_AUDIO_0_TONE
    sta AUDC0
    lda #LOGO_AUDIO_0_VOLUME
    sta AUDV0
    lda #LOGO_AUDIO_1_TONE
    sta AUDC1
    lda #LOGO_AUDIO_1_VOLUME
    sta AUDV1
    lda #0
    sta AudioStep

    ; Play first note
    lda LogoAudio0,AudioStep
    sta AUDF0
    lda LogoAudio1,AudioStep
    sta AUDF1

    ; Setup frame counters
    lda #0
    sta Frame
    lda #LOGO_FRAMES
    sta FrameTimer

    ; Setup Image Animation
    ;lda #KERNEL_IMAGE_SIZE
    ;sta ImageVisible

    rts

LogoVerticalBlank:
    ;jsr LogoAnimation
    rts

LogoOverScan:
    jsr LogoAudio
    jsr LogoState
    rts

LogoAnimation:
    lda Frame
    and #%00000011 ; Every 4 when bits are 00
    bne .logo_animation_return

    ;ldx ImageVisible
    ;cpx #0
    ;beq .logo_animation_return

    ; Add another visible line
    ;dex
    ;stx ImageVisible

.logo_animation_return:
    rts

LogoAudio:

    lda Frame
    and #%00000111 ; Every 8 when bits are 000
    bne .logo_audio_return

.logo_audio_play:

    ; Check if we're at the end of the melody
    ldy AudioStep
    cpy #LOGO_AUDIO_LENGTH-1
    beq .logo_audio_mute

.logo_audio_play_note:
    ; Increment audio position
    iny
    sty AudioStep

    ; Logo note and play
    lda LogoAudio0,y
    sta AUDF0
    lda LogoAudio1,y
    sta AUDF1
    jmp .logo_audio_mute_skip

.logo_audio_mute:

    ; Mute audio
    lda #0
    sta AUDC0
    sta AUDV0
    sta AUDF0
    sta AUDC1
    sta AUDV1
    sta AUDF1

.logo_audio_mute_skip:
.logo_audio_return:
    rts

LogoState:
    lda FrameTimer
    cmp #0
    bne .logo_state_return

    jsr TitleInit

.logo_state_return:
    rts

LogoKernel:

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

.logo_kernel_image:

    ; 76 machine cycles per scanline
    sta WSYNC

.logo_kernel_image_load: ; 66 cycles

    ; First half of image
    lda LogoImage,y ; 5
    sta PF0 ; 4
    lda LogoImage+1,y ; 5
    sta PF1 ; 4
    lda LogoImage+2,y ; 5
    sta PF2 ; 4

    sleep 6

    ; Second half of image
    lda LogoImage+3,y ; 5
    sta PF0 ; 4
    lda LogoImage+4,y ; 5
    sta PF1 ; 4
    lda LogoImage+5,y ; 5
    sta PF2 ; 4

.logo_kernel_image_index: ; 4 cycles

    dex ; 2
    bne .logo_kernel_image ; 2

.logo_kernel_image_index_next: ; 6 cycles

    ; Restore scanline counter
    ldx #KERNEL_IMAGE_LINE ; 2

    tya ; 2
    clc ; 2
    adc #KERNEL_IMAGE_FULL_DATA ; 2
    tay ; 2
    cpy #KERNEL_IMAGE_SIZE*KERNEL_IMAGE_FULL_DATA
    bne .logo_kernel_image ; 2

.logo_kernel_image_clean:

    ; Clear out playfield
    lda #0
    sta PF0
    sta PF1
    sta PF2

.logo_kernel_image_return:
    rts

LogoAssets:

    ; Assets
    include "logo_image.asm"

LogoAudio0:

    .BYTE #29   ; C
    .BYTE #23   ; E
    .BYTE #19   ; G
    .BYTE #15   ; A
    .BYTE #23   ; E
    .BYTE #19   ; G
    .BYTE #15   ; B
    .BYTE #14   ; C
    .BYTE #11   ; E
    .BYTE #11
    .BYTE #11
    .BYTE #11

LogoAudio1:

    .BYTE #31   ; C
    .BYTE #31
    .BYTE #31
    .BYTE #31
    .BYTE #25   ; E
    .BYTE #25
    .BYTE #25
    .BYTE #25
    .BYTE #20   ; G
    .BYTE #20
    .BYTE #20
    .BYTE #20
