;================
; Constants
;================

LOGO_FRAMES         = 140

LOGO_BG_COLOR       = #$00
LOGO_FG_COLOR       = #$C6
LOGO_BG_BW_COLOR    = #$00
LOGO_FG_BW_COLOR    = #$0E

LOGO_IMAGE_SIZE         = 12
LOGO_IMAGE_LINE_SIZE    = 5
LOGO_IMAGE_LINES        = LOGO_IMAGE_SIZE*LOGO_IMAGE_LINE_SIZE
LOGO_IMAGE_PADDING      = #(KERNEL_SCANLINES-LOGO_IMAGE_LINES)/2
LOGO_IMAGE_ANIM_PADDING = #LOGO_IMAGE_PADDING-10 ; The extra 10 is for processing overflow
LOGO_IMAGE_ANIM_SPEED   = #6

LogoInit:

    ; Setup logic and kernel
    SET_POINTER VBlankPtr, LogoVerticalBlank
    SET_POINTER KernelPtr, LogoKernel
    SET_POINTER OverScanPtr, LogoOverScan

    ; Clean audio
    lda #0
    sta AUDV0
    sta AUDV1

    ; Set initial button state
;    lda #0
    sta InputState

    ; Setup frame counters
;    lda #0
    sta Frame
    lda #LOGO_FRAMES
    sta FrameTimer

    ; Setup Image Animation
    lda #LOGO_IMAGE_SIZE-1
    sta WebIndex

    rts

LogoVerticalBlank:
    jsr LogoAnimation
    rts

LogoOverScan:
    jsr LogoState
    rts

LogoAnimation:
    lda Frame
    cmp #LOGO_IMAGE_ANIM_SPEED
    bne .logo_animation_return

    lda #0
    sta Frame

    ldx WebIndex
    beq .logo_animation_return

    ; Add another visible line
    dec WebIndex

.logo_animation_return:
    rts

LogoState:
    lda FrameTimer
    beq .logo_state_next

    ; Check if Fire Button on controller 1 is released
    lda INPT4
    bmi .logo_state_check

.logo_state_on:
    lda #1
    sta InputState
    rts

.logo_state_check:
    ldx InputState
    beq .logo_state_return

.logo_state_next:
    ; Button is released or timer runs out, load title screen
    jsr TitleInit

.logo_state_return:
    rts

LogoKernel:

    ; Playfield Control
    lda #%00000001 ; Mirror
    ;sta CtrlPf
    sta CTRLPF

    ; Load Colors
    lda SWCHB
    REPEAT 4
    lsr
    REPEND
    bcc .logo_kernel_bw

.logo_kernel_color:
    ldx #LOGO_BG_COLOR
    ldy #LOGO_FG_COLOR
    jmp .logo_kernel_set

.logo_kernel_bw:
    lda #LOGO_BG_BW_COLOR
    lda #LOGO_FG_BW_COLOR

.logo_kernel_set:
    stx COLUBK
    sty COLUPF

.logo_kernel_start:

    ; Turn on display
    lda #0
    sta VBLANK

    ldy WebIndex
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
    bpl .logo_kernel_image_animation_start

.logo_kernel_image:

    ldx #LOGO_IMAGE_SIZE-1
    ldy #LOGO_IMAGE_LINE_SIZE-2
    ; The extra 2 on line size is for processing overflow

    ;dex
    cpx WebIndex
    bcc .logo_kernel_bottom_padding

.logo_kernel_image_line:
    sta WSYNC

    lda LogoImage1,x
    sta PF1
    lda LogoImage2,x
    sta PF2

    sleep 26

    lda LogoImage3,x
    sta PF2
    lda LogoImage4,x
    sta PF1

    dey
    bne .logo_kernel_image_line

    ldy #LOGO_IMAGE_LINE_SIZE

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
