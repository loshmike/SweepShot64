//===============================================================================
// Program Information
//===============================================================================

	// Program:      Sweep Shot 64
	// Program by:   Michael Losh
	// Date:         2023-01-09
	

	// New/unique code is copyright (c) Michael Losh, all rights reserved, at least for now. 
	// (Likely to put under an open source or public domain license in the future)
	//
	//	Gameplay, Rules, and Scoring 
	//
	//	(Disclaimer: Intended functionality... almost all implemented, but not guaranteed bug-free yet)
	//		
	//	Game Overall 
	//	 	• Basic idea is there is a vertical or horizontal beam that sweeps horizontally or vertically showing where a shot takes effect
	//       • If beam touches an enemy sprite when player presses fire, the Sweep shot will knock the enemy in the Sweepning direction
	//       • However, if the fire is held too long, the sweeping energy is lost and has no effect on enemy
	//       • After fire button release, the Sweep shooter needs a short time to recharge
	//	 	• Enemies appear at a middle distance between center and screen edges
	//	 	• Single-player game ends if four objects escape
	//	 	• Different enemy types have different motion patterns different score values
	//	 	• Enemies appear up to two at a time
	//	 	• There are 32 enemies per sector
	//	 	• If all enemies are cleared in a sector, brief flashing occurs and a life added (if under four)
	//		• Background color hue changes for each sector; after the fourth sector, the colors will repeat
	//		• Subsequent sectors two and three have faster beam sweep speed; later sectors have the same sweep speed as third
	//		• Strength of sweep push depends on how few frames the button is pushed before hitting enemy (as long as it is at least one)
	//	 	• Scoring per enemy starts at some point value (depending on enemy type) and decreases for each sweep push
	
	//	Collect Variant - single player
	//	 	• Enemies that move far enough toward edge of screen disappear
	//	 	• Enemies that are swept into the home base disappear and score points
	//		• Game Ends after N enemies escape?
	//
	//   Clear Variant - single player  (save for "delux" version?)
	//	 	• Enemies that are pushed far enough toward edge of screen disappear
	//		• Each hit scores, but points depend on distance from base (farther is higher score, basically)
	//	 	• Enemies that reach the home base disappear cause loss of a sweeper

	//   MultiPlayer  (save for "delux" version?)
	//	 	• There is a different color base near the center of the screen for each player (1, 2, 3?, or 4) but separated at least a little
	//	 	• Enemies that move far enough toward edge of screen disappear
	//	 	• Enemies that are swept into the home base of the player's color disappear and score for that player
	//		• Game Ends after a player reaches a "win" score?  
     
//===============================================================================
// Change Log
//===============================================================================
 
	// 2022.12.24 - First code for Atari 2600 created
	// 2023.01.09 - Port to Commodore 64 started
	
//===============================================================================
// Initialize KickAssembler
//===============================================================================
.file [name="ss64.prg"]

//===============================================================================
// Conditional Build options
//===============================================================================
.var SUPEREASY=0		// use super-easy settings for quicker testing

//===============================================================================
// Constants - Constant values defined here, except where bitfields make it better
//             to define next to their RAM variables, or aliases of RAM vars
//===============================================================================

.const SWEEP_FIRE_CNT_LIM 	= 24	// 24/60 second
.const COOLDOWN_INIT_COUNT = 12		// 12/60 second  about .2 sec

.const PLAYFIELD_LINES 	= 200		
.const PLAYFIELD_COLS	= 320 		
.const INCINERATOR_Y    = 99

.if (SUPEREASY == 1) 	.const OBJECTS_PER_SECTOR = 4
else					.const OBJECTS_PER_SECTOR = 32

.const NEW_OBJ_PAUSE = 96

.const BEAM_NORM_CLR		= $1c	// yellow
.const BEAM_SWEEPING_CLR 	= $3a	// reddish-orange
.const BEAM_COOLING_CLR   	= $02 	// dark gray 

.const TITLE_MIN_Y = 82				// Bob the y position of the title between these two coordinates
.const TITLE_MAX_Y = 90


// object types
.const VOID_OBJ = -1
.const DUSTBUN_OBJ	= 0		// does not move unless pushed
.const CREEPER_OBJ = 1		// steady movement straight away, not very fast
.const SLIDER_OBJ = 2		// moves straight vertical or horizontal based on longer initial distance after placement or hit
.const ZIPSTER_OBJ = 3		// Picks rand direction and goes that way for awhile; then picks another
.const ZAGSTER_OBJ = 4  	// moves for a short random burst, generally in a zig-zag pattern, short pauses between movements
.const BURN_OBJ = 5		// an incinerating object sequence (5 to 12)

// EventTypes
.const OBJ_PUSH_EVENT = 1	// when successfully hit
.const OBJ_MISS_EVENT = 2	// when touched by depleted beam
.const OBJ_BURN_EVENT = 3	// during incineration
.const OBJ_NEW_EVENT  = 4	// when new object appears
.const OBJ_WARN_EVENT = 5	// when obj is ready to escape
.const CLEARED_EVENT  = 6	// when a sector is cleared
.const GAMEOVER_EVENT = 7	// when all lives gone
.const THEMEMUSIC_EVENT = 8	// music for title page

.const ISR_PTR		= $0314
.const CHARMEM 		= $0400

.const SPR_PTR0      = $07F8
.const SPR_PTR1      = $07F9
.const SPR_PTR2      = $07FA
.const SPR_PTR3      = $07FB
.const SPR_PTR4      = $07FC
.const SPR_PTR5      = $07FD
.const SPR_PTR6      = $07FE
.const SPR_PTR7      = $07FF

.const SPR_GFX 		= $3200		// real address of sprite graphics 
.const SPR_BUF0		= ((SPR_GFX / 64) + 0)	// bit-shifted version to go into sprite pointers
.const SPR_BUF1		= ((SPR_GFX / 64) + 1)
.const SPR_BUF2		= ((SPR_GFX / 64) + 2)
.const SPR_BUF3		= ((SPR_GFX / 64) + 3)
.const SPR_BUF4		= ((SPR_GFX / 64) + 4)
.const SPR_BUF5		= ((SPR_GFX / 64) + 5)
.const SPR_BUF6		= ((SPR_GFX / 64) + 6)
.const SPR_BUF7		= ((SPR_GFX / 64) + 7)

.const SPR_X0		= $D000		// sprite screen position coordinates
.const SPR_Y0		= $D001
.const SPR_X1		= $D002
.const SPR_Y1		= $D003
.const SPR_X2		= $D004
.const SPR_Y2		= $D005
.const SPR_X3		= $D006
.const SPR_Y3		= $D007
.const SPR_X4		= $D008
.const SPR_Y4		= $D009
.const SPR_X5		= $D00A
.const SPR_Y5		= $D00B
.const SPR_X6		= $D00C
.const SPR_Y6		= $D00D
.const SPR_X7		= $D00E
.const SPR_Y7		= $D00F
.const SPR_XHI		= $D010		// 8th bit of X coordinate of each sprite, for when X > 255

.const SCRNCTRL		= $D011
.const VRASTERSCROLL = 7		// bits 0 to 2
.const RASTER_HI    = $80		// bit 8 of current raster line

.const RASTER       = $D012		// bits 0 to 7 of current raster line


.const SPR_ENAB		= $D015		// sprite enable
.const SCRNCTRL2	= $D016
.const SPR_DBLHI	= $D017		// sprite double-height flags
.const MEMSETUP		= $D018		// location of screen data, etc.

.const INTR_STAT	= $D019		// interrupt status register
.const RASTER_I		= 1
.const CX_SPR_BKG_I	= 2
.const CX_SPR_SPR_I	= 4
.const LIGHT_PEN_I	= 8

.const INTR_CTRL	= $D01A		// interrupt control register
.const SPR_PRI		= $D01B		// sprite priority flags, 1 = behind screen content
.const SPR_MLTCLR	= $D01C		// sprite multicolor flags, 1 = use multiple colors
.const SPR_DBLWIDE	= $D01D		// sprite double-width flags, 1 = double-width sprites

.const COLUBD 		= $D020 
.const COLUBK 		= $D021 

.const SPR_EXCLR1	= $D025		// sprite extra color 1
.const SPR_EXCLR2	= $D026		// sprite extra color 2

.const SPR_CLR0		= $D027		// sprite 0 color
.const SPR_CLR1		= $D028
.const SPR_CLR2		= $D029
.const SPR_CLR3		= $D02A
.const SPR_CLR4		= $D02B
.const SPR_CLR5		= $D02C

.const PORTA  		= $DC00		// CIA#1 (Port Register A)
.const DDRA 		= $DC02		// CIA#1 (Data Direction Register A)
.const PORTB  		= $DC01		// CIA#1 (Port Register B)
.const DDRB 		= $DC03		// CIA#1 (Data Direction Register B)
.const CIA1CTRL		= $DC0D
.const CIA2CTRL		= $DD0D

.const DEFAULT_ISR	= $EA31

.const CLR_BLACK	= $0
.const CLR_WHITE	= $1
.const CLR_RED	  	= $2
.const CLR_CYAN		= $3
.const CLR_MAGENTA	= $4
.const CLR_GREEN	= $5
.const CLR_BLUE		= $6
.const CLR_YELLOW	= $7
.const CLR_ORANGE	= $8
.const CLR_BROWN	= $9
.const CLR_PINK		= $A
.const CLR_DRKGRAY	= $B
.const CLR_GRAY		= $C
.const CLR_LTGREEN	= $D
.const CLR_LTBLUE	= $E
.const CLR_LTGRAY	= $F

//===============================================================================
// Variables - Constant values defined here, except where bitfields make it better
//             to define next to their RAM variables, or aliases of RAM vars
//===============================================================================
* = $4000 "Variables"

Variables:
Frame:		.byte 0
Mode:		.byte 0
TitleY: 	.byte TITLE_MIN_Y
TitleInc:	.byte 1
Pressing:	.byte 0				// non-zero if return (and space and Joystick fire?) is being pressed

	
//===============================================================================
// Program Code  - The main code and subroutines follow here
//===============================================================================
* = 16666 "Code"

//===============================================================================
// Entry Point - You can use "G 4000" in the monitor or "SYS 16384" in BASIC
//===============================================================================
CodeStart:
// clear char disp 
	ldx #0
	lda #$20
clrLoop: 
	sta CHARMEM + 0*$100,x
	sta CHARMEM + 1*$100,x
	sta CHARMEM + 2*$100,x
	sta CHARMEM + 3*$100,x
	inx
	bne clrLoop

// screen colors
colors:
	lda #CLR_BLACK
	sta COLUBD
	sta COLUBK

// sprite bits	
	ldx #0
spritesLoadLoop0:
	lda Title0Gfx,x
	sta SPR_GFX+0,x
	inx
	cpx #63
	bcc spritesLoadLoop0

	ldx #0
spritesLoadLoop1:
	lda Title1Gfx,x
	sta SPR_GFX+64,x
	inx
	cpx #63
	bcc spritesLoadLoop1

	ldx #0
spritesLoadLoop2:
	lda Title2Gfx,x
	sta SPR_GFX+128,x
	inx
	cpx #63
	bcc spritesLoadLoop2

	ldx #0
spritesLoadLoop3:
	lda Title3Gfx,x
	sta SPR_GFX+192,x
	inx
	cpx #63
	bcc spritesLoadLoop3

	ldx #0
spritesLoadLoop4:
	lda CredGfx,x
	sta SPR_GFX+256,x
	inx
	cpx #63
	bcc spritesLoadLoop4

	ldx #0
spritesLoadLoop5:
	lda CopyrightGfx,x
	sta SPR_GFX+320,x
	inx
	cpx #63
	bcc spritesLoadLoop5
	
// sprite pointers
	lda #SPR_BUF0	
	sta SPR_PTR0
	lda #SPR_BUF1	
	sta SPR_PTR1
	lda #SPR_BUF2	
	sta SPR_PTR2
	lda #SPR_BUF3	
	sta SPR_PTR3
	lda #SPR_BUF4	
	sta SPR_PTR4
	lda #SPR_BUF5	
	sta SPR_PTR5

// sprite position
	lda #160
	sta SPR_X0
	sta SPR_X1
	sta SPR_X2
	sta SPR_X3
	sta SPR_X4
	sta SPR_X5
	
	lda #82
	sta SPR_Y0
	sta SPR_Y1
	sta SPR_Y2
	sta SPR_Y3
	lda #140
	sta SPR_Y4
	lda #198
	sta SPR_Y5
	
// sprite color
	lda #CLR_YELLOW
	sta SPR_CLR0
	lda #CLR_ORANGE
	sta SPR_CLR1
	lda #CLR_PINK
	sta SPR_CLR2
	lda #CLR_MAGENTA
	sta SPR_CLR3
	lda #CLR_GREEN
	sta SPR_CLR4
	lda #CLR_ORANGE
	sta SPR_CLR5

	lda #0
	sta SPR_MLTCLR

// sprite size
	lda #$ff			// all sprites expanded
	sta SPR_DBLHI
	sta SPR_DBLWIDE	

// sprite enable
	lda #$3F
	sta SPR_ENAB	
	
	
GameSetup:
	lda #0
	sta Frame


	lda #RASTER_I
	sta INTR_CTRL
	
InitRasterInt:
	sei					// set interrupt bit, make the CPU ignore interrupt requests
	lda #%01111111		// switch off interrupt signals from CIA-1
	sta CIA1CTRL

	and SCRNCTRL		// clear most significant bit of VIC's raster register
	sta SCRNCTRL

	lda CIA1CTRL		// acknowledge pending interrupts from CIA-1
	lda CIA2CTRL		// acknowledge pending interrupts from CIA-2

	lda #252			// just past the visible visible raster lines
	sta RASTER

	lda #<FrameIrq      // set interrupt vectors, pointing to interrupt service routine below
	sta ISR_PTR
	lda #>FrameIrq
	sta ISR_PTR+1

	lda #%00000001		// enable raster interrupt signals from VIC
	sta INTR_STAT 

	cli					// clear interrupt flag, allowing the CPU to respond to interrupt requests

Wait:
	nop
	jsr GetInput
	
	jmp Wait
	
; FrameWait:
	; lda RASTER
	; and #RASTER_I
	; beq FrameWait

FrameIrq:
	inc Frame
	lda Mode
	bmi GameMode
TitleMode:
	jsr TitleFrame
	jmp FrameIrqDone
GameMode:
	jsr GameFrame
FrameIrqDone:
	asl INTR_STAT		// acknowledge the interrupt by clearing the VIC's interrupt flag
	jmp DEFAULT_ISR		// jump into KERNAL's standard interrupt service routine to handle keyboard scan, cursor display etc.	

//----------------------------------------------------------------------
TitleFrame:
	lda Frame
	and #3				// update rate defined by this bit mask
	bne moveDone
moving:
	lda TitleY
	cmp #(TITLE_MIN_Y+1)
	bcs checkMax
	lda #1			// make move downward on screen
	sta TitleInc
	bne doMove
checkMax:
	cmp #TITLE_MAX_Y
	bcc doMove
	lda #-1			// make move upward on screen
	sta TitleInc
doMove:
	lda TitleY
	clc
	adc TitleInc	// inc/dec position
	sta TitleY
	sta SPR_Y0		// update title sprite Y pos
	sta SPR_Y1		// update title sprite Y pos
	sta SPR_Y2		// update title sprite Y pos
	sta SPR_Y3		// update title sprite Y pos
moveDone:
	rts
	
//----------------------------------------------------------------------
GameFrame:
	//Testing ...
	// disable sprite
	lda #0
	sta SPR_ENAB
	rts

//----------------------------------------------------------------------
GetInput:
	sei             // interrupts deactivated
	lda #%11111111  // CIA#1 port A = outputs 
	sta DDRA             
	lda #%00000000  // CIA#1 port B = inputs
	sta DDRB             
//	sta Pressing	// assume user is not pressing

checkSpace:
	lda #%01111111  // testing column 7 of the matrix
	sta PORTA 
	lda PORTB
	and #%00010000  // masking row 4 for SPACE key 
//	beq Press
	
//chkReturn:
//	lda #%11111110  // testing column 0 (COL0) of the matrix
//	sta PORTA 
//	lda PORTB
//	and #%00000010  // masking row 1 (ROW1) for RETURN key 
	bne InputDone

Press:
	lda #1
	sta Pressing
	lda #$80
	sta Mode

InputDone:
	cli             // interrupts activated
	rts             // back to background loop
	
//===============================================================================
// Fixed Game Data - Sprite data, data tables, etc. go here
//===============================================================================

.align $100

Title0Gfx:
	.byte %00000000, %00000000, %00000000//, $74
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $58
	.byte %01110010, %10101010, %10101001//, $4a
	.byte %00000000, %00000000, %00000000//, $3d
	.byte %00000000, %00000000, %00000000//, $4a
	.byte %00000000, %00000000, %00000000//, $58
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $74
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $58
	.byte %00000000, %00000000, %00000000//, $4a
	.byte %00111001, %00101000, %10001000//, $3d
	.byte %00000000, %00000000, %00000000//, $4a
	.byte %00000000, %00000000, %00000000//, $58
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	
Title1Gfx:
	.byte %00000000, %00000000, %00000000//, $74
	.byte %00000000, %00000000, %00000000//, $66
	.byte %10000010, %00100100, %01001110//, $58
	.byte %01110010, %10101010, %10101001//, $4a
	.byte %00001010, %10101110, %11101001//, $3d
	.byte %00000000, %00000000, %00000000//, $4a
	.byte %00000000, %00000000, %00000000//, $58
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $74
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $58
	.byte %01000001, %11000111, %00111110//, $4a
	.byte %00111001, %00101000, %10001000//, $3d
	.byte %00000101, %00101000, %10001000//, $4a
	.byte %00000000, %00000000, %00000000//, $58
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	
Title2Gfx:
	.byte %00000000, %00000000, %00000000//, $74
	.byte %10000000, %00000000, %00000000//, $66
	.byte %10000010, %00100100, %01001110//, $58
	.byte %01110010, %10101010, %10101001//, $4a
	.byte %00001010, %10101110, %11101001//, $3d
	.byte %00001001, %01001000, %10001001//, $4a
	.byte %00000000, %00000000, %00000000//, $58
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $74
	.byte %00000000, %00000000, %00000000//, $66
	.byte %01000001, %00000000, %00001000//, $58
	.byte %01000001, %11000111, %00111110//, $4a
	.byte %00111001, %00101000, %10001000//, $3d
	.byte %00000101, %00101000, %10001000//, $4a
	.byte %00000101, %00101000, %10001000//, $58
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	
Title3Gfx:
	.byte %01111000, %00000000, %00000000//, $74
	.byte %10000000, %00000000, %00000000//, $66
	.byte %10000010, %00100100, %01001110//, $58
	.byte %01110010, %10101010, %10101001//, $4a
	.byte %00001010, %10101110, %11101001//, $3d
	.byte %00001001, %01001000, %10001001//, $4a
	.byte %11110001, %01000100, %01001110//, $58
	.byte %00000000, %00000000, %00001000//, $66
	.byte %00000000, %00000000, %00001000//, $74
	.byte %00111101, %00000000, %00000000//, $66
	.byte %01000001, %00000000, %00001000//, $58
	.byte %01000001, %11000111, %00111110//, $4a
	.byte %00111001, %00101000, %10001000//, $3d
	.byte %00000101, %00101000, %10001000//, $4a
	.byte %00000101, %00101000, %10001000//, $58
	.byte %01111001, %00100111, %00001000//, $66
	.byte %00000000, %00000000, %00000000//, $66
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4

	
CredGfx:
	.byte %00000000, %10000000, %00000000//, $b4
	.byte %00000000, %11100100, %10000000//, $b4
	.byte %00000000, %10010100, %10000000//, $b4
	.byte %00000000, %11100011, %00000000//, $b4
	.byte %00000000, %00001110, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %01000001, %00100100, %00000000//, $bc
	.byte %01100011, %00000100, %10011000//, $ba
	.byte %01010101, %00100101, %00100100//, $b8
	.byte %01001001, %00100110, %00111100//, $b6
	.byte %01000001, %00100101, %00100000//, $b4
	.byte %01000001, %00100100, %10011000//, $b2
	.byte %00000000, %00000000, %00000000//, $b2
	.byte %01000000, %00000000, %00010000//, $bc
	.byte %01000000, %11000011, %00011100//, $ba
	.byte %01000001, %00100100, %00010010//, $b8
	.byte %01000001, %00100011, %00010010//, $b6
	.byte %01000001, %00100000, %10010010//, $b4
	.byte %01111100, %11000011, %00010010//, $b2
	.byte %00000000, %00000000, %00000000//, $b2
	.byte %00000000, %00000000, %00000000//, $b4

CopyrightGfx:
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b2
	.byte %01000100, %01100010, %01100110//, $2c
	.byte %10011010, %00010101, %00010001//, $2a
	.byte %10100010, %00100101, %00100010//, $28
	.byte %10011010, %01000101, %01000001//, $26
	.byte %01000100, %01110010, %01110110//, $24
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b2
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b2
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b2
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b4
	.byte %00000000, %00000000, %00000000//, $b2
