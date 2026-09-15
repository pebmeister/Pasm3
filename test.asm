    .org $C000

    .ifndef MAX
    .error "Enter -d MAX n"
    .endif

    .print push
    .print off
    
    .var j = 0
    .var k = 0
    .repeat
        .print on
        .word j
        .print off
        j = j + 1
        k = 1
        .while (k < j)
            .print on            
            .word k
            .print off
            k = k + 1
        .wend
    .until j == MAX
    rts