;================
; Constants
;================

LOGO_FRAMES         = 180

LOGO_BG_COLOR       = #$00
LOGO_FG_COLOR       = #$C6

LOGO_AUDIO_0_TONE   = 4
LOGO_AUDIO_0_VOLUME = 15 ; 15 is max
LOGO_AUDIO_1_TONE   = 1
LOGO_AUDIO_1_VOLUME = 3
LOGO_AUDIO_LENGTH   = 12
LOGO_AUDIO_STEP     = 8

LOGO_IMAGE_SIZE         = 16
LOGO_IMAGE_LINE_SIZE    = 5
LOGO_IMAGE_LINES        = LOGO_IMAGE_SIZE*LOGO_IMAGE_LINE_SIZE
LOGO_IMAGE_PADDING      = #(KERNEL_SCANLINES-LOGO_IMAGE_LINES)/2
LOGO_IMAGE_ANIM_PADDING = #LOGO_IMAGE_PADDING-6 ; The extra 6 is for processing overflow

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
    lda #(LOGO_IMAGE_SIZE+1)*2
    sta WebIndex

    rts

LogoVerticalBlank:
    jsr LogoAnimation
    rts

LogoOverScan:
    jsr LogoAudio
    jsr LogoState
    rts

LogoAnimation:
    lda Frame
    and #%00000011 ; Every 4 when bits are 00
    bne .logo_animation_return

    ldx WebIndex
    cpx #0
    beq .logo_animation_return

    ; Add another visible line
    dex
    dex
    stx WebIndex

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
    lda CtrlPf
    and #%11111110 ; No mirroring
    sta CtrlPf
    sta CTRLPF

    ; Turn on display
    lda #0
    sta VBLANK

    ldy WebIndex
    cpy #0
    bne .logo_kernel_top_anim_padding

.logo_kernel_top_padding:
    ; Top Padding
    jsr LogoPadding
    jmp .logo_kernel_image

.logo_kernel_top_anim_padding:
    jsr LogoAnimPadding

.logo_kernel_image_animation_start:
    ldx #LOGO_IMAGE_LINE_SIZE

.logo_kernel_image_animation_loop:
    sta WSYNC
    dex
    bne .logo_kernel_image_animation_loop

    dey
    dey
    bne .logo_kernel_image_animation_start

.logo_kernel_image:

    ldx #(LOGO_IMAGE_SIZE*2)
    ldy #LOGO_IMAGE_LINE_SIZE-1
    ; The extra 1 on line size is for processing overflow

    dex
    cpx WebIndex
    bcc .logo_kernel_bottom_padding

.logo_kernel_image_line:
    sta WSYNC

    lda LogoImagePF0-1,x
    sta PF0
    lda LogoImagePF1-1,x
    sta PF1
    lda LogoImagePF2-1,x
    sta PF2

    sleep 6

    lda LogoImagePF0,x
    sta PF0
    lda LogoImagePF1,x
    sta PF1
    lda LogoImagePF2,x
    sta PF2

    dey
    bne .logo_kernel_image_line

    ldy #LOGO_IMAGE_LINE_SIZE

    dex
    cpx WebIndex
    bcc .logo_kernel_bottom_padding

    dex
    bpl .logo_kernel_image_line

.logo_kernel_bottom_padding:
    ; Bottom Padding
    jsr LogoPadding

.logo_kernel_image_return:
    rts

LogoPadding:
    lda #0
    sta PF0
    sta PF1
    sta PF2

    ldx #LOGO_IMAGE_PADDING
.logo_padding_loop:
    sta WSYNC
    dex
    bne .logo_padding_loop

    rts

LogoAnimPadding:
    lda #0
    sta PF0
    sta PF1
    sta PF2

    ldx #LOGO_IMAGE_ANIM_PADDING
    jmp .logo_padding_loop

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
