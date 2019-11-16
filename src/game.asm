;================
; Game
;================

; Constants

GAME_AUDIO_VOLUME = 4
GAME_AUDIO_LENGTH   = 32
GAME_AUDIO_STEP     = 9
GAME_AUDIO_OFFSET   = 1

; Object Code

    include "objects/score.asm"
    include "objects/web.asm"
    include "objects/spider.asm"
    include "objects/line.asm"
    include "objects/bug.asm"
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
    sta SampleStep

    ; Load Audio Settings
    lda #GAME_AUDIO_VOLUME
    sta AUDV0

    ; Make it so that we play the first note immediately
    lda #GAME_AUDIO_LENGTH-1
    sta AudioStep
    lda #2
    sta FrameTimer

    ; Initialize Objects
    jsr ScoreInit
    jsr SpiderInit
    jsr LineInit
    jsr BugInit
;    jsr SwatterInit

    rts

GameVerticalBlank:

    ; Refresh random values
    jsr Random

    ; Update Objects
    jsr SpiderUpdate
    jsr LineUpdate
    jsr BugUpdate
;    jsr SwatterUpdate
    jsr ScoreUpdate

    ; Reset Collisions
    sta CXCLR

    ; Clear horizontal movement
    sta HMCLR

    ; Update Positions
    jsr SpiderPosition
    jsr LinePosition
    jsr BugPosition
;    jsr SwatterPosition

    ; Set final x positions
    sta WSYNC
    sta HMOVE

    rts

GameOverScan:

    ; Audio Routines
    jsr GameAudio
    jsr GameSample

    ; State Routines
    jsr GameDeath

    rts

GameSample:

    ldx SampleStep
    cpx #0
    beq .game_sample_return

    dex
    bne .game_sample_return

.game_sample_mute:
    lda #0
    sta AUDV1
    sta AUDF1
    sta AUDC1

.game_sample_return:
    stx SampleStep
    rts

GameAudio:

    ldx FrameTimer
    cpx #GAME_AUDIO_OFFSET
    beq .game_audio_mute_note
    cpx #0
    bne .game_audio_return

    ; Reset Timer
    ldx #GAME_AUDIO_STEP
    stx FrameTimer

.game_audio_play:

    ; Increment melody position
    ldy AudioStep
    iny

    cpy #GAME_AUDIO_LENGTH
    bne .game_audio_play_note

    ; Loop our audio step
    ldy #0

.game_audio_play_note:

    ; Save current position
    sty AudioStep

    ; Melody Line
    lda GameTone0,y
    cmp #$FF
    beq .game_audio_mute_note

    sta AUDC0
    lda GameAudio0,y
    sta AUDF0
    lda #GAME_AUDIO_VOLUME
    sta AUDV0

    rts

.game_audio_mute_note:

    lda #0
    sta AUDF0
    sta AUDC0
    sta AUDV0

.game_audio_return:
    rts

GameDeath:
    lda ScoreValue+0
    cmp #0
    bne .game_death_return

    ; Show Game Over Screen
    jsr OverInit

.game_death_return:
    rts

GameKernel:

    ; Turn on display
    lda #0
    sta VBLANK

.game_kernel_score:

    ; Draw Score on top first
    jsr ScoreDraw

.game_kernel_objects_start:

    ; Setup Drawing Objects
    jsr WebDrawStart
    jsr SpiderDrawStart
    jsr LineDrawStart
    jsr BugDrawStart
;    jsr SwatterDrawStart

    ; Start Scanline Counter
    ldx #KERNEL_SCANLINES-SCORE_LINES

    ; Half scanline counter in Temp+1
    lda #(KERNEL_SCANLINES-SCORE_LINES)/2
    sta Temp+1

.game_kernel_objects:

    ; Draw Objects in order

;    jsr LineDraw
;    jsr BugDraw
    jsr WebDraw ; Every 6 lines

    sta WSYNC
    dex
    beq .game_kernel_clean

    jsr SpiderDraw ; Every odd scanline
;    jsr SwatterDraw

    sta WSYNC
    dec Temp+1
    dex
    beq .game_kernel_clean

    lda Temp+1
    jsr LineDraw
    jsr BugDraw

;    sta WSYNC
    dex
    beq .game_kernel_clean

    jsr SpiderDraw
;    jsr SwatterDraw

    sta WSYNC
    dec Temp+1
    dex
    beq .game_kernel_clean

    lda Temp+1
    jsr LineDraw
    jsr BugDraw

;    sta WSYNC
    dex
    beq .game_kernel_clean

    jsr SpiderDraw
;    jsr SwatterDraw

    sta WSYNC
    dec Temp+1
    dex
    bne .game_kernel_objects

.game_kernel_clean:

    jsr WebClean
    jsr SpiderClean
    jsr LineClean
    jsr BugClean
;    jsr SwatterDraw

    sta WSYNC

.game_kernel_return:
    rts

GameTone0:
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #6
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #6
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF
    .byte #6
    .byte #$FF

GameAudio0:
    .byte #13   ; D
    .byte #$FF
    .byte #15   ; B
    .byte #$FF
    .byte #13   ; D
    .byte #$FF
    .byte #15   ; B
    .byte #$FF
    .byte #13   ; D
    .byte #13   ; D
    .byte #15   ; B
    .byte #$FF
    .byte #12   ; D#
    .byte #$FF
    .byte #15   ; B
    .byte #$FF
    .byte #11   ; E
    .byte #$FF
    .byte #14   ; C#
    .byte #$FF
    .byte #11
    .byte #$FF
    .byte #14
    .byte #$FF
    .byte #11
    .byte #11
    .byte #14
    .byte #$FF
    .byte #11
    .byte #$FF
    .byte #14
    .byte #$FF
