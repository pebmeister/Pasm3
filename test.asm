SCREEN = $0400
	.org $1000+75*6
START:
	lda #1	; THATS A BIG 1
	sta SCREEN
	bne target
	rts
	jmp START
target
	.byte $20,$22
	.word $1234, $5678
  
