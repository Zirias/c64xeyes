.segment "LDADDR"
                .word   $c000

SPRITE		= $2c0
SPRITEPTR	= SPRITE >> 6

POT_X		= $d419
POT_Y		= $d41a
OPOT_X		= $fb
OPOT_Y		= $fc
OLDVAL		= $fd
NEWVAL		= $fe
TMP1		= $02

.code
		jsr	$e544
		ldx	#$3f
		lda	#0
		sta	$d010
		sta	$d01b
spclear:	sta	SPRITE,x
		dex
		bpl	spclear
		ldy	#spritelines-1
		ldx	#(spritelines-1) * 3
spcpy:		lda	spriteblocks,y
		sta	SPRITE,x
		dex
		dex
		dex
		dey
		bpl	spcpy
		lda	#SPRITEPTR
		sta	$7f8
		lda	#$18
		sta	$d000
		lda	#$32
		sta	$d001
		lda	#$d
		sta	$d027
		lda	#$1
		sta	$d015
		sei
		lda	#<isr
		sta	$314
		lda	#>isr
		sta	$315
		cli
		bne	*

checkmove:
		sty	OLDVAL
		sta	NEWVAL
		tay
		sec
		sbc	OLDVAL
		and	#$7f
		cmp	#$40
		bcs	negativemove
		lsr	a
		beq	nomove
		rts
negativemove:	ora	#$c0
		cmp	#$ff
		beq	nomove
		sec
		ror	a
		rts
nomove:		lda	#$0
		rts

redraw:
		jsr	$e544
		lda	mouse_x
		sec
		sbc	#$5
		bcs	draw_xleftok
		lda	#$0
draw_xleftok:	cmp	#$1e
		bcc	draw_xrightok
		lda	#$1d
draw_xrightok:	sta	redraw_x
		clc
		adc	#$2
		sta	eye1_x
		adc	#$6
		sta	eye2_x
		lda	mouse_y
		sec
		sbc	#$2
		bcs	draw_yupok
		lda	#$0
draw_yupok:	cmp	#$15
		bcc	draw_ydownok
		lda	#$14
draw_ydownok:	sta	redraw_y
		clc
		adc	#$2
		sta	eyes_y
		lda	#<frame1
		sta	framesrc
		lda	#>frame1
		sta	framesrc+1
		lda	#$4
		sta	tmp2
framelinel:	ldx	redraw_y
		jsr	$e9f0
		lda	#$2
		sta	TMP1
		ldy	redraw_x
frameloopo:	ldx	#$0
framesrc	= *+1
frameloopi:	lda	$ffff,x
		sta	($d1),y
		iny
		inx
		cpx	#$5
		bne	frameloopi
		iny
		dec	TMP1
		bne	frameloopo
		inc	redraw_y
		lda	#<frame2
		sta	framesrc
		lda	#>frame2
		sta	framesrc+1
		dec	tmp2
		bmi	rdrwdone
		bne	framelinel
		lda	#<frame3
		sta	framesrc
		lda	#>frame3
		sta	framesrc+1
		bne	framelinel
rdrwdone:	rts

isr:
		lda	POT_X
		ldy	OPOT_X
		jsr	checkmove
		sty	OPOT_X
		sta	TMP1
		clc
		adc	$d000
		sta	$d000
		ror	a
		eor	TMP1
		bpl	skiphbtoggle
		lda	#$01
		eor	$d010
		sta	$d010
skiphbtoggle:	lda	$d010
		lsr	a
		lda	$d000
		bcs	checkright
		cmp	#$18
		bcs	doy
setleft:	lda	#$18
		bne	xsecondstore
checkright:	cmp	#$58
		bcc	doy
		bit	TMP1
		bpl	setright
		dec	$d010
		bcs	setleft
setright:	lda	#$57
xsecondstore:	sta	$d000
doy:		lda	POT_Y
		ldy	OPOT_Y
		jsr	checkmove
		sty	OPOT_Y
		eor	#$ff
		sta	TMP1
		sec
		adc	$d001
		sta	$d001
		ror	a
		eor	TMP1
		bpl	noywrap
		bit	TMP1
		bpl	setupper
		bmi	setlower
noywrap:	lda	$d001
		cmp	#$32
		bcs	upperok
setlower:	lda	#$32
		bne	ysecondstore
upperok:	cmp	#$fa
		bcc	mousedone
setupper:	lda	#$f9
ysecondstore:	sta	$d001
mousedone:	lda	mouse_x
		sta	mouse_ox
		lda	mouse_y
		sta	mouse_oy
		lda	$d010
		lsr	a
		lda	$d000
		ror	a
		sec
		sbc	#$0c
		lsr	a
		lsr	a
		sta	mouse_x
		lda	$d001
		sec
		sbc	#$32
		lsr	a
		lsr	a
		lsr	a
		sta	mouse_y
checkclick:	lda	$dc01
		and	#$10
		cmp	button
		beq	checkeyes
		sta	button
		and	#$10
		bne	checkeyes
		jsr	redraw
		bmi	doeyes
checkeyes:	lda	mouse_x
		cmp	mouse_ox
		bne	doeyes
		lda	mouse_y
		cmp	mouse_oy
		beq	isrout
doeyes:		ldx	eyes_y
		dex
		stx	TMP1
		lda	#$3
		sta	tmp2
eyeclrloop:	ldx	TMP1
		jsr	$e9f0
		lda	#$20
		ldx	#$3
		ldy	eye1_x
		dey
eyeclrrow1:	sta	($d1),y
		iny
		dex
		bne	eyeclrrow1
		ldx	#$3
		ldy	eye2_x
		dey
eyeclrrow2:	sta	($d1),y
		iny
		dex
		bne	eyeclrrow2
		inc	TMP1
		dec	tmp2
		bne	eyeclrloop

isrout:		jmp	$ea31

.data

spriteblocks:
		.byte	$80, $c0, $e0, $f0
		.byte	$f8, $fc, $f0, $d8
		.byte	$18, $0c, $0c
spritelines	= *-spriteblocks
frame1:		.byte	".---."
frame2:		.byte	$5d, "   ", $5d
frame3:		.byte	"'---'"

.bss

mouse_x:	.res	1
mouse_y:	.res	1
mouse_ox:	.res	1
mouse_oy:	.res	1
button:		.res	1
eye1_x:		.res	1
eye2_x:		.res	1
eyes_y:		.res	1
redraw_x:	.res	1
redraw_y:	.res	1
tmp2:		.res	1
