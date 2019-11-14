;================
; Game
;================

; Object Code

    include "objects/score.asm"
    include "objects/web.asm"
    include "objects/spider.asm"
;    include "objects/line.asm"
;    include "objects/bug.asm"
;    include "objects/swatter.asm"

; Initialization

GameInit:

    ; Setup logic and kernel
    SET_POINTER VBlankPtr, GameVerticalBlank
    SET_POINTER KernelPtr, GameKernel
    SET_POINTER OverScanPtr, GameOverScan

    ; Mute Audio
    lda #0
    sta AUDC0
    sta AUDV0
    sta AUDF0
    sta AUDC1
    sta AUDV1
    sta AUDF1

    ; Initialize Objects
    jsr SpiderInit
;    jsr LineInit
;    jsr BugInit
;    jsr SwatterInit

    rts

GameVerticalBlank:

    ; Clear horizontal movement
    sta HMCLR

    ; Update Objects
    jsr SpiderUpdate
;    jsr LineUpdate
;    jsr BugUpdate
;    jsr SwatterUpdate
    jsr ScoreUpdate

    ; Set final x positions
    sta WSYNC
    sta HMOVE

    rts

GameOverScan:
    ; Do nothing at the moment
    ; Room for some updating...
    rts

GameKernel:

    ; Turn on display
    lda #0
    sta VBLANK

.game_kernel_score:

    ; Draw Score on top first
    jsr ScoreDraw

.game_kernel_objects_start:

    ; Start Scanline Counter
    ldx #KERNEL_SCANLINES-SCORE_LINES

    ; Setup Drawing Objects
    jsr WebDrawStart
    jsr SpiderDrawStart

.game_kernel_objects:

    ; Draw Objects in order

    jsr WebDraw ; Every 6 lines

    sta WSYNC
    dex
    beq .game_kernel_clean

    jsr SpiderDraw ; Every other scanline

    sta WSYNC
    dex
    beq .game_kernel_clean

    sta WSYNC
    dex
    beq .game_kernel_clean

    jsr SpiderDraw

    sta WSYNC
    dex
    beq .game_kernel_clean

    sta WSYNC
    dex
    beq .game_kernel_clean

    jsr SpiderDraw

    sta WSYNC
    dex
    bne .game_kernel_objects

.game_kernel_clean:

    jsr WebClean
    jsr SpiderClean
;    jsr LineClean

    sta WSYNC

.game_kernel_return:
    rts
