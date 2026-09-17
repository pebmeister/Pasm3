    .org $C000

    .ifndef MAX
    .error "Enter -d MAX n"
    .endif

    .print push
    .print off
   
    .print on
    .text "FIBINACHI SEQUENCE"
    .print off
    
    .var t1 = 0, t2 = 1, next = 0, terms = 1
    .while terms <= MAX
        .print on
        .word t2
        .print off
        next = t1 + t2
        t1 = t2
        t2 = next
        terms = terms + 1
    .wend
        
    .var aa = 1
    
    .print on
    .text "PYTHAGORIAN TRIPPLE"
    .print off
   
   
    .var m, n
    .var a, b, c
    terms = 0

    m = 2
    .while terms < MAX
        n = 1
        .while n < m && terms < MAX
            ; Generates valid triples directly without needing a GCD check
            a = (m * m) - (n * n);
            b = 2 * m * n;
            c = (m * m) + (n * n);

            ; Optional: Ensure 'a' is always the smaller leg for clean formatting
            .if a > b
                .var  temp = a;
                a = b;
                b = temp
            .endif
            .print on
            .word a,b,c
            .print off
            terms = terms + 1
            n = n + 1
        .wend
        m = m + 1
    .wend

    .print pop
   