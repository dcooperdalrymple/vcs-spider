    ; 8 Legs of Love game for Atari VCS/2600
    ; Created by D Cooper Dalrymple 2018 - dcdalrymple.com
    ; Licensed under GNU LGPL V3.0
    ; Last revision: August 28th, 2018

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

; Logo
LOGO_SIZE           = 9
LOGO_START          = 48
LOGO_INTERVAL       = 8
LOGO_FRAMES         = 180

LOGO_BG_COLU        = #$A2
LOGO_FG_COLU        = #$5E

LOGO_AUD_0_TONE     = 4
LOGO_AUD_0_VOLUME   = 15 ; 15 is max
LOGO_AUD_1_TONE     = 1
LOGO_AUD_1_VOLUME   = 3
LOGO_AUD_LENGTH     = 12
LOGO_AUD_STEP       = 8

; Title
TITLE_LINE_SIZE     = 8
TITLE_DATA_SIZE     = %00000100
TITLE_BORDER        = 1
TITLE_PAD           = 4
TITLE_IMAGE         = 6
TITLE_GAP           = 2

TITLE_BG_COLU       = #$70
TITLE_BD_COLU       = #$7E
TITLE_FG_COLU       = #$0E

TITLE_AUD_0_TONE    = 4
TITLE_AUD_0_VOLUME  = 4
TITLE_AUD_1_VOLUME  = 7
TITLE_AUD_LENGTH    = 16
TITLE_AUD_STEP      = 9

; Game
GAME_PF_LINE_SIZE   = 8
GAME_PF_DATA_SIZE   = %00000100
GAME_PF_SIZE        = 12

GAME_BG_COLU        = #$00
GAME_FG_COLU        = #$0C

GAME_P0_COLU        = #$56
GAME_P0_SIZE        = 8

;================
; Variables
;================

    SEG.U vars
    org $80

Overlay             ds 8

    org Overlay

; Animation/Logic System

AnimationFrame      ds 1 ; 1 byte to count frames
AnimationSubFrame   ds 1 ; 1 byte to count portions of frames

; Audio System

AudioFrame          ds 1
AudioStep           ds 1

    SEG

    ORG $F000           ; Start of cart area

Reset:

.initstack

    ldx #0
    txa

.initstack_loop:

    dex
    txs
    pha
    bne .initstack_loop

    ; Stack pointer now $FF, a=x=0, TIA registers (0 - $7F) = RAM ($80 - $FF) = 0

.initvars

    ; Set background color
    lda #$00 ; Black
    sta COLUBK

    ; Set the playfield and player color
    lda #$0E ; White
    sta COLUPF
    sta COLUP0
    sta COLUP1

    ; Playfield Control
    lda #%00000000 ; 1 for mirroring
    sta CTRLPF

    ; Disable Game Elements
    lda #$00
    sta ENABL           ; Turn off ball
    sta ENAM0           ; Turn off player 1 missile
    sta ENAM1           ; Turn off player 2 missile
    sta GRP0            ; Turn off player 1
    sta GRP1            ; Turn off player 2

    ; Empty playfield
    lda #%00000000
    sta PF0
    sta PF1
    sta PF2

LogoScreen:

    ; Load Colors
    lda #LOGO_BG_COLU
    sta COLUBK
    lda #LOGO_FG_COLU
    sta COLUPF

    ; Load audio settings
    lda #LOGO_AUD_0_TONE
    sta AUDC0
    lda #LOGO_AUD_0_VOLUME
    sta AUDV0
    lda #LOGO_AUD_1_TONE
    sta AUDC1
    lda #LOGO_AUD_1_VOLUME
    sta AUDV1
    lda #0
    sta AudioFrame
    sta AudioStep

    ; Play first note
    tay
    lda LogoAudio0,y
    sta AUDF0
    lda LogoAudio1,y
    sta AUDF1

    ; Load number of frames into AnimationFrame
    lda #LOGO_FRAMES
    sta AnimationFrame

    ; Initialize sub frame
    lda #0
    sta AnimationSubFrame

LogoFrame:

.logo_audio:

    ; Increment Audio Frame
    ldx AudioFrame
    inx
    stx AudioFrame

    ; Check if we need to play the next note
    cpx #LOGO_AUD_STEP
    bcc .logo_audio_skip

.logo_audio_play:

    ; Reset AudioFrame
    lda #0
    sta AudioFrame

    ; Check if we're at the end of the melody
    ldy AudioStep
    cpy #LOGO_AUD_LENGTH-1
    beq .logo_audio_mute

.logo_audio_play_note:

    ; Increment Audio position
    iny
    sty AudioStep

    ; Load note and play
    lda LogoAudio0,y
    sta AUDF0
    lda LogoAudio1,y
    sta AUDF1
    jmp .logo_audio_mute_skip

.logo_audio_mute:

    ; Mute audio
    lda #0
    sta AUDC0
    sta AUDV0
    sta AUDF0
    sta AUDC1
    sta AUDV1
    sta AUDF1

.logo_audio_mute_skip:

.logo_audio_skip:

.logo_vsync:                 ; Start of vertical blank processing

    lda #0
    sta VBLANK

    lda #2
    sta VSYNC

    ; VSYNCH signal scanlines
    REPEAT #KERNEL_VSYNC
        sta WSYNC
    REPEND

    lda #0
    sta VSYNC

.logo_vblank:                ; scanlines of vertical blank

    ldx #KERNEL_VBLANK
.logo_vblank_loop:

    sta WSYNC
    dex
    bne .logo_vblank_loop

.logo_scanline:              ; Do 192 scanlines

    lda #$00            ; Clear playfields
    sta PF0
    sta PF1
    sta PF2

    ldx #LOGO_START     ; This counts our scanline number
.logo_scanline_start:

    sta WSYNC
    dex
    bne .logo_scanline_start

    ldx #0
.logo_scanline_loop:

    ; Cleanup
    sta PF1

    txa
    lsr                 ; Divide counter by 4
    lsr
    and #%11111110      ; Remove 0th bit
    tay

    ; Check if we need to display line
    cpy AnimationSubFrame
    bcs .logo_scanline_skip

    ; Load first half of data
    lda LogoData,y
    sta PF2

    ; Load second half of data
    iny
    lda LogoData,y

    ; Use 4 MSB bits on PF0
    sta PF0

    ; Use 4 LSB bits on PF1
    REPEAT 4
        asl
    REPEND
    sta PF1

    ; Cleanup
    lda #$00
    sta PF2
    sta PF0

.logo_scanline_skip:

    ; Clear Playfields
    lda #$00
    sta PF0
    sta PF1
    sta PF2

    ; Wait for next line
    sta WSYNC

    ; Check if at end of logo display
    inx
    cpx #LOGO_SIZE*LOGO_INTERVAL
    bne .logo_scanline_loop

    ldx #KERNEL_SCANLINES-LOGO_START-LOGO_SIZE*LOGO_INTERVAL
.logo_scanline_end:

    sta WSYNC
    dex
    bne .logo_scanline_end

.logo_overscan:              ; 30 scanlines of overscan

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

    ldx #KERNEL_OVERSCAN
.logo_overscan_loop:

    sta WSYNC
    dex
    bne .logo_overscan_loop

    ldx AnimationFrame

    ; Divide inverted AnimationFrame by 4 and put in AnimationSubFrame
    lda #LOGO_FRAMES
    sbc AnimationFrame
    lsr
    lsr
    sta AnimationSubFrame

    ; Decrement AnimationFrame
    dex
    stx AnimationFrame

    ; Check if we're at the end of the animation
    beq TitleScreen
    jmp LogoFrame

TitleScreen:

    ; Clear playfields
    lda #$00
    sta PF0
    sta PF1
    sta PF2

    ; Background Color
    lda #TITLE_BG_COLU
    sta COLUBK

    ; Border Color
    lda #TITLE_BD_COLU
    sta COLUPF

    ; Load audio settings

    ; Melody Line
    lda #TITLE_AUD_0_TONE
    sta AUDC0
    lda #TITLE_AUD_0_VOLUME
    sta AUDV0

    ; Drums and Bass
    lda #0
    sta AUDC1
    sta AUDV1

    ; Make it so that we play the first note immediately
    lda #TITLE_AUD_STEP-1
    sta AudioFrame
    lda #TITLE_AUD_LENGTH-1
    sta AudioStep

TitleFrame:

.title_audio:

    ; Increment Audio Frame
    ldx AudioFrame
    inx
    stx AudioFrame

    ; Check if we need to play the next note
    cpx #TITLE_AUD_STEP
    bcc .title_audio_skip

.title_audio_play:

    ; Reset AudioFrame
    lda #0
    sta AudioFrame

    ; Increment melody position
    ldy AudioStep
    iny

    ; Check if we're at the end of the melody
    cpy #TITLE_AUD_LENGTH
    bne .title_audio_play_note

    ; Loop our audio step
    ldy #0

.title_audio_play_note:

    ; Save current position
    sty AudioStep

    ; Basic Melody Line
    lda TitleAudio0,y
    sta AUDF0

    ; Drums and Bass
    lda TitleTone1,y
    cmp #$FF
    beq .title_audio_play_note_1_mute

    sta AUDC1
    lda TitleAudio1,y
    sta AUDF1
    lda #TITLE_AUD_1_VOLUME
    sta AUDV1

    jmp .title_audio_skip

.title_audio_play_note_1_mute:

    lda #0
    sta AUDF1
    sta AUDC1
    sta AUDV1

.title_audio_skip:

.title_vsync:                 ; Start of vertical blank processing

    lda #0
    sta VBLANK

    lda #2
    sta VSYNC

    ; VSYNCH signal scanlines
    REPEAT #KERNEL_VSYNC
        sta WSYNC
    REPEND

    lda #0
    sta VSYNC

.title_vblank:                  ; scanlines of vertical blank

    ldx #KERNEL_VBLANK
.title_vblank_loop:

    sta WSYNC
    dex
    bne .title_vblank_loop

.title_border_h_top:

    ; Number of Scanlines
    ldx #TITLE_BORDER*TITLE_LINE_SIZE

    ; Draw Playfield
    lda #$FF
    sta PF0
    sta PF1
    sta PF2

.title_border_h_top_loop:

    sta WSYNC
    dex
    bne .title_border_h_top_loop

.title_border_v_top:

    ; Number of Scanlines
    ldx #TITLE_PAD*TITLE_LINE_SIZE

    ; Mirror playfield
    lda #%00000001
    sta CTRLPF

    ; Draw Playfield
    lda #%00010000
    sta PF0

    lda #$00
    sta PF1
    sta PF2

.title_border_v_top_loop:

    sta WSYNC
    dex
    bne .title_border_v_top_loop

.title_image_top:

    ldy #$00    ; Current Image Index
    ldx #TITLE_LINE_SIZE                ; Current scanline

    jmp .title_image_top_loop

.title_image_top_loop_wait:

    ; Wait until new line is ready to draw
    sta WSYNC
    sleep 11

.title_image_top_loop:

    ; Draw Image
    lda TitleImageTop,y
    sta PF1
    iny

    ; Set Image Color
    lda #TITLE_FG_COLU
    sta COLUPF

    ; Finish Drawing Image
    lda TitleImageTop,y
    sta PF2
    iny
    lda TitleImageTop,y
    iny
    sleep 5
    sta PF2
    lda TitleImageTop,y
    sta PF1

    ; Clear bottom of index
    tya
    and #%11111100
    tay

    ; Restore border color
    sleep 2
    lda #TITLE_BD_COLU
    sta COLUPF

    dex
    bne .title_image_top_loop_wait

    ; Add 4 to the image index to skip to next line
    REPEAT 4
        iny
    REPEND

    ldx #TITLE_LINE_SIZE                ; Current scanline

    cpy #TITLE_IMAGE*TITLE_DATA_SIZE
    bne .title_image_top_loop

.title_gap:

    ; Number of Scanlines
    ldx #TITLE_GAP*TITLE_LINE_SIZE

    ; Mirror playfield
    lda #%00000001
    sta CTRLPF

    ; Draw Playfield
    lda #%00010000
    sta PF0

    lda #$00
    sta PF1
    sta PF2

.title_gap_loop:

    sta WSYNC
    dex
    bne .title_gap_loop

.title_image_bottom:

    ldy #$00                ; Current Image Index
    ldx #TITLE_LINE_SIZE

    jmp .title_image_bottom_loop

.title_image_bottom_loop_wait:

    ; Wait until new line is ready to draw
    sta WSYNC
    sleep 11

.title_image_bottom_loop:

    ; Draw Image
    lda TitleImageBottom,y
    sta PF1
    iny

    ; Set Image Color
    lda #TITLE_FG_COLU
    sta COLUPF

    ; Finish Drawing Image
    lda TitleImageBottom,y
    sta PF2
    iny
    lda TitleImageBottom,y
    iny
    sleep 5
    sta PF2
    lda TitleImageBottom,y
    sta PF1

    ; Clear bottom of index
    tya
    and #%11111100
    tay

    ; Restore border color
    sleep 2
    lda #TITLE_BD_COLU
    sta COLUPF

    dex
    bne .title_image_bottom_loop_wait

    ; Add 4 to image index to skip to next line
    REPEAT 4
        iny
    REPEND

    ldx #TITLE_LINE_SIZE                ; Current scanline

    cpy #TITLE_IMAGE*TITLE_DATA_SIZE
    bne .title_image_bottom_loop

.title_border_v_bottom:

    ; Number of Scanlines
    ldx #TITLE_PAD*TITLE_LINE_SIZE

    ; Mirror playfield
    lda #%00000001
    sta CTRLPF

    ; Draw Playfield
    lda #%00010000
    sta PF0

    lda #$00
    sta PF1
    sta PF2

.title_border_v_bottom_loop:

    sta WSYNC
    dex
    bne .title_border_v_bottom_loop

.title_border_h_bottom:

    ; Number of Scanlines
    ldx #TITLE_BORDER*TITLE_LINE_SIZE

    ; Draw Playfield
    lda #$FF
    sta PF0
    sta PF1
    sta PF2

.title_border_h_bottom_loop:

    sta WSYNC
    dex
    bne .title_border_h_bottom_loop

.title_overscan:              ; 30 scanlines of overscan

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

    ldx #KERNEL_OVERSCAN
.title_overscan_loop:

    sta WSYNC
    dex
    bne .title_overscan_loop

    ; Check if Fire Button on controller 1 is pressed
    lda INPT4
    bpl GameScreen
    jmp TitleFrame

GameScreen:

    ; Clear playfields
    lda #0
    sta PF0
    sta PF1
    sta PF2

    ; Mirror playfield
    lda #%00000001
    sta CTRLPF

    ; Background Color
    lda #GAME_BG_COLU
    sta COLUBK

    ; Foreground Color
    lda #GAME_FG_COLU
    sta COLUPF

    ; Player Color
    lda #GAME_P0_COLU
    sta COLUP0

    ; Mute Audio
    lda #0
    sta AUDC0
    sta AUDV0
    sta AUDF0
    sta AUDC1
    sta AUDV1
    sta AUDF1

GameFrame:

.game_vsync:                 ; Start of vertical blank processing

    lda #0
    sta VBLANK

    lda #2
    sta VSYNC

    ; VSYNCH signal scanlines
    REPEAT #KERNEL_VSYNC
        sta WSYNC
    REPEND

    lda #0
    sta VSYNC

.game_vblank:                ; scanlines of vertical blank

    ldx #KERNEL_VBLANK
.game_vblank_loop:

    sta WSYNC
    dex
    bne .game_vblank_loop

.game_playfield_top:

    ldy #0                  ; Current Image Index

.game_playfield_top_line:

    ; Draw Image
    lda GameImage,y
    sta PF0
    iny
    lda GameImage,y
    sta PF1
    iny
    lda GameImage,y
    sta PF2

    ; Clear bottom of index
    tya
    and #%11111100
    tay

    ; Add 4 to the image index to skip to next line
    REPEAT 4
        iny
    REPEND

    ldx #GAME_PF_LINE_SIZE  ; Current scanline
.game_playfield_top_loop:

    sta WSYNC
    dex
    bne .game_playfield_top_loop

    ; Reset scanlines
    ldx #GAME_PF_LINE_SIZE

    ; Check if we're at end of top half
    cpy #GAME_PF_SIZE*GAME_PF_DATA_SIZE
    bne .game_playfield_top_line

.game_player:

    ldy #0
    ldx #GAME_P0_SIZE
.game_player_loop:

    lda PlayerSprite,y
    sta GRP0
    iny

    lda #1
    sleep 20
    sta RESP0
    sleep 20

    sta WSYNC
    dex
    bne .game_player_loop

    ; Reset Player
    lda #0
    sta GRP0


.game_playfield_bottom:

    ldy #(GAME_PF_SIZE-2)*GAME_PF_DATA_SIZE    ; Current image index

.game_playfield_bottom_line:

    ; Draw Image
    lda GameImage,y
    sta PF0
    iny
    lda GameImage,y
    sta PF1
    iny
    lda GameImage,y
    sta PF2

    ; Clear bottom of index
    tya
    and #%11111100
    tay

    ; Subtract 4 from the image index to skip to next line
    REPEAT 4
        dey
    REPEND

    ldx #GAME_PF_LINE_SIZE                  ; Current scanline
.game_playfield_bottom_loop:

    sta WSYNC
    dex
    bne .game_playfield_bottom_loop

    ; Check if we're at the end of the bottom half
    cpy #0-GAME_PF_DATA_SIZE
    bne .game_playfield_bottom_line

    ; Clear Playfields
    lda #0
    sta PF0
    sta PF1
    sta PF2

.game_overscan:              ; 30 scanlines of overscan

    lda #%01000010
    sta VBLANK          ; end of screen - enter blanking

    ldx #KERNEL_OVERSCAN
.game_overscan_loop:

    sta WSYNC
    dex
    bne .game_overscan_loop

    jmp GameFrame

LogoData:               ; 6 bytes over 8 lines each, total of 48 lines

    .BYTE %01000110     ; Reversed
    .BYTE %01100000     ; First 4 bits reversed

    .BYTE %10101010
    .BYTE %10100000

    .BYTE %00101010
    .BYTE %10100000

    .BYTE %10101010
    .BYTE %10100000

    .BYTE %01000110
    .BYTE %01100000

    .BYTE %00000000
    .BYTE %00000000

    .BYTE %10001000
    .BYTE %10000000

    .BYTE %01010100
    .BYTE %01010000

    .BYTE %00100010
    .BYTE %00100000

LogoAudio0:

    .BYTE #29   ; C
    .BYTE #23   ; E
    .BYTE #19   ; G
    .BYTE #15   ; A
    .BYTE #23   ; E
    .BYTE #19   ; G
    .BYTE #15   ; B
    .BYTE #14   ; C
    .BYTE #11   ; E
    .BYTE #11
    .BYTE #11
    .BYTE #11

LogoAudio1:

    .BYTE #31   ; C
    .BYTE #31
    .BYTE #31
    .BYTE #31
    .BYTE #25   ; E
    .BYTE #25
    .BYTE #25
    .BYTE #25
    .BYTE #20   ; G
    .BYTE #20
    .BYTE #20
    .BYTE #20

TitleImageTop:          ; Spider

    .BYTE %00011110     ; Normal
    .BYTE %01110111     ; Reversed
    .BYTE %11100111     ; Normal
    .BYTE %00001110     ; Reversed

    .BYTE %00010000
    .BYTE %00100101
    .BYTE %10010100
    .BYTE %00010010

    .BYTE %00010000
    .BYTE %00100111
    .BYTE %10010110
    .BYTE %00010010

    .BYTE %00011100
    .BYTE %00100001
    .BYTE %10010100
    .BYTE %00001110

    .BYTE %00000100
    .BYTE %00100001
    .BYTE %10010100
    .BYTE %00010010

    .BYTE %00011100
    .BYTE %01110001
    .BYTE %11100111
    .BYTE %00010010

TitleImageBottom:       ; Web & Art

    .BYTE %00000001     ; Normal
    .BYTE %00000011     ; Reversed
    .BYTE %10001011     ; Normal
    .BYTE %00011101     ; Reversed

    .BYTE %00001010
    .BYTE %00010100
    .BYTE %10001010
    .BYTE %00100100

    .BYTE %00010101
    .BYTE %00101010
    .BYTE %10001011
    .BYTE %00011100

    .BYTE %00100100
    .BYTE %01001001
    .BYTE %10001010
    .BYTE %00100100

    .BYTE %00100010
    .BYTE %01000100
    .BYTE %10101010
    .BYTE %00100100

    .BYTE %00010001
    .BYTE %00100011
    .BYTE %01010011
    .BYTE %00011101

TitleAudio0:

    .BYTE #15   ; B
    .BYTE #19   ; G
    .BYTE #23   ; E
    .BYTE #19   ; G
    .BYTE #14   ; C
    .BYTE #19
    .BYTE #23
    .BYTE #19
    .BYTE #12   ; D
    .BYTE #19
    .BYTE #23
    .BYTE #19
    .BYTE #14   ; C
    .BYTE #19
    .BYTE #23
    .BYTE #19

TitleTone1:

    .BYTE #15   ; Electronic Rumble
    .BYTE #$FF
    .BYTE #1    ; Low Pure Tone
    .BYTE #1
    .BYTE #8    ; White Noise
    .BYTE #1
    .BYTE #1
    .BYTE #$FF
    .BYTE #$FF
    .BYTE #15
    .BYTE #$FF
    .BYTE #$FF
    .BYTE #8
    .BYTE #$FF
    .BYTE #1
    .BYTE #1

TitleAudio1:

    .BYTE #29   ; Kick
    .BYTE #$FF
    .BYTE #31   ; C
    .BYTE #31
    .BYTE #7    ; Snare
    .BYTE #31
    .BYTE #31
    .BYTE #$FF
    .BYTE #$FF
    .BYTE #29
    .BYTE #$FF
    .BYTE #$FF
    .BYTE #7
    .BYTE #$FF
    .BYTE #23   ; F
    .BYTE #24   ; E

GameImage:      ; Just one quadrant of web

    .BYTE %00000000     ; First 4 bits reversed
    .BYTE %00000000     ; Normal
    .BYTE %00000011     ; Reversed
    .BYTE %00000000     ; Empty

    .BYTE %00000000
    .BYTE %00000000
    .BYTE %00111111
    .BYTE %00000000

    .BYTE %00000000
    .BYTE %00000001
    .BYTE %11000010
    .BYTE %00000000

    .BYTE %00000000
    .BYTE %00000001
    .BYTE %00000100
    .BYTE %00000000

    .BYTE %00000000
    .BYTE %00000010
    .BYTE %00001000
    .BYTE %00000000

    .BYTE %00000000
    .BYTE %00001100
    .BYTE %00001000
    .BYTE %00000000

    .BYTE %00110000
    .BYTE %00110000
    .BYTE %00010000
    .BYTE %00000000

    .BYTE %11100000
    .BYTE %11000000
    .BYTE %00100000
    .BYTE %00000000

    .BYTE %00100000
    .BYTE %00111000
    .BYTE %00100000
    .BYTE %00000000

    .BYTE %01000000
    .BYTE %00000111
    .BYTE %01000001
    .BYTE %00000000

    .BYTE %01000000
    .BYTE %00000000
    .BYTE %10001110
    .BYTE %00000000

    .BYTE %10000000
    .BYTE %00000000
    .BYTE %11110000
    .BYTE %00000000

PlayerSprite:

    ; Up
    .BYTE %10011001
    .BYTE %10111101
    .BYTE %10011001
    .BYTE %01111110
    .BYTE %00111100
    .BYTE %01111110
    .BYTE %10111101
    .BYTE %10011001

    ; Right
    .BYTE %11000111
    .BYTE %00101000
    .BYTE %01111010
    .BYTE %11111111
    .BYTE %11111111
    .BYTE %01111010
    .BYTE %00101000
    .BYTE %11000111

    ; Down
    .BYTE %10011001
    .BYTE %10111101
    .BYTE %01111110
    .BYTE %00111100
    .BYTE %01111110
    .BYTE %10011001
    .BYTE %10111101
    .BYTE %10011001

    ; Left
    .BYTE %11100011
    .BYTE %00010100
    .BYTE %01011110
    .BYTE %11111111
    .BYTE %11111111
    .BYTE %01011110
    .BYTE %00010100
    .BYTE %11100011

    ;-------------------------------------------

    ORG $FFFA           ; End of cart area

InterruptVectors:

    .word Reset         ; NMI
    .word Reset         ; RESET
    .word Reset         ; IRQ

    END
