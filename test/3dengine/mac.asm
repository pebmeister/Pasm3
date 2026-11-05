    .print push
    .print off
    
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
        
;********************************************
;* CALL_MAT3_MUL
;*
;* /1 = Matrix A
;* /2 = Matrix B
;* /3 = Matrix C
;********************************************

        .macro CALL_MAT3_MUL

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

        jsr MAT3_MUL

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
        
;********************************************
;* MAT4_COPY
;* Copy a 4x4 matrix (64 bytes)
;*
;* Parameters:
;*   \1 = address of source matrix
;*   \2   = address of destination matrix
;*
;* Uses:
;*   MOVE32 \1, dest
;********************************************

        .macro MAT4_COPY
        
        ldy #63
@l1:
        lda \1,y
        sta \2,y
        dey
        bpl @l1
       .endm


;********************************************
;* MAT4_COPY
;* Copy a 4x4 matrix (64 bytes)
;*
;* Parameters:
;*   \1 = address of source matrix
;*   \2   = address of destination matrix
;*
;* Uses:
;*   MOVE32 \1, dest
;********************************************

        .macro VERT_COPY
        
        ldy #127
@l1:
        lda \1,y
        sta \2,y
        dey
        bpl @l1
       .endm

;********************************************
        .macro PRINT_MAT
        
        lda #1
        sta DISPLAY_VECTORS
        
        lda #\2                 ; 3 rows in the result vector
        sta DISPLAY_ROWS

        lda #\3                  ; 1 column for the vector
        sta DISPLAY_COLS

        lda #<\1
        sta FIXPTR
        lda #>\1
        sta FIXPTR+1

        jsr DisplayResults

        .endm


;********************************************
;*                                          *
;* SET_SCALE X, Y, Z                        *
;*                                          *
;*                                          *
;*  destroys a,x,y                          *
;*                                          *
;********************************************
        .macro SET_SCALE

        ; Copy X
        lda \1
        sta SCALE_X
        lda \1 + 1
        sta SCALE_X + 1
        lda \1 + 2
        sta SCALE_X + 2
        lda \1 + 3
        sta SCALE_X + 3

        ; Copy Y
        lda \2
        sta SCALE_Y
        lda \2 + 1
        sta SCALE_Y + 1
        lda \2 + 2
        sta SCALE_Y + 2
        lda \2 + 3
        sta SCALE_Y + 3

        ; Copy Z
        lda \3
        sta SCALE_Z
        lda \3 + 1
        sta SCALE_Z + 1
        lda \3 + 2
        sta SCALE_Z + 2
        lda \3 + 3
        sta SCALE_Z + 3

        jsr BUILD_SCALING_MATRIX

        .endm
        
        ; SET_SCALE_I X, Y, Z

;********************************************
;*                                          *
;* SET_SCALE_I X, Y, Z                      *
;*                                          *
;*                                          *
;*  destroys a,x,y                          *
;*                                          *
;********************************************
        .macro SET_SCALE_I

        ; X
        lda #0
        sta SCALE_X
        sta SCALE_X + 1
        lda #<\1
        sta SCALE_X + 2
        lda #>\1
        sta SCALE_X + 3

        ; Y
        lda #0
        sta SCALE_Y
        sta SCALE_Y + 1
        lda #<\2
        sta SCALE_Y + 2
        lda #>\2
        sta SCALE_Y + 3

        ; Z
        lda #0
        sta SCALE_Z
        sta SCALE_Z + 1
        lda #<\3
        sta SCALE_Z + 2
        lda #>\3
        sta SCALE_Z + 3

        jsr BUILD_SCALING_MATRIX

        .endm
        
;********************************************
;*                                          *
;* SET_TRANSLATION X, Y, Z                  *
;*                                          *
;********************************************
        .macro SET_TRANSLATION

        ; Copy X
        lda \1
        sta TRANS_X
        lda \1 + 1
        sta TRANS_X + 1
        lda \1 + 2
        sta TRANS_X + 2
        lda \1 + 3
        sta TRANS_X + 3

        ; Copy Y
        lda \2
        sta TRANS_Y
        lda \2 + 1
        sta TRANS_Y + 1
        lda \2 + 2
        sta TRANS_Y + 2
        lda \2 + 3
        sta TRANS_Y + 3

        ; Copy Z
        lda \3
        sta TRANS_Z
        lda \3 + 1
        sta TRANS_Z + 1
        lda \3 + 2
        sta TRANS_Z + 2
        lda \3 + 3
        sta TRANS_Z + 3

        jsr BUILD_TRANSLATION_MATRIX

        .endm
        
        
;********************************************
;*                                          *
;* SET_TRANSLATION_I X, Y, Z                *
;*                                          *
;********************************************
        .macro SET_TRANSLATION_I

        ; X
        lda #0
        sta TRANS_X
        sta TRANS_X + 1
        lda #<\1
        sta TRANS_X + 2
        lda #>\1
        sta TRANS_X + 3

        ; Y
        lda #0
        sta TRANS_Y
        sta TRANS_Y + 1
        lda #<\2
        sta TRANS_Y + 2
        lda #>\2
        sta TRANS_Y + 3

        ; Z
        lda #0
        sta TRANS_Z
        sta TRANS_Z + 1
        lda #<\3
        sta TRANS_Z + 2
        lda #>\3
        sta TRANS_Z + 3

        jsr BUILD_TRANSLATION_MATRIX

        .endm
        
;********************************************
;*                                          *
;* SET_ROTATION X, Y, Z                     *
;*                                          *
;********************************************
        .macro SET_ROTATION

        lda \1
        sta ROT_X_ANGLE
        lda \2
        sta ROT_Y_ANGLE
        lda \3
        sta ROT_Z_ANGLE

        jsr BUILD_ROTATION_MATRIX

        .endm
        
;********************************************
;*                                          *
;* SET_ROTATION_I X, Y, Z                   *
;*                                          *
;********************************************
         .macro SET_ROTATION_I

        lda #\1
        sta ROT_X_ANGLE
        lda #\2
        sta ROT_Y_ANGLE
        lda #\3
        sta ROT_Z_ANGLE

        jsr BUILD_ROTATION_MATRIX

        .endm
        
               
        .macro CALL_PRINT_FIX16
        lda #<\1
        sta FIXPTR
        lda #>\1
        sta FIXPTR+1
        jsr PRINT_FIX16
        rts
        .endm
        
        .print pop
