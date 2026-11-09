;********************************************
;* ROTATION_Z
;*
;* Build a 4x4 Z rotation matrix.
;* ROT_Z_ANGLE = 64 means 90 degrees.
;* ROT_Z_MATRIX = output matrix
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

        ; Clear entire 64-byte ROT_Z_MATRIX buffer to 0
        ldx #0
@ClearMat:
        lda #0
        sta ROT_Z_MATRIX,x
        sta ROT_Z_MATRIX+16,x
        sta ROT_Z_MATRIX+32,x
        sta ROT_Z_MATRIX+48,x
        inx
        cpx #16
        bne @ClearMat

        ; ROT_Z_MATRIX row 0: [cos, -sin, 0, 0]
        ldx #0
@CopyCos0:
        lda ROT_COSINE,x
        sta ROT_Z_MATRIX,x
        inx
        cpx #4
        bne @CopyCos0

        ldx #0
@CopyNegSin:
        lda ROT_NEG_SINE,x
        sta ROT_Z_MATRIX+4,x
        inx
        cpx #4
        bne @CopyNegSin

        ; ROT_Z_MATRIX row 1: [sin, cos, 0, 0]
        ldx #0
@CopySin:
        lda ROT_SINE,x
        sta ROT_Z_MATRIX+16,x
        inx
        cpx #4
        bne @CopySin

        ldx #0
@CopyCos1:
        lda ROT_COSINE,x
        sta ROT_Z_MATRIX+20,x
        inx
        cpx #4
        bne @CopyCos1

        ; ROT_Z_MATRIX row 2: [0, 0, 1.0, 0] -> 1.0 at offset 40 (Row 2, Col 2)
        ldx #0
@CopyOne2:
        lda MAT_I+40,x
        sta ROT_Z_MATRIX+40,x
        inx
        cpx #4
        bne @CopyOne2

        ; ROT_Z_MATRIX row 3: [0, 0, 0, 1.0] -> 1.0 at offset 60 (Row 3, Col 3)
        ldx #0
@CopyOne3:
        lda MAT_I+60,x
        sta ROT_Z_MATRIX+60,x
        inx
        cpx #4
        bne @CopyOne3

        rts
        
 ;********************************************
;* ROTATION_Y
;*
;* Build a 4x4 Y rotation matrix in ROT_Y_MATRIX.
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
        sta ROT_Y_MATRIX,x
        inx
        cpx #64
        bne @YClear

        ; Row 0, column 0: cos
        ldx #0
@YCos0:
        lda ROT_COSINE,x
        sta ROT_Y_MATRIX,x
        inx
        cpx #4
        bne @YCos0

        ; Row 0, column 2: sin
        ldx #0
@YSin0:
        lda ROT_SINE,x
        sta ROT_Y_MATRIX+8,x
        inx
        cpx #4
        bne @YSin0

        ; Row 1, column 1: 1.0
        lda #1
        sta ROT_Y_MATRIX+22

        ; Row 2, column 0: -sin
        ldx #0
@YNegSin:
        lda ROT_NEG_SINE,x
        sta ROT_Y_MATRIX+32,x
        inx
        cpx #4
        bne @YNegSin

        ; Row 2, column 2: cos
        ldx #0
@YCos2:
        lda ROT_COSINE,x
        sta ROT_Y_MATRIX+40,x
        inx
        cpx #4
        bne @YCos2

        ; Row 3, column 3: 1.0
        lda #1
        sta ROT_Y_MATRIX+62

        rts
        
;********************************************
;* ROTATION_X
;*
;* Build a 4x4 X rotation matrix in ROT_X_MATRIX.
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
        sta ROT_X_MATRIX
        sta ROT_X_MATRIX+1
        lda #1
        sta ROT_X_MATRIX+2
        lda #0
        sta ROT_X_MATRIX+3

        lda #0
        sta ROT_X_MATRIX+4
        sta ROT_X_MATRIX+5
        sta ROT_X_MATRIX+6
        sta ROT_X_MATRIX+7
        
        ; Correct 1.0 at ROT_X_MATRIX[0,0]
        lda #0
        sta ROT_X_MATRIX
        sta ROT_X_MATRIX+1
        lda #1
        sta ROT_X_MATRIX+2
        lda #0
        sta ROT_X_MATRIX+3


        ; Row 1, Col 0 = 0.0
        lda #0
        sta ROT_X_MATRIX+16
        sta ROT_X_MATRIX+17
        sta ROT_X_MATRIX+18
        sta ROT_X_MATRIX+19
        
        ; Row 1: 0, cos, -sin, 0
        ldx #0
@XCos:
        lda ROT_COSINE,x
        sta ROT_X_MATRIX+20,x
        lda ROT_NEG_SINE,x
        sta ROT_X_MATRIX+24,x
        inx
        cpx #4
        bne @XCos

        ; Row 2: 0, sin, cos, 0
        ldx #0
@XSinCos:
        lda ROT_SINE,x
        sta ROT_X_MATRIX+36,x
        lda ROT_COSINE,x
        sta ROT_X_MATRIX+40,x
        inx
        cpx #4
        bne @XSinCos

        ; Row 3: 0, 0, 0, 1
        lda #0
        sta ROT_X_MATRIX+60
        sta ROT_X_MATRIX+61
        lda #1
        sta ROT_X_MATRIX+62
        lda #0
        sta ROT_X_MATRIX+63

        rts


