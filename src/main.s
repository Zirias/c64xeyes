.segment "LDADDR"
                .word   $c000

SPRITE		= $2c0
SPRITEPTR	= SPRITE >> 6

POT_X		= $d419
POT_Y		= $d41a

OP_DECZP	= $c6
OP_INCZP	= $e6

opot_x		= $fb
opot_y		= $fc
oldval		= $fd
newval		= $fe
redraw_x	= $fd
redraw_y	= $fe
mouse_x		= $69
mouse_y		= $6a
mouse_ox	= $6b
mouse_oy	= $6c
button		= $6d
eye1_x		= $5c
eye2_x		= $5d
eyes_y		= $5e
tmp1		= $5f
tmp2		= $02

.code
		jsr	$e544
		lda	#$ff
		sta	eyes_y
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
		sty	oldval
		sta	newval
		tay
		sec
		sbc	oldval
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
		sta	tmp1
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
		dec	tmp1
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

draweye:
		cmp	mouse_x
		bcc	righthalf
		beq	xcenter
		sbc	mouse_x
		sta	tmp1
		lda	#OP_DECZP
		bne	lefthalf
righthalf:	eor	#$ff
		sec
		adc	mouse_x
		sta	tmp1
		lda	#OP_INCZP
lefthalf:	sta	ddownleft
		sta	dleft
		sta	dupleft
		lda	mouse_y
		cmp	eyes_y
		bcc	cupleft
		beq	dleft
		sbc	eyes_y
		cmp	tmp1
		bcc	cdownleftl
		lsr	a
		cmp	tmp1
		bcs	ddown
ddownleft:	dec	redraw_x
ddown:		ldx	eyes_y
		inx
		bne	dodraw
dleft:		dec	redraw_x
dcenter:	ldx	eyes_y
		bne	dodraw
cdownleftl:	asl	a
		cmp	tmp1
		bcs	ddownleft
		bcc	dleft
cupleft:	eor	#$ff
		sec
		adc	eyes_y
		cmp	tmp1
		bcc	cupleftl
		lsr	a
		cmp	tmp1
		bcs	dup
dupleft:	dec	redraw_x
dup:		ldx	eyes_y
		dex
		bne	dodraw
cupleftl:	asl	a
		cmp	tmp1
		bcs	dupleft
		bcc	dleft
xcenter:	lda	mouse_y
		cmp	eyes_y
		bcc	dup
		beq	dcenter
		bcs	ddown
dodraw:		jsr	$e9f0
		lda	#$30
		ldy	redraw_x
		sta	($d1),y
		rts	

isr:
		lda	POT_X
		ldy	opot_x
		jsr	checkmove
		sty	opot_x
		sta	tmp1
		clc
		adc	$d000
		sta	$d000
		ror	a
		eor	tmp1
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
		bit	tmp1
		bpl	setright
		dec	$d010
		bcs	setleft
setright:	lda	#$57
xsecondstore:	sta	$d000
doy:		lda	POT_Y
		ldy	opot_y
		jsr	checkmove
		sty	opot_y
		eor	#$ff
		sta	tmp1
		sec
		adc	$d001
		sta	$d001
		ror	a
		eor	tmp1
		bpl	noywrap
		bit	tmp1
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
checkeyes:	lda	eyes_y
		bmi	isrout
		lda	mouse_x
		cmp	mouse_ox
		bne	doeyes
		lda	mouse_y
		cmp	mouse_oy
		beq	isrout
doeyes:		ldx	eyes_y
		dex
		stx	tmp1
		lda	#$3
		sta	tmp2
eyeclrloop:	ldx	tmp1
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
		inc	tmp1
		dec	tmp2
		bne	eyeclrloop
		lda	eye1_x
		sta	redraw_x
		jsr	draweye
		lda	eye2_x
		sta	redraw_x
		jsr	draweye
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

