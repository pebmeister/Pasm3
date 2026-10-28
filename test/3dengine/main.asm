
;********************************************
;* GET_SINE                                 *
;* Lookup 16.16 Sine value from table       *
;* \1 Angle (8-bit index 0-255)             *
;* \2 Destination (32-bit variable)         *
;* Destroys A, Y, FIXPTR, TEMP16            *
;********************************************
        .macro GET_SINE
        lda \1
        jsr LookupSineTable
        ldy #0
        lda (FIXPTR),y
        sta \2
        iny
        lda (FIXPTR),y
        sta \2+1
        iny
        lda (FIXPTR),y
        sta \2+2
        iny
        lda (FIXPTR),y
        sta \2+3
        .endm


;********************************************
;* GET_COSINE                               *
;* Lookup 16.16 Cosine value from table     *
;* (\+64 phase shift for 90° cosine offset) *
;* \1 Angle (8-bit index 0-255)             *
;* \2 Destination (32-bit variable)         *
;* Destroys A, Y, FIXPTR, TEMP16            *
;********************************************
        .macro GET_COSINE
        lda \1
        clc
        adc #64
        jsr LookupSineTable
        ldy #0
        lda (FIXPTR),y
        sta \2
        iny
        lda (FIXPTR),y
        sta \2+1
        iny
        lda (FIXPTR),y
        sta \2+2
        iny
        lda (FIXPTR),y
        sta \2+3
        .endm

;********************************************
;* CALL_MAT4_MUL
;*
;* /1 = Matrix A
;* /2 = Matrix B
;* /3 = Matrix C
;*
;* Sets pointers and calls MAT4_MUL.
;********************************************

        .macro CALL_MAT4_MUL

        lda #<\1
        sta MAT4_A_PTR
        lda #>\1
        sta MAT4_A_PTR+1

        lda #<\2
        sta MAT4_B_PTR
        lda #>\2
        sta MAT4_B_PTR+1

        lda #<\3
        sta MAT4_C_PTR
        lda #>\3
        sta MAT4_C_PTR+1

        jsr MAT4_MUL

        .endm
 
 ; CALL_FIX16_MUL operand_A, operand_B, destination

        .macro CALL_FIX16_MUL

        lda #<\1
        sta FIX16_A_PTR
        lda #>\1
        sta FIX16_A_PTR+1

        lda #<\2
        sta FIX16_B_PTR
        lda #>\2
        sta FIX16_B_PTR+1

        lda #<\3
        sta FIX16_RESULT_PTR
        lda #>\3
        sta FIX16_RESULT_PTR+1

        jsr FIX16_MUL

        .endm
        
       
;********************************************
;* CALL_MAT4_VECTOR_MUL
;*
;* /1 = Matrix address
;* /2 = Input vector address
;* /3 = Output vector address
;********************************************

        .macro CALL_MAT4_VECTOR_MUL

        lda #<\1
        sta MAT4_MATRIX_PTR
        lda #>\1
        sta MAT4_MATRIX_PTR+1

        lda #<\2
        sta MAT4_VIN_PTR
        lda #>\2
        sta MAT4_VIN_PTR+1

        lda #<\3
        sta MAT4_VOUT_PTR
        lda #>\3
        sta MAT4_VOUT_PTR+1

        jsr MAT4_VECTOR_MUL

        .endm
        
        
; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================
        .basic_hdr
       
        jsr CLEARSCREEN
        
        lda #0
        sta ROW
        
        jsr new_test
 
@wait
        jmp @wait

        
new_test
        ;lda #32 
        ;sta ROT_X_ANGLE
        ;jsr ROTATION_X
        ;lda #32 
        ;sta ROT_Y_ANGLE
        ;jsr ROTATION_Y
        ;lda #32 
        ;sta ROT_Z_ANGLE
        ;jsr ROTATION_Z

        jsr Test_Combined_Rotation

        rts


Test_Vector_Multiply:

        lda #32
        sta ROT_Z_ANGLE
        jsr ROTATION_Z

        ; Copy rotation matrix from MAT_B to MAT_A.
        ldx #0
@CopyRotation:
        lda MAT_B,x
        sta MAT_A,x
        inx
        cpx #64
        bne @CopyRotation

        CALL_MAT4_VECTOR_MUL MAT_A, VEC_IN, VEC_OUT

        ; Display VEC_OUT using your existing
        ; vector-printing routine.

        PRINT_VECTOR VEC_OUT
        rts
        
 
Test_Vector_Rotations:

        ; ====================================
        ; Test 1: Rotate around X by 45 degrees
        ; ====================================
        lda #32
        sta ROT_X_ANGLE
        jsr ROTATION_X

        jsr Copy_MAT_B_To_MAT_A

        CALL_MAT4_VECTOR_MUL MAT_A, VEC_IN, VEC_OUT

        ; Display X-axis result
        ; Expected: 1, 0, 0, 1
        PRINT_VECTOR VEC_OUT


        ; ====================================
        ; Test 2: Rotate around Y by 45 degrees
        ; ====================================
        lda #32
        sta ROT_Y_ANGLE
        jsr ROTATION_Y

        jsr Copy_MAT_B_To_MAT_A

        MAT4_VECTOR_MUL MAT_A, VEC_IN, VEC_OUT

        ; Display Y-axis result
        ; Expected: 0.70710, 0, -0.70710, 1
        PRINT_VECTOR VEC_OUT


        ; ====================================
        ; Test 3: Rotate around Z by 45 degrees
        ; ====================================
        lda #32
        sta ROT_Z_ANGLE
        jsr ROTATION_Z

        jsr Copy_MAT_B_To_MAT_A

        MAT4_VECTOR_MUL MAT_A, VEC_IN, VEC_OUT

        ; Display Z-axis result
        ; Expected: 0.70710, 0.70710, 0, 1
        PRINT_VECTOR VEC_OUT

        rts


; ============================================
; Copy 64-byte MAT_B to MAT_A
; ============================================
Copy_MAT_B_To_MAT_A:
        ldx #0
@CopyLoop:
        lda MAT_B,x
        sta MAT_A,x
        inx
        cpx #64
        bne @CopyLoop
        rts




; ============================================
; Test_Combined_Rotation:
; ============================================
Test_Combined_Rotation___

        ; Build X rotation
        lda #32
        sta ROT_X_ANGLE
        jsr ROTATION_X

        ; Save Rx
        MAT4_COPY MAT_B, MAT_A

        ; Build Y rotation
        lda #32
        sta ROT_Y_ANGLE
        jsr ROTATION_Y

        ; Calculate Ry * Rx
        CALL_MAT4_MUL MAT_B, MAT_A, MAT_C

        ; Save intermediate result
        MAT4_COPY MAT_C, MAT_ROT_XY

        ; Build Z rotation
        lda #32
        sta ROT_Z_ANGLE
        jsr ROTATION_Z

        ; Save Rz
        MAT4_COPY MAT_B, MAT_A

        ; Restore Ry * Rx
        MAT4_COPY MAT_ROT_XY, MAT_B

        ; Calculate Rz * (Ry * Rx)
        CALL_MAT4_MUL MAT_A, MAT_B, MAT_C

        ; Display final matrix
        PRINT_MAT MAT_C, 4

        rts
        
      ;********************************************
;* Test_Combined_Rotation
;* Diagnose final multiplication inputs
;********************************************

Test_Combined_Rotation:

        ; Build X rotation
        lda #32
        sta ROT_X_ANGLE
        jsr ROTATION_X

        ; Save Rx
        MAT4_COPY MAT_B, MAT_A

        ; Build Y rotation
        lda #32
        sta ROT_Y_ANGLE
        jsr ROTATION_Y

        ; Calculate Ry * Rx
        MAT4_MUL MAT_B, MAT_A, MAT_C

        ; Save intermediate matrix
        MAT4_COPY MAT_C, MAT_ROT_XY

        ; Build Z rotation
        lda #32
        sta ROT_Z_ANGLE
        jsr ROTATION_Z

        ; Save Rz
        MAT4_COPY MAT_B, MAT_A

        ; Restore intermediate matrix
        MAT4_COPY MAT_ROT_XY, MAT_B

        ; Calculate Rz * (Ry * Rx)
        MAT4_MUL MAT_A, MAT_B, MAT_C

        ; Print only the final matrix
        PRINT_MAT MAT_C, 4

        rts