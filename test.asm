    .org $C000

    .var xx = 2, yy = 16

    .byte xx
    .word yy

    xx = xx + 1
    yy = yy - 2

    .byte xx
    .word yy

    ldx RED
    bne @end
    @start   

    rts
    beq @start
  
    .while 1
        sta $C000 + xx, x
        nop
    .wend

	nop
    
    @end

    rts