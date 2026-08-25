@BEGIN
	nop
@here
	jsr @over_there
	bne @BEGIN
	beq @HERE
@over_there
	rts

