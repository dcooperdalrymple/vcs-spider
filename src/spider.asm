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
LOGO_START          = 32
LOGO_HEIGHT         = 48
LOGO_END            = 80

;================
; Variables
;================

    SEG.U vars
    org $80

logoDrawLine        ds 1

    SEG

    ORG $F000           ; Start of cart area

Reset:

InitializeStack:

    ldx #0
    txa

InitializeStackLoop:

    dex
    txs
    pha
    bne InitializeStackLoop

    ; Stack pointer now $FF, a=x=0, TIA registers (0 - $7F) = RAM ($80 - $FF) = 0

InitializeVariables:

    ; Set background color
    lda #$00 ; White
    sta COLUBK

    ; Set the playfield color
    lda #$0E ; White
    sta COLUPF

    ; Playfield Control
    lda #%00000001
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

StartOfFrame:           ; Start of vertical blank processing

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

VerticalBlank:          ; scanlines of vertical blank

    ldx #0

VerticalBlankLoop:

    sta WSYNC
    inx
    cpx #KERNEL_VBLANK
    bne VerticalBlankLoop

Picture:                ; Do 192 scanlines

    ldx #0              ; This counts our scanline number
    ldy #$FF              ; This counts our logo line number, set to $FF to loop

PictureScanline:

    ; Check if we are outside of logo bounds
    cpx #LOGO_START
    bcc PictureScanlineClear
    cpx #LOGO_END
    bcs PictureScanlineClear

    ; Increment logo line and check for 4th bit change (every 8)
    tya
    iny
    sty $80
    eor $80
    and #%00001000
    beq PictureScanlineEnd

    tya                 ; Load up logo index
    pha                 ; Push logo line index to stack
    lsr                 ; Divide by 8 (3 bitshifts)
    lsr
    lsr
    tay                 ; Move accumulator to y
    lda LogoData,y      ; Load logo data from yth line
    sta PF1             ; Store logo line into playfield
    pla                 ; Recall logo line index from stack
    tay                 ; Store logo line index back into y register
    jmp PictureScanlineEnd

PictureScanlineClear:

    lda #0
    sta PF1

PictureScanlineEnd:

    sta WSYNC
    inx

    cpx #KERNEL_SCANLINES
    bne PictureScanline

Overscan:               ; 30 scanlines of overscan...

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

    ldx #0

OverscanLoop:

    sta WSYNC
    inx
    cpx #KERNEL_OVERSCAN
    bne OverscanLoop

    jmp StartOfFrame

LogoData:               ; 6 bytes over 8 lines each, total of 48 lines

    .BYTE %00001000
    .BYTE %00011100
    .BYTE %00110110
    .BYTE %01100000
    .BYTE %11000000
    .BYTE %11111111

    ;-------------------------------------------

    ORG $FFFA           ; End of cart area

InterruptVectors:

    .word Reset         ; NMI
    .word Reset         ; RESET
    .word Reset         ; IRQ

    END
