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

KERNEL_IMAGE_MIRROR_DATA   = #3
KERNEL_IMAGE_FULL_DATA = #6
KERNEL_IMAGE_LINE   = #8
KERNEL_IMAGE_SIZE   = #24 ; KERNEL_SCANLINES/KERNEL_IMAGE_LINE

; Game States
STATE_LOGO          = #0
STATE_TITLE         = #1
STATE_GAME          = #2

; Kernel Types
KERNEL_FULL_IMAGE   = #0
KERNEL_GAME         = #1

;================
; Variables
;================

    SEG.U vars
    org $80

State               ds 1
KernelType          ds 1

Frame               ds 1
FrameTimer          ds 1

ImagePtr            ds 2
ImageVisible        ds 1

AudioStep           ds 1

PlayerPtr           ds 2
PlayerPosition      ds 2
PlayerCounter       ds 1

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
    lda State
    cmp #STATE_LOGO
    beq .vblank_logic_logo
    cmp #STATE_TITLE
    beq .vblank_logic_title
    cmp #STATE_GAME
    beq .vblank_logic_game
    bne .vblank_logic_default

.vblank_logic_logo:
    jsr LogoVerticalBlank
    jmp .vblank_loop

.vblank_logic_title:
    jsr TitleVerticalBlank
    jmp .vblank_loop

.vblank_logic_game:
.vblank_logic_default:
    jsr GameVerticalBlank

.vblank_loop:
    ; WSYNC until Timer is complete
    sta WSYNC
    lda INTIM
    bne .vblank_loop

.vblank_return:
    rts

Kernel:

    ; Check which kernel is selected
    lda KernelType
    cmp #KERNEL_GAME
    beq KernelGame
    cmp #KERNEL_FULL_IMAGE
    beq KernelFullImage
    bne KernelDefault

KernelDefault:
KernelFullImage:

    ; Playfield Control
    lda #%00000000 ; No mirroring
    sta CTRLPF

    ; Start Counters
    ldx #KERNEL_IMAGE_LINE ; Scanline Counter
    ldy #0 ; Image Counter

    ; Turn on display
    lda #0
    sta VBLANK

    sta WSYNC

.kernel_full_image:

    ; 76 machine cycles per scanline
    sta WSYNC

.kernel_full_image_load: ; 66 cycles

    ; First half of image
    lda TitleImage,y ; 5
    sta PF0 ; 4
    lda TitleImage+1,y ; 5
    sta PF1 ; 4
    lda TitleImage+2,y ; 5
    sta PF2 ; 4

    sleep 6

    ; Second half of image
    ;lda (ImagePtr+#3),y ; 5 ; Need to figure out indirect addressing with index adjustment
    lda TitleImage+3,y ; 5
    sta PF0 ; 4
    lda TitleImage+4,y ; 5
    sta PF1 ; 4
    lda TitleImage+5,y ; 5
    sta PF2 ; 4

.kernel_full_image_index: ; 4 cycles

    dex ; 2
    bne .kernel_full_image ; 2

.kernel_full_image_index_next: ; 6 cycles

    ldx #KERNEL_IMAGE_LINE ; 2
    tya ; 2
    clc ; 2
    adc #KERNEL_IMAGE_FULL_DATA ; 2
    tay ; 2
    cpy #KERNEL_IMAGE_SIZE*KERNEL_IMAGE_FULL_DATA
    bne .kernel_full_image ; 2

.kernel_full_image_clean:
    sta WSYNC

    ; Clear out playfield
    lda #0
    sta PF0
    sta PF1
    sta PF2

.kernel_full_image_return:
    rts

KernelGame:

    ; Playfield Control
    lda #%00000001 ; Mirrored
    sta CTRLPF

    ; Set player 0 to be double size
    lda NUSIZ0
    and #%11111000
    ora #%00000101
    sta NUSIZ0

    ; Turn on display
    lda #0
    sta VBLANK

    ; Start Counters
    ldx #KERNEL_SCANLINES ; Scanline Counter
    ldy #0 ; Image Counter

.kernel_game:

.kernel_game_player:

    ; Store image position in stack
    tya
    pha

    txa
    sbc PlayerPosition+1
    cmp #GAME_P0_SIZE*2
    bcc .kernel_game_player_draw

.kernel_game_player_blank:

    ; Draw empty sprite
    lda #0
    sta GRP0
    jmp .kernel_game_player_restore

.kernel_game_player_draw:

    ; Load sprite line
    lsr ; Divide by 2
    tay
    lda (PlayerPtr),y
    sta GRP0

.kernel_game_player_restore:

    ; Restore image position from stack
    pla
    tay

    ; Sync up to horizontal line
    sta WSYNC

.kernel_game_image:

    ; Check to see if new playfield needs to be loaded
    txa
    and #%00000111
    bne .kernel_game_line

.kernel_game_image_load:

    ; Draw Image
    lda (ImagePtr),y ; 3
    sta PF0 ; 1
    iny ; 2
    lda (ImagePtr),y ; 3
    sta PF1 ; 1
    iny ; 2
    lda (ImagePtr),y ; 3
    sta PF2 ; 1
    iny ; 2

.kernel_game_line:
    dex
    bne .kernel_game

.kernel_game_clean:
    sta WSYNC

    ; Clear out playfield
    lda #0
    sta PF0
    sta PF1
    sta PF2

    ; Clear out Player sprite
    sta GRP0

.kernel_game_return:
    rts

OverScan:

    ; End of screen, enter blanking
    lda #%01000010
    sta VBLANK

    ; Setup Timer
    lda #36 ; #KERNEL_OVERSCAN*76/64
    sta TIM64T

.overscan_logic:
    lda State
    cmp #STATE_LOGO
    beq .overscan_logic_logo
    cmp #STATE_TITLE
    beq .overscan_logic_title
    cmp #STATE_GAME
    beq .overscan_logic_game
    bne .overscan_logic_default

.overscan_logic_logo:
    jsr LogoOverScan
    jmp .overscan_loop

.overscan_logic_title:
    jsr TitleOverScan
    jmp .overscan_loop

.overscan_logic_game:
.overscan_logic_default:
    jsr GameOverScan

.overscan_loop:
    ; WSYNC until Timer is complete
    sta WSYNC
    lda INTIM
    bne .overscan_loop

.overscan_return:
    rts


;================
; State Code
;================

    ; Game state logic
    include "logo.asm"
    include "title.asm"
    include "game.asm"

;================
; End of cart
;================

    ORG $FFFA

InterruptVectors:

    .word InitSystem    ; NMI
    .word InitSystem    ; RESET
    .word InitSystem    ; IRQ

    END
