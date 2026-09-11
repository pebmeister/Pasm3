    .org $C000

    .ifndef MAX
    .error "Enter -d MAX n for fib and Prime sequence"
    .endif
    
    .var t1 = 0, t2 = 1
    .var nextTerm = t1 + t2
    .var terms = 2
    
    .byte t1

    .while (terms < MAX) && (t2 < 255)
        .byte nextTerm

        .print push
        .print off
        terms = terms + 1
        t1 = t2
        t2 = nextTerm
        nextTerm = t1 + t2   
        .print pop
    .wend


    .var candidate = 2

    .while candidate <= MAX
        .print push
        .print off
        .var divisor = 2
        .var is_prime = 1
        .print pop

        ; Check divisibility up to sqrt(candidate)
        .while (divisor * divisor <= candidate) && (is_prime == 1)
            .while (candidate % divisor == 0) && (is_prime == 1)
                .print push
                .print off
                is_prime = 0
                .print pop
            .wend
            .print push
            .print off
            divisor = divisor + 1
            .print pop
        .wend

        ; Emit word if prime (single-shot conditional loop)
        .while is_prime == 1
            .word candidate
            .print push
            .print off
            is_prime = 0
            .print pop
        .wend

        .print push
        .print off
        candidate = candidate + 1
        .print pop
    .wend
    
    rts
    