    .org $C000

    .var xx = 2, yy = 16

    .byte xx
    .word yy

    xx = xx + 7
    yy = yy - 2

    .byte xx
    .word yy

    ldx RED
    bne @end
    @start   

    rts
    beq @start
  
    .while xx
        sta $C000 + xx, x
        nop
        xx = xx -1
    .wend

	nop
    
    @end

    rts