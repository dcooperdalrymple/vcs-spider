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

    ; Reset NuSiz
    lda #0
    sta NuSiz0
    sta NUSIZ0
    sta NuSiz1
    sta NUSIZ1

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
    jsr SwatterDrawStart
    jsr LineDrawStart
    jsr BugDrawStart

    ; Start Scanline Counter
    ldx #KERNEL_SCANLINES-SCORE_LINES-5
    ; The extra 5 is for processing overflow

    ; Half scanline counter in Temp+1
    lda #(KERNEL_SCANLINES-SCORE_LINES)/2
    sta Temp+1

.game_kernel_objects:

    sta WSYNC

.game_kernel_web:

    ; Web
    ldy WebIndex

    ; Load Image
    lda WebImagePF0,y
    sta PF0
    lda WebImagePF1,y
    sta PF1
    lda WebImagePF2,y
    sta PF2

    inc WebIndex

.game_kernel_line_1:
    ; Line (1st time)

    bit LineEnabled
    bpl .game_kernel_line_1_skip

    ; Load half-line
    lda Temp+1

    ldy #%00000000

    ; Top
    cmp LineDrawPos+1
    bcs .game_kernel_line_1_off

    ; Bottom
    cmp LineDrawPos+0
    bcc .game_kernel_line_1_off

.game_kernel_line_1_on:
    ldy #%00000010

.game_kernel_line_1_off:
    sty ENABL

.game_kernel_line_1_skip:

    dex
    sta WSYNC

.game_kernel_spider_1:
    ; Spider (1st time)

    ldy SpiderIndex
    bmi .game_kernel_spider_1_load  ; At end of sprite
    bne .game_kernel_spider_1_draw  ; Currently drawing (not zero)

    ; Check y position to see if we should start
    lda Temp+1  ; Use half scanline
    sbc SpiderDrawPos
    bpl .game_kernel_spider_1_load

.game_kernel_spider_1_draw:
    lda (SpiderPtr),y
    sta SpiderLine

    ; Increment sprite index
    inc SpiderIndex

    ; See if we're at the end
    cpy #SPIDER_SPRITE_SIZE
    bne .game_kernel_spider_1_line
    ldy #-1 ; Load a negative value to tell draw routine to stop
    sty SpiderIndex
    lda #0
    sta SpiderLine

.game_kernel_spider_1_load:
    lda SpiderLine
.game_kernel_spider_1_line:
    sta GRP0

.game_kernel_swatter_1:
    ; Swatter (1st time)

    ; Check if wait state
    bit SwatterState
    bpl .game_kernel_swatter_1_load

    ldy SwatterIndex
    bmi .game_kernel_swatter_1_load ; At end of sprite
    bne .game_kernel_swatter_1_draw ; Currently drawing (not zero)

    ; Check y position to see if we should start
    lda Temp+1 ; Use half scanline
    sbc SwatterDrawPos
    bpl .game_kernel_swatter_1_load

.game_kernel_swatter_1_draw:
    lda SwatterSprite,y
    sta SwatterLine

    ; Increment index
    inc SwatterIndex

    ; See if we're at the end
    cpy #(SWATTER_SPRITE_SIZE-1)
    bne .game_kernel_swatter_1_line
    ldy #-1 ; Load a negative value to tell draw routine to stop
    sty SwatterIndex

.game_kernel_swatter_1_load:
    lda SwatterLine
.game_kernel_swatter_1_line:
    sta GRP1

    ; New line and decrement half scanline
    dec Temp+1
    dex
    sta WSYNC

    ; Preload half-line
    lda Temp+1

.game_kernel_line_2:
    ; Line (2nd time)

    bit LineEnabled
    bpl .game_kernel_line_2_skip

    ldy #%00000000

    ; Top
    cmp LineDrawPos+1
    bcs .game_kernel_line_2_off

    ; Bottom
    cmp LineDrawPos+0
    bcc .game_kernel_line_2_off

.game_kernel_line_2_on:
    ldy #%00000010

.game_kernel_line_2_off:
    sty ENABL

.game_kernel_line_2_skip:

.game_kernel_bug_1_0:
    ; First Bug (1st time)

    ldy #%00000000

    ; Top
    cmp BugDrawPosTop+0
    bcs .game_kernel_bug_1_0_off

    ; Bottom
    cmp BugDrawPosBottom+0
    bcc .game_kernel_bug_1_0_off

.game_kernel_bug_1_0_on:
    ldy #%00000010

.game_kernel_bug_1_0_off:
    sty ENAM0

.game_kernel_bug_1_1:
    ; Second Bug (1st time)

    ldy #%00000000

    ; Top
    cmp BugDrawPosTop+1
    bcs .game_kernel_bug_1_1_off

    ; Bottom
    cmp BugDrawPosBottom+1
    bcc .game_kernel_bug_1_1_off

.game_kernel_bug_1_1_on:
    ldy #%00000010

.game_kernel_bug_1_1_off:
    sty ENAM1

    ; Next Line
    dex
    sta WSYNC

.game_kernel_spider_2:
    ; Spider (2nd time)

    ldy SpiderIndex
    bmi .game_kernel_spider_2_load  ; At end of sprite
    bne .game_kernel_spider_2_draw  ; Currently drawing (not zero)

    ; Check y position to see if we should start
    lda Temp+1  ; Use half scanline
    sbc SpiderDrawPos
    bpl .game_kernel_spider_2_load

.game_kernel_spider_2_draw:
    lda (SpiderPtr),y
    sta SpiderLine

    ; Increment sprite index
    inc SpiderIndex

    ; See if we're at the end
    cpy #SPIDER_SPRITE_SIZE
    bne .game_kernel_spider_2_line
    ldy #-1 ; Load a negative value to tell draw routine to stop
    sty SpiderIndex
    lda #0
    sta SpiderLine

.game_kernel_spider_2_load:
    lda SpiderLine
.game_kernel_spider_2_line:
    sta GRP0

.game_kernel_swatter_2:
    ; Swatter (2nd time)

    ; Check if wait state
    bit SwatterState
    bpl .game_kernel_swatter_2_load

    ldy SwatterIndex
    bmi .game_kernel_swatter_2_load ; At end of sprite
    bne .game_kernel_swatter_2_draw ; Currently drawing (not zero)

    ; Check y position to see if we should start
    lda Temp+1 ; Use half scanline
    sbc SwatterDrawPos
    bpl .game_kernel_swatter_2_load

.game_kernel_swatter_2_draw:
    lda SwatterSprite,y
    sta SwatterLine

    ; Increment index
    inc SwatterIndex

    ; See if we're at the end
    cpy #(SWATTER_SPRITE_SIZE-1)
    bne .game_kernel_swatter_2_line
    ldy #-1 ; Load a negative value to tell draw routine to stop
    sty SwatterIndex

.game_kernel_swatter_2_load:
    lda SwatterLine
.game_kernel_swatter_2_line:
    sta GRP1

    ; Next Line and half-line
    dec Temp+1
    dex
    sta WSYNC

    ; Preload half-line
    lda Temp+1

.game_kernel_line_3:
    ; Line (3rd time)

    bit LineEnabled
    bpl .game_kernel_line_3_skip

    ldy #%00000000

    ; Top
    cmp LineDrawPos+1
    bcs .game_kernel_line_3_off

    ; Bottom
    cmp LineDrawPos+0
    bcc .game_kernel_line_3_off

.game_kernel_line_3_on:
    ldy #%00000010

.game_kernel_line_3_off:
    sty ENABL

.game_kernel_line_3_skip:

.game_kernel_bug_2_0:
    ; First Bug (2nd time)

    ldy #%00000000

    ; Top
    cmp BugDrawPosTop+0
    bcs .game_kernel_bug_2_0_off

    ; Bottom
    cmp BugDrawPosBottom+0
    bcc .game_kernel_bug_2_0_off

.game_kernel_bug_2_0_on:
    ldy #%00000010

.game_kernel_bug_2_0_off:
    sty ENAM0

.game_kernel_bug_2_1:
    ; Second Bug (2nd time)

    ldy #%00000000

    ; Top
    cmp BugDrawPosTop+1
    bcs .game_kernel_bug_2_1_off

    ; Bottom
    cmp BugDrawPosBottom+1
    bcc .game_kernel_bug_2_1_off

.game_kernel_bug_2_1_on:
    ldy #%00000010

.game_kernel_bug_2_1_off:
    sty ENAM1

    ; Next Line
    dex
    sta WSYNC

.game_kernel_spider_3:
    ; Spider (3rd time)

    ldy SpiderIndex
    bmi .game_kernel_spider_3_load  ; At end of sprite
    bne .game_kernel_spider_3_draw  ; Currently drawing (not zero)

    ; Check y position to see if we should start
    lda Temp+1  ; Use half scanline
    sbc SpiderDrawPos
    bpl .game_kernel_spider_3_load

.game_kernel_spider_3_draw:
    lda (SpiderPtr),y
    sta SpiderLine

    ; Increment sprite index
    inc SpiderIndex

    ; See if we're at the end
    cpy #SPIDER_SPRITE_SIZE
    bne .game_kernel_spider_3_line
    ldy #-1 ; Load a negative value to tell draw routine to stop
    sty SpiderIndex
    lda #0
    sta SpiderLine

.game_kernel_spider_3_load:
    lda SpiderLine
.game_kernel_spider_3_line:
    sta GRP0

.game_kernel_spider_3_skip:

.game_kernel_swatter_3:
    ; Swatter (3rd time)

    ; Check if wait state
    bit SwatterState
    bpl .game_kernel_swatter_3_load

    ldy SwatterIndex
    bmi .game_kernel_swatter_3_load ; At end of sprite
    bne .game_kernel_swatter_3_draw ; Currently drawing (not zero)

    ; Check y position to see if we should start
    lda Temp+1 ; Use half scanline
    sbc SwatterDrawPos
    bpl .game_kernel_swatter_3_load

.game_kernel_swatter_3_draw:
    lda SwatterSprite,y
    sta SwatterLine

    ; Increment index
    inc SwatterIndex

    ; See if we're at the end
    cpy #(SWATTER_SPRITE_SIZE-1)
    bne .game_kernel_swatter_3_line
    ldy #-1 ; Load a negative value to tell draw routine to stop
    sty SwatterIndex

.game_kernel_swatter_3_load:
    lda SwatterLine
.game_kernel_swatter_3_line:
    sta GRP1

.game_kernel_swatter_3_skip:

    ; New line and decrement half scanline
    dec Temp+1
    dex
    beq .game_kernel_clean
    jmp .game_kernel_objects

.game_kernel_clean:

    jsr WebClean
    jsr SpiderClean
    jsr LineClean
    jsr BugClean
    jsr SwatterClean

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
