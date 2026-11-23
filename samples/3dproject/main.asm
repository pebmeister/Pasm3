GETIN   = $F13E
CHRIN   = $F157
CHROUT  = $FFD2

BORDER  = $D020
SCREENC = $D021

PLOT    = $E50A
STROUT  = $AB1E



        .basic_hdr
        
        lda     #$36
        sta     $01                 ; Configure C64 memory banking:
        
        jsr     CLEARSCREEN
        
        jsr     RunMat4MulTest
        lda     BORDER
        cmp     #5
        bne     @Done
        
        jsr     RunDivTest
        lda     BORDER
        cmp     #5
        bne     @Done
        
        jsr     RunVec3Mat4Test
        lda     BORDER
        cmp     #5
        bne     @Done

        jsr     RunRotXTest
        lda     BORDER
        cmp     #5
        bne     @Done

        jsr     RunRotYTest
        lda     BORDER
        cmp     #5
        bne     @Done
        
        jsr     RunRotZTest
        lda     BORDER
        cmp     #5
        bne     @Done

; next test goes here
        jsr     RunRotXyzTest
        lda     BORDER
        cmp     #5
        bne     @Done
        
@Done
        jmp     @Done
