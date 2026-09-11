    .org $C000

    .ifndef MAX
    .error "Enter -d MAX n for fib sequence"
    .endif
    
    .var t1 = 0, t2 = 1
    .var nextTerm = t1 + t2
    .var terms = 2
    
    .byte t1

    .while (terms < MAX) && (t2 < 255)
        .byte nextTerm

        terms = terms + 1
        t1 = t2
        t2 = nextTerm
        nextTerm = t1 + t2        
    .wend

    rts
    