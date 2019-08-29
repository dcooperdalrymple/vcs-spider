    ; 8 Legs of Love game for Atari VCS/2600
    ; Created by D Cooper Dalrymple 2018 - dcdalrymple.com
    ; Licensed under GNU LGPL V3.0
    ; Last revision: August 28th, 2018

    processor 6502
    include "vcs.h"
    include "macro.h"

;================
; Constants
;================

; PAL Region
PAL                 = 0
PAL_SCANLINES       = 242
PAL_TOTAL           = 312

; NTSC Region
NTSC                = 1
NTSC_SCANLINES      = 192
NTSC_TOTAL          = 262

; Kernel
SYSTEM              = NTSC
#if SYSTEM = NTSC
KERNEL_SCANLINES    = NTSC_SCANLINES
KERNEL_TOTAL        = NTSC_TOTAL
#endif
#if SYSTEM = PAL
KERNEL_SCANLINES    = PAL_SCANLINES
KERNEL_TOTAL        = PAL_TOTAL
#endif
KERNEL_VSYNC        = 3
KERNEL_VBLANK       = 37
KERNEL_OVERSCAN     = 30

; Logo
LOGO_SIZE           = 9
LOGO_START          = 48
LOGO_INTERVAL       = 4*2
LOGO_FRAMES         = 255

; Title
TITLE_LINE_SIZE     = 8
TITLE_DATA_SIZE     = %00000100
TITLE_BORDER        = 1
TITLE_PAD           = 4
TITLE_IMAGE         = 6
TITLE_GAP           = 2

;================
; Variables
;================

    SEG.U vars
    org $80

Overlay             ds 8

    org Overlay

; Animation/Logic System

AnimationFrame      ds 1 ; 1 byte to count frames
AnimationSubFrame   ds 1 ; 1 byte to count portions of frames

    org Overlay

; Drawing System, etc

TitleImagePtr       ds 2 ; Pointer to image data location

    SEG

    ORG $F000           ; Start of cart area

Reset:

.initstack

    ldx #0
    txa

.initstack_loop:

    dex
    txs
    pha
    bne .initstack_loop

    ; Stack pointer now $FF, a=x=0, TIA registers (0 - $7F) = RAM ($80 - $FF) = 0

.initvars

    ; Set background color
    lda #$00 ; Black
    sta COLUBK

    ; Set the playfield and player color
    lda #$0E ; White
    sta COLUPF
    sta COLUP0
    sta COLUP1

    ; Playfield Control
    lda #%00000000 ; 1 for mirroring
    sta CTRLPF

    ; Disable Game Elements
    lda #$00
    sta ENABL           ; Turn off ball
    sta ENAM0           ; Turn off player 1 missile
    sta ENAM1           ; Turn off player 2 missile
    sta GRP0            ; Turn off player 1
    sta GRP1            ; Turn off player 2

    ; Empty playfield
    lda #%00000000
    sta PF0
    sta PF1
    sta PF2

LogoScreen:

    ; Load number of frames into AnimationFrame
    lda #LOGO_FRAMES
    sta AnimationFrame

    lda #0
    sta AnimationSubFrame

LogoFrame:

.logo_vsync:                 ; Start of vertical blank processing

    lda #0
    sta VBLANK

    lda #2
    sta VSYNC

    ; VSYNCH signal scanlines
    REPEAT #KERNEL_VSYNC
        sta WSYNC
    REPEND

    lda #0
    sta VSYNC

.logo_vblank:                ; scanlines of vertical blank

    ldx #KERNEL_VBLANK
.logo_vblank_loop:

    sta WSYNC
    dex
    bne .logo_vblank_loop

.logo_scanline:              ; Do 192 scanlines

    lda #$00            ; Clear playfields
    sta PF0
    sta PF1
    sta PF2

    ldx #LOGO_START     ; This counts our scanline number
.logo_scanline_start:

    sta WSYNC
    dex
    bne .logo_scanline_start

    ldx #0
.logo_scanline_loop:

    ; Cleanup
    sta PF1

    txa
    lsr                 ; Divide counter by 4
    lsr
    and #%11111110      ; Remove 0th bit
    tay

    ; Check if we need to display line
    cpy AnimationSubFrame
    bcs .logo_scanline_skip

    ; Load first half of data
    lda LogoData,y
    sta PF2

    ; Load second half of data
    iny
    lda LogoData,y

    ; Use 4 MSB bits on PF0
    sta PF0

    ; Use 4 LSB bits on PF1
    REPEAT 4
        asl
    REPEND
    sta PF1

    ; Cleanup
    lda #$00
    sta PF2
    sta PF0

.logo_scanline_skip:

    ; Clear Playfields
    lda #$00
    sta PF0
    sta PF1
    sta PF2

    ; Wait for next line
    sta WSYNC

    ; Check if at end of logo display
    inx
    cpx #LOGO_SIZE*LOGO_INTERVAL
    bne .logo_scanline_loop

    ldx #KERNEL_SCANLINES-LOGO_START-LOGO_SIZE*LOGO_INTERVAL
.logo_scanline_end:

    sta WSYNC
    dex
    bne .logo_scanline_end

.logo_overscan:              ; 30 scanlines of overscan

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

    ldx #KERNEL_OVERSCAN
.logo_overscan_loop:

    sta WSYNC
    dex
    bne .logo_overscan_loop

    ldx AnimationFrame

    ; Divide inverted AnimationFrame by 4 and put in AnimationSubFrame
    lda #LOGO_FRAMES
    sbc AnimationFrame
    lsr
    lsr
    sta AnimationSubFrame

    ; Decrement AnimationFrame
    dex
    stx AnimationFrame

    ; Check if we're at the end of the animation
    bne LogoFrame

TitleScreen:

    lda #$00            ; Clear playfields
    sta PF0
    sta PF1
    sta PF2

TitleFrame:

.title_vsync:                 ; Start of vertical blank processing

    lda #0
    sta VBLANK

    lda #2
    sta VSYNC

    ; VSYNCH signal scanlines
    REPEAT #KERNEL_VSYNC
        sta WSYNC
    REPEND

    lda #0
    sta VSYNC

.title_vblank:                  ; scanlines of vertical blank

    ldx #KERNEL_VBLANK
.title_vblank_loop:

    sta WSYNC
    dex
    bne .title_vblank_loop

.title_border_h_top:

    ; Number of Scanlines
    ldx #TITLE_BORDER*TITLE_LINE_SIZE

    ; Draw Playfield
    lda #$FF
    sta PF0
    sta PF1
    sta PF2

.title_border_h_top_loop:

    sta WSYNC
    dex
    bne .title_border_h_top_loop

.title_border_v_top:

    ; Number of Scanlines
    ldx #TITLE_PAD*TITLE_LINE_SIZE

    ; Mirror playfield
    lda #%00000001
    sta CTRLPF

    ; Draw Playfield
    lda #%00010000
    sta PF0

    lda #$00
    sta PF1
    sta PF2

.title_border_v_top_loop:

    sta WSYNC
    dex
    bne .title_border_v_top_loop

.title_image_top:

    ldy #$00    ; Current Image Index

    sleep 2
    jmp .title_image_top_line_skip_wait

.title_image_top_line:

    sleep 8

.title_image_top_line_skip_wait:

    ldx #TITLE_LINE_SIZE                ; Current scanline
    jmp .title_image_top_loop_skip_wait

.title_image_top_loop:

    ; Wait until new line is ready to draw
    sta WSYNC
    sleep 16

.title_image_top_loop_skip_wait:

    ; Draw Image
    lda TitleImageTop,y
    sta PF1
    iny
    lda TitleImageTop,y
    sta PF2
    iny
    lda TitleImageTop,y
    iny
    sleep 5
    sta PF2
    lda TitleImageTop,y
    sta PF1

    ; Clear bottom of index
    tya
    and #%11111100
    tay

    dex
    bne .title_image_top_loop

    ; Add 4 to the image index to skip to next line
    REPEAT 4
        iny
    REPEND

    cpy #TITLE_IMAGE*TITLE_DATA_SIZE
    bne .title_image_top_line

.title_gap:

    ; Number of Scanlines
    ldx #TITLE_GAP*TITLE_LINE_SIZE

    ; Mirror playfield
    lda #%00000001
    sta CTRLPF

    ; Draw Playfield
    lda #%00010000
    sta PF0

    lda #$00
    sta PF1
    sta PF2

.title_gap_loop:

    sta WSYNC
    dex
    bne .title_gap_loop

.title_image_bottom:

    ldy #$00                ; Current Image Index

    sleep 2
    jmp .title_image_bottom_line_skip_wait

.title_image_bottom_line:

    sleep 9

.title_image_bottom_line_skip_wait

    ldx #TITLE_LINE_SIZE    ; Current scanline
    jmp .title_image_bottom_loop_skip_wait

.title_image_bottom_loop:

    ; Wait until new line is ready to draw
    sta WSYNC
    sleep 16

.title_image_bottom_loop_skip_wait:

    ; Draw Image
    lda TitleImageBottom,y
    sta PF1
    iny
    lda TitleImageBottom,y
    sta PF2
    iny
    lda TitleImageBottom,y
    iny
    sleep 5
    sta PF2
    lda TitleImageBottom,y
    sta PF1

    ; Clear bottom of index
    tya
    and #%11111100
    tay

    dex
    bne .title_image_bottom_loop

    ; Add 4 to image index to skip to next line
    REPEAT 4
        iny
    REPEND

    cpy #TITLE_IMAGE*TITLE_DATA_SIZE
    bne .title_image_bottom_line

.title_border_v_bottom:

    ; Number of Scanlines
    ldx #TITLE_PAD*TITLE_LINE_SIZE

    ; Mirror playfield
    lda #%00000001
    sta CTRLPF

    ; Draw Playfield
    lda #%00010000
    sta PF0

    lda #$00
    sta PF1
    sta PF2

.title_border_v_bottom_loop:

    sta WSYNC
    dex
    bne .title_border_v_bottom_loop

.title_border_h_bottom:

    ; Number of Scanlines
    ldx #TITLE_BORDER*TITLE_LINE_SIZE

    ; Draw Playfield
    lda #$FF
    sta PF0
    sta PF1
    sta PF2

.title_border_h_bottom_loop:

    sta WSYNC
    dex
    bne .title_border_h_bottom_loop

.title_overscan:              ; 30 scanlines of overscan

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

    ldx #KERNEL_OVERSCAN
.title_overscan_loop:

    sta WSYNC
    dex
    bne .title_overscan_loop

    ; Check if Fire Button on controller 1 is pressed
    lda INPT4
    bpl StartScreen
    jmp TitleFrame

StartScreen:

    ; Init variables here

StartFrame:

.start_vsync:                 ; Start of vertical blank processing

    lda #0
    sta VBLANK

    lda #2
    sta VSYNC

    ; VSYNCH signal scanlines
    REPEAT #KERNEL_VSYNC
        sta WSYNC
    REPEND

    lda #0
    sta VSYNC

.start_vblank:                ; scanlines of vertical blank

    ldx #KERNEL_VBLANK
.start_vblank_loop:

    sta WSYNC
    dex
    bne .start_vblank_loop

.start_scanline:              ; Do 192 scanlines

    lda #$08            ; Clear playfields (with temp design)
    sta PF0
    sta PF1
    sta PF2

    ldx #KERNEL_SCANLINES ; Iterate through all scanlines
.start_scanline_loop:

    sta WSYNC
    dex
    bne .start_scanline_loop

.start_overscan:              ; 30 scanlines of overscan

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

    ldx #KERNEL_OVERSCAN
.start_overscan_loop:

    sta WSYNC
    dex
    bne .start_overscan_loop

    jmp StartFrame

LogoData:               ; 6 bytes over 8 lines each, total of 48 lines

    .BYTE %00000000     ; Reversed
    .BYTE %00010000     ; First 4 bits reversed

    .BYTE %10000000
    .BYTE %00100000

    .BYTE %01000000
    .BYTE %01000000

    .BYTE %00100000
    .BYTE %10000000

    .BYTE %00010000
    .BYTE %00001000

    .BYTE %00001000
    .BYTE %00000000

    .BYTE %00000100
    .BYTE %00000000

    .BYTE %00000010
    .BYTE %00000000

    .BYTE %11111111
    .BYTE %11111111

TitleImageTop:          ; Spider

    .BYTE %00011110     ; Normal
    .BYTE %01110111     ; Reversed
    .BYTE %11100111     ; Normal
    .BYTE %00001110     ; Reversed

    .BYTE %00010000
    .BYTE %00100101
    .BYTE %10010100
    .BYTE %00010010

    .BYTE %00010000
    .BYTE %00100111
    .BYTE %10010110
    .BYTE %00010010

    .BYTE %00011100
    .BYTE %00100001
    .BYTE %10010100
    .BYTE %00001110

    .BYTE %00000100
    .BYTE %00100001
    .BYTE %10010100
    .BYTE %00010010

    .BYTE %00011100
    .BYTE %01110001
    .BYTE %11100111
    .BYTE %00010010

TitleImageBottom:       ; Web & Art

    .BYTE %00000001     ; Normal
    .BYTE %00000011     ; Reversed
    .BYTE %10001011     ; Normal
    .BYTE %00011101     ; Reversed

    .BYTE %00001010
    .BYTE %00010100
    .BYTE %10001010
    .BYTE %00100100

    .BYTE %00010101
    .BYTE %00101010
    .BYTE %10001011
    .BYTE %00011100

    .BYTE %00100100
    .BYTE %01001001
    .BYTE %10001010
    .BYTE %00100100

    .BYTE %00100010
    .BYTE %01000100
    .BYTE %10101010
    .BYTE %00100100

    .BYTE %00010001
    .BYTE %00100011
    .BYTE %01010011
    .BYTE %00011101

    ;-------------------------------------------

    ORG $FFFA           ; End of cart area

InterruptVectors:

    .word Reset         ; NMI
    .word Reset         ; RESET
    .word Reset         ; IRQ

    END
