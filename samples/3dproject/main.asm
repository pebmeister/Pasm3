GETIN   = $F13E
CHRIN   = $F157
CHROUT  = $FFD2

BORDER  = $D020
SCREENC = $D021

PLOT    = $E50A




        .basic_hdr
        
        lda     #$36
        sta     $01                 ; Configure C64 memory banking:

        jsr     RunMat4MulTest
        lda     BORDER
        cmp     #5
        bne     @Done
        
        jsr     RunDivTest
        lda     BORDER
        cmp     #5
        bne     @Done
        
        jsr     RunVec3Mat4Test

@Done
        jmp     @Done
