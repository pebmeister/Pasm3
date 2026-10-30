

; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================
        .basic_hdr
       
        jsr Test
 
@wait
        jmp @wait

Test:
        jsr CLEARSCREEN

        ; MATRIX = SCALING_MATRIX
        lda #<SCALING_MATRIX
        sta MAT4_MATRIX_PTR
        lda #>SCALING_MATRIX
        sta MAT4_MATRIX_PTR + 1

        ; VIN = TEST_VECTOR
        lda #<TEST_VECTOR
        sta MAT4_VIN_PTR
        lda #>TEST_VECTOR
        sta MAT4_VIN_PTR + 1

        ; VOUT = RESULT_VECTOR
        lda #<RESULT_VECTOR
        sta MAT4_VOUT_PTR
        lda #>RESULT_VECTOR
        sta MAT4_VOUT_PTR + 1

        
        jsr MAT4_VECTOR_MUL
        
        PRINT_VECTOR RESULT_VECTOR, 4
        rts
        
TEST_VECTOR:
        .word $0000,$0001      ; 1.0
        .word $0000,$0001      ; 1.0
        .word $0000,$0001      ; 1.0
        .word $0000,$0001      ; 1.0
        

RESULT_VECTOR:
        .ds 16
        