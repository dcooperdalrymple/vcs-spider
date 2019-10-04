    ; Spider Web game for Atari VCS/2600
    ; Created by D Cooper Dalrymple 2018 - dcdalrymple.com
    ; Licensed under GNU LGPL V3.0
    ; Last revision: September 5th, 2019

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
KERNEL_WIDTH        = 40*8
KERNEL_HBLANK       = 68

KERNEL_IMAGE_MIRROR_DATA   = #3
KERNEL_IMAGE_FULL_DATA = #6
KERNEL_IMAGE_LINE   = #8
KERNEL_IMAGE_SIZE   = #24 ; KERNEL_SCANLINES/KERNEL_IMAGE_LINE

;================
; Variables
;================

    SEG.U vars
    org $80

VBlankPtr           ds 2
KernelPtr           ds 2
OverScanPtr         ds 2

Temp                ds 1

Frame               ds 1
FrameTimer          ds 1

AudioStep           ds 1

ImageIndex          ds 1

PlayerPtr           ds 2
PlayerPosition      ds 2
PlayerControl       ds 1

MissileEnabled      ds 1
MissilePosition     ds 2
MissileVelocity     ds 2
MissileStartPos     ds 2

    SEG

    ORG $F000           ; Start of cart area

;=======================================
; Global Kernel Subroutines
;=======================================

;=======================================
; PosObject
; ---------
; A - holds the X position of the object
; X - holds which object to position
;   0 = player0
;   1 = player1
;   2 = missile0
;   3 = missile1
;   4 = Ball
;=======================================

PosObject:
    sec
    sta WSYNC
.posobject_divide_loop:
    sbc #15
    bcs .posobject_divide_loop
    eor #7
    REPEAT 4
        asl
    REPEND
    sta.wx HMP0,x
    sta RESP0,x
    rts

PosMissile:
    sec
    sta WSYNC
.posmissle_divide_loop:
    sbc #15
    bcs .posmissle_divide_loop
    eor #7
    REPEAT 4
        asl
    REPEND
    sta.wx HMM0,x
    sta RESM0,x
    rts

InitSystem:

.init_clean:
    ; Resets RAM, TIA registers, and CPU registers
    CLEAN_START

.init_tia:
    ; Define default TIA register values

    ; Set background color
    lda #$00        ; Black
    sta COLUBK

    ; Set the playfield and player color
    lda #$0E        ; White
    sta COLUPF
    sta COLUP0
    sta COLUP1

    ; Playfield Control
    lda #%00000001  ; 1 for mirroring
    sta CTRLPF

    ; Disable Game Elements
    lda #$00
    sta ENABL       ; Turn off ball
    sta ENAM0       ; Turn off player 1 missile
    sta ENAM1       ; Turn off player 2 missile
    sta GRP0        ; Turn off player 1
    sta GRP1        ; Turn off player 2

    ; Empty playfield
    lda #%00000000
    sta PF0
    sta PF1
    sta PF2

.init_game:

    jsr LogoInit
    ;jsr GameInit

;=======================================
; Game Kernel
;=======================================

Main:

    jsr VerticalSync
    jsr VerticalBlank
    jsr Kernel
    jsr OverScan
    jmp Main

VerticalSync:

    lda #0
    sta VBLANK

    ; Turn on Vertical Sync signal and setup timer
    lda #2
    sta VSYNC

    ; Increment frame count and reduce frame counter
    inc Frame
    dec FrameTimer

    ; VSYNCH signal scanlines
    REPEAT #KERNEL_VSYNC
        sta WSYNC
    REPEND

    ; Turn off Vertical Sync signal
    lda #0
    sta VSYNC

.vsync_return:
    rts

VerticalBlank:
    ; Setup Timer
    lda #44 ; #KERNEL_VBLANK*76/64
    sta TIM64T

.vblank_logic:
    ; Perform Game Logic
    ;jsr (VBlankPtr)
    jsr .vblank_logic_call_ptr

.vblank_loop:
    ; WSYNC until Timer is complete
    sta WSYNC
    lda INTIM
    bne .vblank_loop

.vblank_return:
    rts

.vblank_logic_call_ptr:
    jmp (VBlankPtr)

Kernel:

    ; Perform Selected Kernel
    ;jsr (KernelPtr)
    jsr .kernel_call_ptr
    rts

.kernel_call_ptr:
    jmp (KernelPtr)

OverScan:

    ; End of screen, enter blanking
    lda #%01000010
    sta VBLANK

    ; Setup Timer
    lda #36 ; #KERNEL_OVERSCAN*76/64
    sta TIM64T

.overscan_logic:
    ; Perform OverScan Logic
    ;jsr (OverScanPtr)
    jsr .overscan_logic_call_ptr

.overscan_loop:
    ; WSYNC until Timer is complete
    sta WSYNC
    lda INTIM
    bne .overscan_loop

.overscan_return:
    rts

.overscan_logic_call_ptr:
    jmp (OverScanPtr)

;================
; State Code
;================

    include "logo.asm"
    include "title.asm"
    include "game.asm"

;================
; End of cart
;================

    ORG $F7FA ; 2k = $F7FA, 4k = $FFFA

InterruptVectors:

    .word InitSystem    ; NMI
    .word InitSystem    ; RESET
    .word InitSystem    ; IRQ

    END
