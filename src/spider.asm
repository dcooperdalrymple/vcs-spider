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

;================
; Variables
;================

    SEG.U vars
    org $80

unused_variable     ds 1

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

    ; Set the playfield color
    lda #$0E ; White
    sta COLUPF

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

    ldx #0

.vblank_loop:

    sta WSYNC
    inx
    cpx #KERNEL_VBLANK
    bne .vblank_loop

.scanline:              ; Do 192 scanlines

    lda #$00            ; Clear playfields
    sta PF0
    sta PF1
    sta PF2

    ldx #0              ; This counts our scanline number
.scanline_start:

    sta WSYNC
    inx
    cpx #LOGO_START
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

    ; load first half of data
    lda LogoData,y
    sta PF2

    ; -8 pixels, 228 pixels in total, pf0 starts at 68 pixels, 160 per line, 80 is middle
    ; 88 more pixels to middle, 3 pixels per 6502 clock, 29 clocks needed, nop = 2 clocks

    ; Load second half of data
    iny
    lda LogoData,y
    ; tay ; Make a copy of the data

    ; and #%11110000 ; Use 4 MSB bits
    sta PF0

    ; tya ; Use 4 LSB bits
    ; and #%00001111
    asl
    asl
    asl
    asl
    sta PF1

    ; Delay before cleanup
    REPEAT 4
        nop
    REPEND

    ; Cleanup
    lda #$00
    sta PF0
    sta PF2

    sta WSYNC
    inx
    cpx #LOGO_SIZE*LOGO_INTERVAL
    bne .scanline_logo

    lda #$00            ; Clear Playfields
    sta PF0
    sta PF1
    sta PF2

    ldx #0
.scanline_end:

    sta WSYNC
    inx
    cpx #KERNEL_SCANLINES-LOGO_START-LOGO_SIZE*LOGO_INTERVAL
    bne .scanline_end

.overscan:              ; 30 scanlines of overscan

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

    ldx #0

.overscan_loop:

    sta WSYNC
    inx
    cpx #KERNEL_OVERSCAN
    bne .overscan_loop

    jmp LogoFrame

LogoData:               ; 6 bytes over 8 lines each, total of 48 lines

    .BYTE %00000000 ; Reversed
    .BYTE %00010000 ; First 4 bits reversed

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

    ;-------------------------------------------

    ORG $FFFA           ; End of cart area

InterruptVectors:

    .word Reset         ; NMI
    .word Reset         ; RESET
    .word Reset         ; IRQ

    END
