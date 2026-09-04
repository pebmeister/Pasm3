    .org $C000
    
    ldx RED
    bne @end
 @start   
 .ifdef RED
    nop
 .else
    inx
 .endif
  .ds 130
 @end
   rts
   beq @start
  
	* = *
	nop