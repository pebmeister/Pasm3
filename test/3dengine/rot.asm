
; ====================================================
; BUILD_ROT_X - Build X-Axis Rotation Matrix into RotMatrixX
; Input: A = 8-bit angle index (0-255)
; ====================================================
BUILD_ROT_X:
        sta RotAngle
        MOVE32      FIX_ONE,  RotMatrixX+0
        MOVE32      FIX_ZERO, RotMatrixX+4
        MOVE32      FIX_ZERO, RotMatrixX+8
        MOVE32      FIX_ZERO, RotMatrixX+12
        GET_COSINE  RotAngle, RotMatrixX+16
        
        GET_SINE    RotAngle, VAR_A
        jsr NegateVarA                  ; Helper or inline negation
        MOVE32      VAR_A,    RotMatrixX+20
        
        MOVE32      FIX_ZERO, RotMatrixX+24
        GET_SINE    RotAngle, RotMatrixX+28
        GET_COSINE  RotAngle, RotMatrixX+32
        rts


; ====================================================
; BUILD_ROT_Y - Build Y-Axis Rotation Matrix into RotMatrixY
; Input: A = 8-bit angle index (0-255)
; ====================================================
BUILD_ROT_Y:
        sta RotAngle
        GET_COSINE  RotAngle, RotMatrixY+0
        MOVE32      FIX_ZERO, RotMatrixY+4
        GET_SINE    RotAngle, RotMatrixY+8
        
        MOVE32      FIX_ZERO, RotMatrixY+12
        MOVE32      FIX_ONE,  RotMatrixY+16
        MOVE32      FIX_ZERO, RotMatrixY+20
        
        GET_SINE    RotAngle, VAR_A
        jsr NegateVarA
        MOVE32      VAR_A,    RotMatrixY+24
        
        MOVE32      FIX_ZERO, RotMatrixY+28
        GET_COSINE  RotAngle, RotMatrixY+32
        rts


; ====================================================
; BUILD_ROT_Z - Build Z-Axis Rotation Matrix into RotMatrixZ
; Input: A = 8-bit angle index (0-255)
; ====================================================
BUILD_ROT_Z:
        sta RotAngle
        GET_COSINE  RotAngle, RotMatrixZ+0
        
        GET_SINE    RotAngle, VAR_A
        jsr NegateVarA
        MOVE32      VAR_A,    RotMatrixZ+4
        
        MOVE32      FIX_ZERO, RotMatrixZ+8
        GET_SINE    RotAngle, RotMatrixZ+12
        GET_COSINE  RotAngle, RotMatrixZ+16
        MOVE32      FIX_ZERO, RotMatrixZ+20
        MOVE32      FIX_ZERO, RotMatrixZ+24
        MOVE32      FIX_ZERO, RotMatrixZ+28
        MOVE32      FIX_ONE,  RotMatrixZ+32
        rts

; Small reusable negation helper to keep code DRY
NegateVarA:
        lda VAR_A
        eor #$FF
        sta VAR_A
        lda VAR_A+1
        eor #$FF
        sta VAR_A+1
        lda VAR_A+2
        eor #$FF
        sta VAR_A+2
        lda VAR_A+3
        eor #$FF
        sta VAR_A+3
        clc
        lda VAR_A
        adc #1
        sta VAR_A
        lda VAR_A+1
        adc #0
        sta VAR_A+1
        lda VAR_A+2
        adc #0
        sta VAR_A+2
        lda VAR_A+3
        adc #0
        sta VAR_A+3
        rts
        
 ; ====================================================
; BUILD_ROT_GENERAL - Build Combined Euler Rotation Matrix
; Inputs: AngleX, AngleY, AngleZ
; Output: RotMatrix (Combined 3x3 rotation matrix)
; ====================================================
BUILD_ROT_GENERAL:
        ; 1. Generate individual axis matrices into isolated buffers
        lda AngleX
        jsr BUILD_ROT_X         ; -> RotMatrixX

        lda AngleY
        jsr BUILD_ROT_Y         ; -> RotMatrixY

        lda AngleZ
        jsr BUILD_ROT_Z         ; -> RotMatrixZ

        ; 2. First Concatenation: TempMatrix = RotMatrixY * RotMatrixX
        lda #<RotMatrixY
        sta PTR_MAT_A
        lda #>RotMatrixY
        sta PTR_MAT_A+1

        lda #<RotMatrixX
        sta PTR_MAT_B
        lda #>RotMatrixX
        sta PTR_MAT_B+1

        lda #<TempMatrix
        sta PTR_MAT_C
        lda #>TempMatrix
        sta PTR_MAT_C+1

        jsr MAT_MUL_3X3

        ; 3. Final Concatenation: RotMatrix = RotMatrixZ * TempMatrix
        lda #<RotMatrixZ
        sta PTR_MAT_A
        lda #>RotMatrixZ
        sta PTR_MAT_A+1

        lda #<TempMatrix
        sta PTR_MAT_B
        lda #>TempMatrix
        sta PTR_MAT_B+1

        lda #<RotMatrix
        sta PTR_MAT_C
        lda #>RotMatrix
        sta PTR_MAT_C+1

        jsr MAT_MUL_3X3
        rts