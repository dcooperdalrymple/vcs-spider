;================
; Constants
;================

TITLE_BG_COLOR          = #$00
TITLE_WEB_COLOR         = #$06
TITLE_LABEL_COLOR       = #$0E
TITLE_SPIDER_COLOR      = #$56
TITLE_SPIDER_BW_COLOR   = #$0E

TITLE_AUDIO_0_TONE      = 4
TITLE_AUDIO_0_VOLUME    = 1
TITLE_AUDIO_1_VOLUME    = 5
TITLE_AUDIO_LENGTH      = 16
TITLE_AUDIO_STEP        = 9

TITLE_FRAME_TOP_LINES   = 12
TITLE_FRAME_BOT_LINES   = 5
TITLE_LABEL_LINE        = 7

TITLE_GAP_SIZE          = #16

TITLE_SPIDER_POS_X      = #(KERNEL_WIDTH/4)-(8*3)-(8*2)-2
TITLE_SPIDER_SIZE       = #9
TITLE_SPIDER_LINE_SIZE  = #4

TitleInit:

    ; Setup logic and kernel
    SET_POINTER VBlankPtr, TitleVerticalBlank
    SET_POINTER KernelPtr, TitleKernel
    SET_POINTER OverScanPtr, TitleOverScan

    ; Load audio settings

    ; Melody Line
    lda #TITLE_AUDIO_0_TONE
    sta AUDC0
    ;lda #TITLE_AUDIO_0_VOLUME
    ;sta AUDV0

    ; Make it so that we play the first note immediately
    lda #TITLE_AUDIO_LENGTH-1
    sta AudioStep
    lda #1
    sta FrameTimer

    ; Setup Spider Sprite
    SET_POINTER SpiderPtr, TitleSpider

    lda #%00010110  ; Triple Sprite and 2 clock size missle0
    sta NUSIZ0
    lda #%00000110  ; Triple Sprite
    sta NUSIZ1

    lda #$FF        ; Reflect P1
    sta REFP1
    lda #0          ; No reflect
    sta REFP0

    ; Drums and Bass
    ;lda #0
    ;sta AUDC1
    sta AUDV1

    ;lda #0
    sta SpiderDrawPos ; Initialize animation state

    ; Disable at start
    ;lda #0
    sta ENAM0

    ; Set initial button state
    ;lda #0
    sta InputState

    ; Set initial select state
    sta Temp+2

    rts

TitleVerticalBlank:

    ; Refresh random values
    jsr Random

    jsr TitlePosition
    jsr TitleAnimation
    jsr TitleColor

    rts

TitlePosition:

    ; Position Spider
    ldx #0                      ; Object (player0)
    lda #TITLE_SPIDER_POS_X     ; X Position
    jsr PosObject

    ldx #1                      ; Object (player1)
    lda #(TITLE_SPIDER_POS_X+8) ; X Position
    jsr PosObject

    ; Position Web Line
    ldx #2                      ; Object (missle0)
    lda #(TITLE_SPIDER_POS_X+8) ; X Position
    jsr PosObject

    sta WSYNC
    sta HMOVE

    rts

TitleAnimation:

    lda SWCHB
    and #%00000010
    bne .title_animation_state_check

    lda Temp+2

.title_animation_state_on:
    ora #%01000000
    sta Temp+2
    jmp .title_animation_load

.title_animation_state_check:
    bit Temp+2
    bvc .title_animation_load

    lda Temp+2
    and #%10111111

.title_animation_state_swap:
    bpl .title_animation_state_bug

.title_animation_state_spider:
    and #%01111111
    jmp .title_animation_state_set

.title_animation_state_bug:
    ora #%10000000

.title_animation_state_set:
    sta Temp+2

.title_animation_load:

    bit Temp+2
    bmi .title_animation_bug

.title_animation_spider:

    lda AudioStep
    beq .title_animation_spider_1
    cmp #4
    beq .title_animation_spider_2
    cmp #9
    beq .title_animation_spider_1
    cmp #12
    beq .title_animation_spider_2
    rts

.title_animation_spider_1:
    SET_POINTER SpiderPtr, TitleSpider
    lda #0
    jmp .title_animation_return

.title_animation_spider_2:
    SET_POINTER SpiderPtr, TitleSpider+#TITLE_SPIDER_SIZE
    lda #1
    jmp .title_animation_return

.title_animation_bug:

    lda AudioStep
    beq .title_animation_bug_1
    cmp #4
    beq .title_animation_bug_2
    cmp #9
    beq .title_animation_bug_1
    cmp #12
    beq .title_animation_bug_2
    rts

.title_animation_bug_1:
    SET_POINTER SpiderPtr, TitleBug
    lda #0
    jmp .title_animation_return

.title_animation_bug_2:
    SET_POINTER SpiderPtr, TitleBug+#TITLE_SPIDER_SIZE
    lda #1

.title_animation_return:
    sta SpiderDrawPos
    rts

TitleColor:

    ; Load Colors
    lda #TITLE_BG_COLOR
    sta COLUBK
    lda #TITLE_WEB_COLOR
    sta COLUPF

    ; Check b/w
    lda SWCHB
    REPEAT 4
    lsr
    REPEND
    bcc .title_bw

.title_color:
    lda #TITLE_SPIDER_COLOR
    sta COLUP0
    sta COLUP1

    rts

.title_bw:
    ; Load B/W Colors
    lda #TITLE_SPIDER_BW_COLOR
    sta COLUP0
    sta COLUP1

    rts

TitleOverScan:
    jsr TitleAudio
    jsr TitleState
    rts

TitleAudio:

    ldx FrameTimer
    bne .title_audio_return

    ; Reset Timer
    ldx #TITLE_AUDIO_STEP
    stx FrameTimer

.title_audio_play:

    ; Increment melody position
    ldy AudioStep
    iny

    ; Check if we're at the end of the melody
    cpy #TITLE_AUDIO_LENGTH
    bne .title_audio_play_note

    ; Loop our audio step
    ldy #0

.title_audio_play_note:

    ; Save current position
    sty AudioStep

.title_audio_play_melody:
    ; Basic Melody Line
    lda TitleAudio0,y
    bmi .title_audio_play_melody_mute

    sta AUDF0
    lda #TITLE_AUDIO_0_VOLUME
    sta AUDV0

    jmp .title_audio_play_rhythm

.title_audio_play_melody_mute:

    lda #0
    sta AUDV0

.title_audio_play_rhythm:

    ; Drums and Bass
    lda TitleTone1,y
    bmi .title_audio_play_rhythm_mute

    sta AUDC1
    lda TitleAudio1,y
    sta AUDF1
    lda #TITLE_AUDIO_1_VOLUME
    sta AUDV1

    rts

.title_audio_play_rhythm_mute:

    lda #0
    ;sta AUDF1
    ;sta AUDC1
    sta AUDV1

.title_audio_return:
    rts

TitleState:

    ; Check if Fire Button on controller 1 is released
    lda INPT4
    bmi .title_state_check

.title_state_on:
    lda #1
    sta InputState
    rts

.title_state_check:
    lda InputState
    beq .title_state_return

.title_state_next:
    ; Button is released, load up game
    jsr GameInit

.title_state_return:
    rts

TitleKernel:

    ; Playfield Control
    ;lda CtrlPf
    ;and #%11111110  ; No mirroring
    ;sta CtrlPf
    lda #%00000000
    sta CTRLPF

    ; Turn on display
    lda #0
    sta VBLANK

    sta WSYNC

TitleFrameTopDraw:

    ; Start Counters
    ldx #KERNEL_IMAGE_LINE ; Scanline Counter
    ldy #0 ; Image Counter

.title_frame_top:

    ; 76 machine cycles per scanline
    sta WSYNC

.title_frame_top_load: ; 66 cycles

    ; First half of image
    lda TitleFrameTop,y ; 5
    sta PF0 ; 4
    lda TitleFrameTop+1,y ; 5
    sta PF1 ; 4
    lda TitleFrameTop+2,y ; 5
    sta PF2 ; 4

    sleep 6

    ; Second half of image
    lda TitleFrameTop+3,y ; 5
    sta PF0 ; 4
    lda TitleFrameTop+4,y ; 5
    sta PF1 ; 4
    lda TitleFrameTop+5,y ; 5
    sta PF2 ; 4

.title_frame_top_index: ; 4 cycles

    dex ; 2
    bne .title_frame_top ; 2

.title_frame_top_index_next: ; 6 cycles

    ; Restore scanline counter
    ldx #KERNEL_IMAGE_LINE ; 2

    tya ; 2
    clc ; 2
    adc #KERNEL_IMAGE_FULL_DATA ; 2
    tay ; 2

    cpy #TITLE_LABEL_LINE*KERNEL_IMAGE_FULL_DATA ; 2
    bne .title_frame_top_label_color_skip ; 2
    lda #TITLE_LABEL_COLOR ; 2
    sta COLUPF ; 4
    nop ; 2
    jmp .title_frame_top_load ; 3

.title_frame_top_label_color_skip:

    cpy #TITLE_FRAME_TOP_LINES*KERNEL_IMAGE_FULL_DATA ; 2
    bne .title_frame_top ; 2

.title_frame_top_clean:

    ; Clear out playfield
    lda #0
    sta PF0
    sta PF1
    sta PF2

TitleWebDraw:

    bit Temp+2
    bmi .title_web_bug

.title_web_spider:
    lda #%00000010
    jmp .title_web_set
.title_web_bug:
    lda #%00000000
.title_web_set:
    sta ENAM0

    lda #TITLE_WEB_COLOR
    sta COLUP0

    ldx #TITLE_GAP_SIZE
.title_web_gap:
    dex
    sta WSYNC
    bne .title_web_gap

TitleSpiderDraw:

    ldy #TITLE_SPIDER_SIZE-1

    lda SpiderDrawPos
    cmp #1
    bne .title_spider_extra_web_disable

.title_spider_extra_web_start:
    ldx #TITLE_SPIDER_LINE_SIZE
.title_spider_extra_web_loop:
    sta WSYNC
    dex
    bne .title_spider_extra_web_loop

    dey
    cpy #TITLE_SPIDER_SIZE-3
    bne .title_spider_extra_web_start

.title_spider_extra_web_disable:
    lda #0
    ldx #TITLE_SPIDER_LINE_SIZE

    sta WSYNC

    sta ENAM0

    ; Check b/w
    lda SWCHB
    REPEAT 4
    lsr
    REPEND
    bcc .title_spider_bw

.title_spider_color:
    lda #TITLE_SPIDER_COLOR
    jmp .title_spider_color_set
.title_spider_bw:
    lda #TITLE_SPIDER_BW_COLOR
.title_spider_color_set:
    sta COLUP0

.title_spider:
    lda (SpiderPtr),y
    sta GRP0
    sta GRP1

.title_spider_delay:
    dex
    sta WSYNC
    bne .title_spider_delay

.title_spider_index:
    ldx #TITLE_SPIDER_LINE_SIZE
    dey
    bpl .title_spider

.title_spider_clean:

    ; Clear sprites
    lda #0
    sta GRP0
    sta GRP1

TitleFrameBottomDraw:

    ; Load Frame Color
    lda #TITLE_WEB_COLOR
    sta COLUPF

    ; Start Counters
    ldx #KERNEL_IMAGE_LINE ; Scanline Counter
    ldy #0 ; Image Counter

.title_frame_bottom:

    ; 76 machine cycles per scanline
    sta WSYNC

.title_frame_bottom_load: ; 66 cycles

    ; First half of image
    lda TitleFrameBottom,y ; 5
    sta PF0 ; 4
    lda TitleFrameBottom+1,y ; 5
    sta PF1 ; 4
    lda TitleFrameBottom+2,y ; 5
    sta PF2 ; 4

    sleep 6

    ; Second half of image
    lda TitleFrameBottom+3,y ; 5
    sta PF0 ; 4
    lda TitleFrameBottom+4,y ; 5
    sta PF1 ; 4
    lda TitleFrameBottom+5,y ; 5
    sta PF2 ; 4

.title_frame_bottom_index: ; 4 cycles

    dex ; 2
    bne .title_frame_bottom ; 2

.title_frame_bottom_index_next: ; 6 cycles

    ; Restore scanline counter
    ldx #KERNEL_IMAGE_LINE ; 2

    tya ; 2
    clc ; 2
    adc #KERNEL_IMAGE_FULL_DATA ; 2
    tay ; 2
    cpy #TITLE_FRAME_BOT_LINES*KERNEL_IMAGE_FULL_DATA
    bne .title_frame_bottom ; 2

.title_frame_bottom_clean:

    ; Clear out playfield
    lda #0
    sta PF0
    sta PF1
    sta PF2

.title_kernel_return:
    rts

TitleAudio0:

    .BYTE #15   ; B
    .BYTE #19   ; G
    .BYTE #23   ; E
    .BYTE #19   ; G
    .BYTE #14   ; C
    .BYTE #14
    .BYTE #-1
    .BYTE #-1
    .BYTE #12   ; D
    .BYTE #19
    .BYTE #23
    .BYTE #19
    .BYTE #14   ; C
    .BYTE #14
    .BYTE #-1
    .BYTE #-1

TitleTone1:

    .BYTE #15   ; Electronic Rumble
    .BYTE #-1
    .BYTE #1    ; Low Pure Tone
    .BYTE #1
    .BYTE #8    ; White Noise
    .BYTE #1
    .BYTE #1
    .BYTE #-1
    .BYTE #-1
    .BYTE #15
    .BYTE #-1
    .BYTE #-1
    .BYTE #8
    .BYTE #-1
    .BYTE #1
    .BYTE #1

TitleAudio1:

    .BYTE #29   ; Kick
    .BYTE #-1
    .BYTE #31   ; C
    .BYTE #31
    .BYTE #7    ; Snare
    .BYTE #31
    .BYTE #31
    .BYTE #-1
    .BYTE #-1
    .BYTE #29
    .BYTE #-1
    .BYTE #-1
    .BYTE #7
    .BYTE #-1
    .BYTE #23   ; F
    .BYTE #24   ; E
