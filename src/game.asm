;================
; Game
;================

; Constants

GAME_AUDIO_VOLUME   = 2
GAME_AUDIO_LENGTH   = 32
GAME_AUDIO_STEP     = 9
GAME_AUDIO_OFFSET   = 1
GAME_AUDIO_TONE     = 6

; Object Code

    include "objects/level.asm"
    include "objects/score.asm"
    include "objects/web.asm"
    include "objects/spider.asm"
    include "objects/line.asm"
    include "objects/bug.asm"
    include "objects/swatter.asm"

; Initialization

GameInit:

    ; Setup logic and kernel
    SET_POINTER VBlankPtr, GameVerticalBlank
    SET_POINTER KernelPtr, GameKernel
    SET_POINTER OverScanPtr, GameOverScan

    ; Mute Audio
    lda #0
;    sta AUDC0
;    sta AUDV0
;    sta AUDF0
    ;sta AUDC1
    sta AUDV1
    ;sta AUDF1
    sta SampleStep

    ; Load Audio Settings
    lda #GAME_AUDIO_VOLUME
    sta AUDV0

    ; Make it so that we play the first note immediately
    lda #GAME_AUDIO_LENGTH-1
    sta AudioStep
    lda #2
    sta FrameTimer

    ; Reset NuSiz
;    lda #0
;    sta NuSiz0
;    sta NUSIZ0
;    sta NuSiz1
;    sta NUSIZ1

    ; Initialize Objects
    jsr LevelInit
    jsr ScoreInit
    jsr SpiderInit
    jsr LineInit
    jsr BugInit
    jsr SwatterInit

    rts

GameVerticalBlank:

    ; Refresh random values
    jsr Random

    ; Update Objects
    jsr LevelUpdate
    jsr SpiderUpdate
    jsr LineUpdate
    jsr BugUpdate
    jsr SwatterUpdate
    jsr ScoreUpdate

    ; Reset Collisions
    sta CXCLR

    ; Clear horizontal movement
    sta HMCLR

    ; Update Positions
    jsr SpiderPosition
    jsr LinePosition
    jsr BugPosition
    jsr SwatterPosition

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
    beq .game_sample_return

    dex
    bne .game_sample_return

.game_sample_mute:
    lda #0
    sta AUDV1
    ;sta AUDF1
    ;sta AUDC1

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
    lda GameAudio0,y
    cmp #$FF
    beq .game_audio_mute_note
    sta AUDF0
    lda #GAME_AUDIO_TONE
    sta AUDC0
    lda #GAME_AUDIO_VOLUME
    sta AUDV0

    rts

.game_audio_mute_note:

    lda #0
    ;sta AUDF0
    ;sta AUDC0
    sta AUDV0

.game_audio_return:
    rts

GameDeath:
    lda ScoreValue+0
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
    jsr SwatterDrawStart
    jsr LineDrawStart
    jsr BugDrawStart

    ; Set missle and sprite sizes
    lda #%00110101
    sta NUSIZ0
    lda #%00110111
    sta NUSIZ1

    ; Set playfield settings and ball size
    lda #%00100001
    sta CTRLPF

    ; Half scanline counter
    ldx #(KERNEL_SCANLINES-SCORE_LINES)/2-2

    ; 6 line counter
    lda #0
    sta Temp+2

    ; Load background color and start first line
    lda WebColor+0
    sta WSYNC
    sta COLUBK

.game_kernel_objects: ; 5 or 10 cycles

    lda Temp+2 ; 3
    bne .game_kernel_missle ; 2*

    lda #3 ; 2
    sta Temp+2 ; 3

.game_kernel_web: ; 32 cycles
    ; Web

    ldy WebIndex ; 3

    ; Load Image
    lda WebImagePF0,y ; 4
    sta PF0 ; 3
    lda WebImagePF1,y ; 4
    sta PF1 ; 3
    lda WebImagePF2,y ; 4
    sta PF2 ; 3

    inc WebIndex ; 5

    jmp .game_kernel_line ; 3

.game_kernel_missle:

.game_kernel_missle_bug_0: ; 18 cycles
    ; First Bug

    ; Top
    cpx BugDrawPosTop+0 ; 3
    bcs .game_kernel_missle_bug_0_off_1 ; 2 or 3 if branching

    ; Bottom
    cpx BugDrawPosBottom+0 ; 3
    bcc .game_kernel_missle_bug_0_off_2 ; 2 or 3 if branching

.game_kernel_missle_bug_0_on:
    ldy #%00000010 ; 2
    jmp .game_kernel_missle_bug_0_set ; 3

.game_kernel_missle_bug_0_off_1:
    sleep 5
.game_kernel_missle_bug_0_off_2:
    sleep 2
    ldy #%00000000 ; 2
.game_kernel_missle_bug_0_set:
    sty ENAM0 ; 3

.game_kernel_missle_bug_1: ; 18 cycles
    ; Second Bug

    ; Top
    cpx BugDrawPosTop+1 ; 3
    bcs .game_kernel_missle_bug_1_off_1 ; 2 or 3 if branching

    ; Bottom
    cpx BugDrawPosBottom+1 ; 3
    bcc .game_kernel_missle_bug_1_off_2 ; 2 or 3 if branching

.game_kernel_missle_bug_1_on:
    ldy #%00000010 ; 2
    jmp .game_kernel_missle_bug_1_set ; 3

.game_kernel_missle_bug_1_off_1:
    sleep 5
.game_kernel_missle_bug_1_off_2:
    sleep 2
    ldy #%00000000 ; 2
.game_kernel_missle_bug_1_set:
    sty ENAM1 ; 3

.game_kernel_line: ; 18 cycles
    ; Line

    ; Top
    cpx LineDrawPos+1 ; 3
    bcs .game_kernel_line_set_off_1 ; 2 or 3 if branching

    ; Bottom
    cpx LineDrawPos+0 ; 3
    bcc .game_kernel_line_set_off_2 ; 2 or 3 if branching

.game_kernel_line_set_on:
    ldy #%00000010 ; 2
    jmp .game_kernel_line_set ; 3

.game_kernel_line_set_off_1:
    sleep 5
.game_kernel_line_set_off_2:
    sleep 2
    ldy #%00000000 ; 2
.game_kernel_line_set:
    sty ENABL ; 3

    ; Next Line
    ;sleep 17 or 16
    sta WSYNC

.game_kernel_sprite:

.game_kernel_sprite_spider: ; 34 cycles
    ; Spider

    ldy SpiderIndex ; 3
    bmi .game_kernel_sprite_spider_load_1 ; At end of sprite / 2 or 3 if branching

    ; Check y position to see if we should be drawing
    txa ; 2
    sbc SpiderDrawPos ; 3
    bpl .game_kernel_sprite_spider_load_2 ; 2 or 3 if branching

.game_kernel_sprite_spider_draw:

    ; Decrement sprite index
    dey ; 2
    bpl .game_kernel_sprite_spider_grab ; 2 or 3 if branching

    lda #0 ; 2
    ;sleep 1
    jmp .game_kernel_sprite_spider_store ; 3

.game_kernel_sprite_spider_grab:
    lda (SpiderPtr),y ; 5
.game_kernel_sprite_spider_store:
    sty SpiderIndex ; 3
    sta SpiderLine ; 3

    jmp .game_kernel_sprite_spider_load_3 ; 3

.game_kernel_sprite_spider_load_1:
    sleep 7
.game_kernel_sprite_spider_load_2:
    sleep 15
    lda SpiderLine ; 3
.game_kernel_sprite_spider_load_3:
    sta GRP0 ; 3

.game_kernel_sprite_swatter: ; 30 cycles
    ; Swatter

    ; Check if wait state
    ;bit SwatterState
    ;bpl .game_kernel_sprite_swatter_load

    ldy SwatterIndex ; 3
    bmi .game_kernel_sprite_swatter_load_1 ; At end of sprite / 2 or 3 if branching

    ; Check y position to see if we should be drawing
    txa ; 2
    sbc SwatterDrawPos ; 3
    bpl .game_kernel_sprite_swatter_load_2 ; 2 or 3 if branching

.game_kernel_sprite_swatter_draw:
    lda SwatterSprite,y ; 4
    sta SwatterLine ; 3

    ; Decrement sprite index
    dec SwatterIndex ; 5

    jmp .game_kernel_sprite_swatter_line ; 3

.game_kernel_sprite_swatter_load_1:
    sleep 7
.game_kernel_sprite_swatter_load_2:
    sleep 11
    lda SwatterLine ; 3
.game_kernel_sprite_swatter_line:
    sta GRP1 ; 3

.game_kernel_sprite_end: ; 12 or 11 cycles

    ;sta WSYNC

    ; New line, decrement half scanline, and increment 3 line counter
    dec Temp+2 ; 5
    dex ; 2
    beq .game_kernel_clean ; 2 or 3 if branching
    jmp .game_kernel_objects ; 3

.game_kernel_clean:

    sta WSYNC

    lda #0
    sta COLUBK
    sta COLUPF
    sta COLUP0
    sta COLUP1
    sta PF0
    sta PF1
    sta PF2
    sta GRP0
    sta GRP1
    sta ENAM0
    sta ENAM1
    sta ENABL

    sta WSYNC

.game_kernel_return:
    rts

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
