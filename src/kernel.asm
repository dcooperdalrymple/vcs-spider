; Spider Web game for Atari VCS/2600
; Created by D Cooper Dalrymple 2018 - dcdalrymple.com
; Licensed under GNU LGPL V3.0
; Last revision: March 1st, 2020

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
PAL_FRAMES          = 50

; NTSC Region
NTSC                = 1
NTSC_SCANLINES      = 192
NTSC_TOTAL          = 262
NTSC_FRAMES         = 60

; Kernel
;SYSTEM              = NTSC
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
#if SYSTEM = NTSC
KERNEL_IMAGE_LINE   = #8
#endif
#if SYSTEM = PAL
KERNEL_IMAGE_LINE   = #10
#endif
KERNEL_IMAGE_SIZE   = #24 ; KERNEL_SCANLINES/KERNEL_IMAGE_LINE

;================
; Variables
;================

    SEG.U vars
    org $80

; Global

Temp                ds 4
Rand8               ds 1
Rand16              ds 1

VBlankPtr           ds 2
KernelPtr           ds 2
OverScanPtr         ds 2

Frame               ds 1
FrameTimer          ds 2
InputState          ds 2

AudioStep           ds 1
SampleStep          ds 1

; Game

GameType            ds 1
GameAudioStep       ds 1

; Score

ScoreValue          ds 2
ScoreDigitOnes      ds 2
ScoreDigitTens      ds 2
ScoreDigitGfx       ds 3
ScoreBarGfx         ds 2

; Level
LevelCurrent        ds 1

; Web

WebIndex            ds 1
WebColor            ds 2

; Object X Positions

XPositions:
SpiderPosX          ds 1 ; 0
SwatterPosX         ds 1 ; 1
BugPosX             ds 2 ; 2/3
LinePosX            ds 1 ; 4

; Spider

SpiderPtr           ds 2
SpiderPosY          ds 1
SpiderCtrl          ds 1
SpiderColor         ds 1

SpiderIndex         ds 1
SpiderDrawPos       ds 1
SpiderLine          ds 1

SpiderPtr2          ds 2

; Line

LineEnabled         ds 1
LinePosY            ds 1
LineVelocity        ds 2
LineDrawPos         ds 2

; Bug

BugSpeed            ds 1

BugStunned          ds 2
BugPosY             ds 2

BugDrawPosBottom    ds 2
BugDrawPosTop       ds 2

; Swatter

SwatterPosY         ds 1
SwatterState        ds 1
SwatterColor        ds 1

SwatterWaitTime     ds 1
SwatterHoldTime     ds 1
SwatterHitDamage    ds 1

SwatterIndex        ds 1
SwatterDrawPos      ds 1
SwatterLine         ds 1

SwatterSampleCount  ds 1
SwatterSampleF      ds 1

; Over

OverImagePF1Ptr     ds 2
OverImagePF2Ptr     ds 2
OverAudio0Ptr       ds 2
OverColor           ds 1

    SEG
    org $F000           ; Start of cart area

    include "routines.asm"

    ; Assets

    include "title_frame_top.asm"
    include "title_frame_bottom.asm"
    include "title_spider.asm"
    include "title_bug.asm"
    include "title_logo.asm"

    include "objects/score_digits.asm"
    include "objects/score_digits_flip.asm"
    include "objects/score_label.asm"

    include "objects/web_image.asm"

    include "objects/spider_sprite.asm"

    include "objects/swatter_sprite.asm"

;    include "logo_image.asm"

InitSystem:

.init_clean:
    ; Resets RAM, TIA registers, and CPU registers
    CLEAN_START

.init_seed:
    ; Seed the random number generator
    lda INTIM       ; Unknown value
    sta Rand8       ; Use as seed
    eor #$FF        ; Flip bits
    sta Rand16      ; Just in case INTIM was 0

.init_game:

;    jsr LogoInit
;    jsr TitleInit
    jsr GameInit

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
    dec FrameTimer+1

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

.overscan_reset:
    ; Check for reset switch
    lda SWCHB
    lsr                     ; Push D0 to carry (C)
    bcs .overscan_logic     ; If D0 is set, no reset

    ; Perform reset
;    jsr LogoInit            ; No need for logic
;    jsr TitleInit
    jsr GameInit
    jmp .overscan_loop

.overscan_logic:
    ; Perform OverScan Logic
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

;    include "logo.asm"
;    include "title.asm"
    include "game.asm"
    include "over.asm"

;================
; End of cart
;================

    ORG $FFFA ; 2k = $F7FA, 4k = $FFFA

InterruptVectors:

    .word InitSystem    ; NMI
    .word InitSystem    ; RESET
    .word InitSystem    ; IRQ

    END
