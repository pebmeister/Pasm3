;********************************************
;* ROTATION_Z
;*
;* Build a 4x4 Z rotation matrix.
;* ROT_Z_ANGLE = 64 means 90 degrees.
;********************************************
ROTATION_Z:
        ; Look up sine and cosine
        GET_SINE   ROT_Z_ANGLE, ROT_SINE
        GET_COSINE ROT_Z_ANGLE, ROT_COSINE

        ; Calculate -sin using 32-bit two's complement
        lda #0
        sec
        sbc ROT_SINE
        sta ROT_NEG_SINE

        lda #0
        sbc ROT_SINE+1
        sta ROT_NEG_SINE+1

        lda #0
        sbc ROT_SINE+2
        sta ROT_NEG_SINE+2

        lda #0
        sbc ROT_SINE+3
        sta ROT_NEG_SINE+3

        ; Clear entire 64-byte MAT_B buffer to 0
        ldx #0
@ClearMat:
        lda #0
        sta MAT_B,x
        sta MAT_B+16,x
        sta MAT_B+32,x
        sta MAT_B+48,x
        inx
        cpx #16
        bne @ClearMat

        ; MAT_B row 0: [cos, -sin, 0, 0]
        ldx #0
@CopyCos0:
        lda ROT_COSINE,x
        sta MAT_B,x
        inx
        cpx #4
        bne @CopyCos0

        ldx #0
@CopyNegSin:
        lda ROT_NEG_SINE,x
        sta MAT_B+4,x
        inx
        cpx #4
        bne @CopyNegSin

        ; MAT_B row 1: [sin, cos, 0, 0]
        ldx #0
@CopySin:
        lda ROT_SINE,x
        sta MAT_B+16,x
        inx
        cpx #4
        bne @CopySin

        ldx #0
@CopyCos1:
        lda ROT_COSINE,x
        sta MAT_B+20,x
        inx
        cpx #4
        bne @CopyCos1

        ; MAT_B row 2: [0, 0, 1.0, 0] -> 1.0 at offset 40 (Row 2, Col 2)
        ldx #0
@CopyOne2:
        lda MAT_I+40,x
        sta MAT_B+40,x
        inx
        cpx #4
        bne @CopyOne2

        ; MAT_B row 3: [0, 0, 0, 1.0] -> 1.0 at offset 60 (Row 3, Col 3)
        ldx #0
@CopyOne3:
        lda MAT_I+60,x
        sta MAT_B+60,x
        inx
        cpx #4
        bne @CopyOne3

        rts
        
 ;********************************************
;* ROTATION_Y
;*
;* Build a 4x4 Y rotation matrix in MAT_B.
;* ROT_Y_ANGLE = 32 means 45 degrees.
;********************************************
ROTATION_Y:
        GET_SINE   ROT_Y_ANGLE, ROT_SINE
        GET_COSINE ROT_Y_ANGLE, ROT_COSINE

        ; Calculate -sin (32-bit two's complement)
        lda #0
        sec
        sbc ROT_SINE
        sta ROT_NEG_SINE
        lda #0
        sbc ROT_SINE+1
        sta ROT_NEG_SINE+1
        lda #0
        sbc ROT_SINE+2
        sta ROT_NEG_SINE+2
        lda #0
        sbc ROT_SINE+3
        sta ROT_NEG_SINE+3

        ; Clear all 64 bytes
        ldx #0
@YClear:
        lda #0
        sta MAT_B,x
        inx
        cpx #64
        bne @YClear

        ; Row 0, column 0: cos
        ldx #0
@YCos0:
        lda ROT_COSINE,x
        sta MAT_B,x
        inx
        cpx #4
        bne @YCos0

        ; Row 0, column 2: sin
        ldx #0
@YSin0:
        lda ROT_SINE,x
        sta MAT_B+8,x
        inx
        cpx #4
        bne @YSin0

        ; Row 1, column 1: 1.0
        lda #1
        sta MAT_B+22

        ; Row 2, column 0: -sin
        ldx #0
@YNegSin:
        lda ROT_NEG_SINE,x
        sta MAT_B+32,x
        inx
        cpx #4
        bne @YNegSin

        ; Row 2, column 2: cos
        ldx #0
@YCos2:
        lda ROT_COSINE,x
        sta MAT_B+40,x
        inx
        cpx #4
        bne @YCos2

        ; Row 3, column 3: 1.0
        lda #1
        sta MAT_B+62

        rts
        
;********************************************
;* ROTATION_X
;*
;* Build a 4x4 X rotation matrix in MAT_B.
;* ROT_X_ANGLE = 32 means 45 degrees.
;********************************************
ROTATION_X:
        GET_SINE   ROT_X_ANGLE, ROT_SINE
        GET_COSINE ROT_X_ANGLE, ROT_COSINE

        ; Calculate -sin (32-bit two's complement)
        lda #0
        sec
        sbc ROT_SINE
        sta ROT_NEG_SINE
        lda #0
        sbc ROT_SINE+1
        sta ROT_NEG_SINE+1
        lda #0
        sbc ROT_SINE+2
        sta ROT_NEG_SINE+2
        lda #0
        sbc ROT_SINE+3
        sta ROT_NEG_SINE+3

        ; Row 0: 1, 0, 0, 0
        lda #0
        sta MAT_B
        sta MAT_B+1
        lda #1
        sta MAT_B+2
        lda #0
        sta MAT_B+3

        lda #0
        sta MAT_B+4
        sta MAT_B+5
        sta MAT_B+6
        sta MAT_B+7
        
        ; Correct 1.0 at MAT_B[0,0]
        lda #0
        sta MAT_B
        sta MAT_B+1
        lda #1
        sta MAT_B+2
        lda #0
        sta MAT_B+3

        ; Row 1: 0, cos, -sin, 0
        ldx #0
@XCos:
        lda ROT_COSINE,x
        sta MAT_B+20,x
        lda ROT_NEG_SINE,x
        sta MAT_B+24,x
        inx
        cpx #4
        bne @XCos

        ; Row 2: 0, sin, cos, 0
        ldx #0
@XSinCos:
        lda ROT_SINE,x
        sta MAT_B+36,x
        lda ROT_COSINE,x
        sta MAT_B+40,x
        inx
        cpx #4
        bne @XSinCos

        ; Row 3: 0, 0, 0, 1
        lda #0
        sta MAT_B+60
        sta MAT_B+61
        lda #1
        sta MAT_B+62
        lda #0
        sta MAT_B+63

        rts


Test_Vector_Rotation:

        ; Build a 45-degree Z rotation matrix in MAT_B.
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

        ; Clear MAT_B to use it as a vector container.
        ldx #0
        lda #0
@ClearVector:
        sta MAT_B,x
        inx
        cpx #64
        bne @ClearVector

        ; Set vector P = (1, 0, 0, 1).
        ; Each matrix element occupies 4 bytes.
        ; The integer word begins at offset +2.

        lda #1
        sta MAT_B+2       ; X = 1.0
        sta MAT_B+50      ; W = 1.0 (row 3, column 0)

        ; Multiply rotation matrix by vector container.
        CALL_MAT4_MUL MAT_A, MAT_B, MAT_C

        ; Display the result.
        PRINT_MAT MAT_C, 3, 3

        rts