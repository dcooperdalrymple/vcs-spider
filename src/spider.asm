    ; 8 Legs of Love game for Atari VCS/2600
    ; Created by D Cooper Dalrymple 2018 - dcdalrymple.com
    ; Licensed under GNU LGPL V3.0
    ; Last revision: August 28th, 2018

    processor 6502
    include "vcs.h"
    include "macro.h"

; Constants
PATTERN         = $80   ; storage location (1st byte in RAM)
TIMETOCHANGE    = 20    ; speed of animation

    SEG
    ORG $F000

Reset

InitializeStack

    ldx #0
    txa

InitializeStackLoop

    dex
    txs
    pha
    bne InitializeStackLoop

    ; Stack pointer now $FF, a=x=0, TIA registers (0 - $7F) = RAM ($80 - $FF) = 0

    ; Set background color
    lda #0
    sta COLUBK

    ; The binary PF pattern
    lda #0
    sta PATTERN

    ; Set the playfield color
    lda #$45
    sta COLUPF

    ; "speed" counter
    ldy #0

StartOfFrame

    ; Start of vertical blank processing

    lda #0
    sta VBLANK

    lda #2
    sta VSYNC

    ; 3 scanlines of VSYNCH signal

    sta WSYNC
    sta WSYNC
    sta WSYNC

    lda #0
    sta VSYNC

    ; 37 scanlines of vertical blank

    ldx #0
VerticalBlank
    sta WSYNC
    inx
    cpx #37
    bne VerticalBlank

    ; Handle a change in the pattern once every 20 frames
    ; and write the pattern to the PF1 register
    iny                 ; Increment speed count by one
    cpy #TIMETOCHANGE   ; has it reached our "change point"?
    bne notyet          ; no, so branch past

    ldy #0              ; reset speed count

    inc PATTERN         ; switch to next pattern

notyet

    lda PATTERN         ; use our saved pattern
    sta PF1             ; as the playfield shape

    ; Do 192 scanlines of color-changing (our picture)

Picture

    ldx #0              ; This counts our scanline number

PictureLoop

    sta WSYNC
    inx
    cpx #192
    bne PictureLoop

    ;----------------------------------------

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

; 30 scanlines of overscan...

Overscan

    ldx #0

OverscanLoop

    sta WSYNC
    inx
    cpx #30
    bne OverscanLoop

    jmp StartOfFrame

    ;-------------------------------------------

    ORG $FFFA

InterruptVectors

    .word Reset         ; NMI
    .word Reset         ; RESET
    .word Reset         ; IRQ

END
