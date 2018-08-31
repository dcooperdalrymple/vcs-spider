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

InitializeVariables

    ; Set background color
    lda #0
    sta COLUBK

    ; Set the playfield color
    lda #$0E ; White
    sta COLUPF

    ; Playfield Control
    lda #%00000001
    sta CTRLPF

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

VerticalBlank

    ldx #0

VerticalBlankLoop

    sta WSYNC
    inx
    cpx #37
    bne VerticalBlankLoop

    ; Do 192 scanlines of color-changing (our picture)

Picture

    ldx #0              ; This counts our scanline number

SolidPattern

    lda #%11111111
    sta PF0
    sta PF1
    sta PF2
    jmp PictureLoop

WallPattern

    lda #%00010000
    sta PF0
    lda #%00000000
    sta PF1
    sta PF2

PictureLoop

    sta WSYNC
    inx

    ; Pattern Changes
    cpx #8
    beq WallPattern
    cpx #184
    beq SolidPattern

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
