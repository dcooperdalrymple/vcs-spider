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
LOGO_TEXT_SIZE      = 8
LOGO_TEXT_INTERVAL  = 1
LOGO_PADDING        = 8

;================
; Variables
;================

    SEG.U vars
    org $80

Overlay             ds 8

    org Overlay         ; <= overlay size of 8 bytes

; Animation/Logic System

    org Overlay

; Drawing System, etc

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
    lda #$00 ; White
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

LogoFrame:

.vsync:                 ; Start of vertical blank processing

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

.vblank:                ; scanlines of vertical blank

    ldx #KERNEL_VBLANK
.vblank_loop:

    sta WSYNC
    dex
    bne .vblank_loop

.scanline:              ; Do 192 scanlines

    lda #$00            ; Clear playfields
    sta PF0
    sta PF1
    sta PF2

    ldx #LOGO_START     ; This counts our scanline number
.scanline_start:

    sta WSYNC
    dex
    bne .scanline_start

    ldx #0
.scanline_logo:

    ; Cleanup
    sta PF1

    txa
    lsr                 ; Divide counter by 4
    lsr
    and #%11111110      ; Remove 0th bit
    tay

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

    ; Wait for next line
    sta WSYNC
    inx
    cpx #LOGO_SIZE*LOGO_INTERVAL
    bne .scanline_logo

    ; Clear Playfields
    lda #$00
    sta PF0
    sta PF1
    sta PF2

    ldx #LOGO_PADDING
.scanline_padding

    sta WSYNC
    dex
    bne .scanline_padding

    ldx #LOGO_TEXT_SIZE*#LOGO_TEXT_INTERVAL
.scanline_text

    sta WSYNC

    dex                 ; Decrement x by 1
    txa
    inx                 ; Restore value of x
    ;lsr                 ; Divide by 2

    ; 1st Character
    tay
    lda LogoTextData,y
    sta GRP0

    ; 2nd Character
    tya
    adc #LOGO_TEXT_SIZE
    tay
    lda LogoTextData,y
    sta GRP1

    SLEEP 4
    sta RESP0
    sta RESP1

    ; 2-8 Characters
    ;REPEAT 2
    ;tya
    ;adc #LOGO_TEXT_SIZE
    ;tay
    ;lda LogoTextData,y
    ;sta GRP0
    ;sta RESP0
    ;REPEND

    dex
    bne .scanline_text
    sta WSYNC           ; Extra scanline to finish displaying sprites

    ; Clear Players
    lda #0
    sta GRP0
    sta GRP1

    ldx #KERNEL_SCANLINES-LOGO_START-LOGO_SIZE*LOGO_INTERVAL-LOGO_PADDING-LOGO_TEXT_SIZE*LOGO_TEXT_INTERVAL-1 ; Extra -1 is from logo text
.scanline_end:

    sta WSYNC
    dex
    bne .scanline_end

.overscan:              ; 30 scanlines of overscan

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

    ldx #KERNEL_OVERSCAN
.overscan_loop:

    sta WSYNC
    dex
    bne .overscan_loop

    jmp LogoFrame

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

LogoTextData: ; 6x8, flipped for decrementing loop

    ; C
    .BYTE %01111000
    .BYTE %11111100
    .BYTE %11001100
    .BYTE %11000000
    .BYTE %11000000
    .BYTE %11001100
    .BYTE %11111100
    .BYTE %01111000

    ; R
    .BYTE %11001100
    .BYTE %11001100
    .BYTE %11001100
    .BYTE %11111000
    .BYTE %11111100
    .BYTE %11001100
    .BYTE %11001100
    .BYTE %11111000

    ; E
    .BYTE %11111100
    .BYTE %11000000
    .BYTE %11000000
    .BYTE %11111000
    .BYTE %11000000
    .BYTE %11111100

    ; A
    .BYTE %01111100
    .BYTE %11000100
    .BYTE %11000100
    .BYTE %11111100
    .BYTE %11000100
    .BYTE %11000100

    ; T
    .BYTE %11111100
    .BYTE %00110000
    .BYTE %00110000
    .BYTE %00110000
    .BYTE %00110000
    .BYTE %00110000

    ; U
    .BYTE %11100100
    .BYTE %11100100
    .BYTE %11100100
    .BYTE %11100100
    .BYTE %11100100
    .BYTE %01111000

    ; R
    .BYTE %11111000
    .BYTE %11000100
    .BYTE %11000100
    .BYTE %11111000
    .BYTE %11000100
    .BYTE %11000100

    ; E
    .BYTE %11111100
    .BYTE %11000000
    .BYTE %11000000
    .BYTE %11111000
    .BYTE %11000000
    .BYTE %11111100

    ;-------------------------------------------

    ORG $FFFA           ; End of cart area

InterruptVectors:

    .word Reset         ; NMI
    .word Reset         ; RESET
    .word Reset         ; IRQ

    END
