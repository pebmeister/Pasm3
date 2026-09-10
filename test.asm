    .org $C000

   .var x, y = 6
   ; .while 1 ; x < y
   ;     sta $C000, x
   ;     nop
       ; x = x + 2
   ; .wend
	
	.ifndef RED
		.error "RED should be defined on the command line"
	.endif
	
    ldx RED
    bne @end
    @start
    ; .ds 130

    rts
    beq @start
  
	* = *
	nop
	@end
