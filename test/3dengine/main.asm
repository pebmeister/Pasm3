

; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================
        .basic_hdr
       
        lda #$00
        sta ROW
        
        jsr Test_Fix16_Mul_Zero
 
@wait
        jmp @wait

; ============================================
; Test_Combined_Rotation
; Multiplies Rz * Ry * Rx for 45-degree angles (32)
; and displays the resulting master matrix cleanly
; ============================================
Test_Combined_Rotation:
        jsr CLEARSCREEN

        ; 1. Build Rx (Angle = 32 / 45 degrees)
        lda #32
        sta ROT_X_ANGLE
        jsr ROTATION_X
        MAT4_COPY MAT_B, MAT_A        ; MAT_A = Rx

        ; 2. Build Ry (Angle = 32 / 45 degrees)
        lda #32
        sta ROT_Y_ANGLE
        jsr ROTATION_Y                ; MAT_B = Ry

        PUSHREGS
        ; 3. Multiply Ry * Rx -> store in intermediate buffer
        CALL_MAT4_MUL MAT_B, MAT_A, MAT_C 
        POPREGS
        
        MAT4_COPY MAT_C, MAT_ROT_XY   ; MAT_ROT_XY = Ry * Rx

        ; 4. Build Rz (Angle = 32 / 45 degrees)
        lda #32
        sta ROT_Z_ANGLE
        jsr ROTATION_Z                ; MAT_B = Rz
        MAT4_COPY MAT_B, MAT_A        ; MAT_A = Rz

        ; 5. Load (Ry * Rx) back into MAT_B
        MAT4_COPY MAT_ROT_XY, MAT_B   ; MAT_B = Ry * Rx

        ; 6. Perform final master multiplication: MAT_C = Rz * (Ry * Rx)
        CALL_MAT4_MUL MAT_A, MAT_B, MAT_C

        ; 7. Point FIXPTR explicitly to MAT_C and display the final matrix
        lda #<MAT_C
        ldy #>MAT_C
        sta FIXPTR
        sty FIXPTR+1

        jsr DisplayResults
        rts
        
 ; ============================================
; Test_Fix16_Mul_Zero
; Multiplies 1.0 * 0.0 directly using FIX16_MUL
; ============================================
Test_Fix16_Mul_Zero:
        jsr CLEARSCREEN

        CALL_MAT4_MUL MatrixA, MatrixB, MAT_C 
        PRINT_MAT MAT_C, 3

        rts
; Matrix A
;  1.5   2.25  0.5   1.0
;  0.5   1.0   1.5   2.0
;  2.0   0.5   1.0   1.5
;  1.0   1.5   2.0   0.5

MatrixA:
    .word $8000, $0001   ; 1.5
    .word $4000, $0002   ; 2.25
    .word $8000, $0000   ; 0.5
    .word $0000, $0001   ; 1.0

    .word $8000, $0000   ; 0.5
    .word $0000, $0001   ; 1.0
    .word $8000, $0001   ; 1.5
    .word $0000, $0002   ; 2.0

    .word $0000, $0002   ; 2.0
    .word $8000, $0000   ; 0.5
    .word $0000, $0001   ; 1.0
    .word $8000, $0001   ; 1.5

    .word $0000, $0001   ; 1.0
    .word $8000, $0001   ; 1.5
    .word $0000, $0002   ; 2.0
    .word $8000, $0000   ; 0.5
    
; Matrix B
;  0.5   1.0   1.5   2.0
;  1.0   0.5   2.0   1.5
;  1.5   2.0   0.5   1.0
;  2.0   1.5   1.0   0.5

MatrixB:
    .word $8000, $0000   ; 0.5
    .word $0000, $0001   ; 1.0
    .word $8000, $0001   ; 1.5
    .word $0000, $0002   ; 2.0

    .word $0000, $0001   ; 1.0
    .word $8000, $0000   ; 0.5
    .word $0000, $0002   ; 2.0
    .word $8000, $0001   ; 1.5

    .word $8000, $0001   ; 1.5
    .word $0000, $0002   ; 2.0
    .word $8000, $0000   ; 0.5
    .word $0000, $0001   ; 1.0

    .word $0000, $0002   ; 2.0
    .word $8000, $0001   ; 1.5
    .word $0000, $0001   ; 1.0
    .word $8000, $0000   ; 0.5
    