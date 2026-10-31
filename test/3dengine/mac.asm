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
        
        
 ;********************************************
;* PUSH16                                   *
;* Push 16-bit value                        *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro PUSH16
        lda \1
        pha
        lda \1 + 1
        pha
        .endm

;********************************************
;* POP16                                    *
;* Pop 16-bit value                         *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro POP16
        pla
        sta \1 + 1
        pla
        sta \1
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
        .macro PRINT_VECTOR
        PRINT_MAT \1, \2, 1
        .endm
        
;********************************************

        .macro PRINT_ONE
        PRINT_MAT \1, 1, 1
        .endm
        
        
 ;********************************************
;* ADD_FIX16
;*
;* /1 = Variable 1
;* /2 = Variable 2
;* /3 = Destination
;*
;* Adds signed 16.16 values using two's
;* complement representation.
;* Destroys A.
;********************************************

        .macro ADD_FIX16
        clc
        lda \1
        adc \2
        sta \3

        lda \1 + 1
        adc \2 + 1
        sta \3 + 1

        lda \1 + 2
        adc \2 + 2
        sta \3 + 2

        lda \1 + 3
        adc \2 + 3
        sta \3 + 3
        .endm

;********************************************
;* MULT16I                                  *
;* 16-bit immediate multiplication          *
;* \1 Immediate value a (16-bit constant)   *
;* \2 Variable b (16-bit variable)          *
;* \3 Destination (32-bit)                  *
;* Destroys A, X, Y                         *
;********************************************

        .macro MULT16I
        PUSH16 \2

        lda #0
        sta \3                      ; Result byte 0
        sta \3 + 1                  ; Result byte 1
        sta \3 + 2                  ; Result byte 2
        ; A must also start at zero!
        ; Do this after clearing the destination.
        lda #0

        ldx #16
@l1:
        lsr \2 + 1
        ror \2
        bcc @l2

        tay
        clc
        lda #<\1
        adc \3 + 2
        sta \3 + 2

        tya
        adc #>\1
@l2:
        ror
        ror \3 + 2
        ror \3 + 1
        ror \3

        dex
        bne @l1

        sta \3 + 3
        POP16 \2
        .endm
        
 ;********************************************
;* ADD8I                                    *
;* Add 8-bit immediate to variable          *
;* \1 Variable 1                            *
;* \2 Immediate value                       *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD8I
        clc
        lda \1
        adc #\2
        sta \3
        .endm

;********************************************
;* ADD16I                                   *
;* Add 16-bit immediate to 16-bit variable  *
;* \1 Variable                              *
;* \2 Value                                 *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD16I
        clc
        lda \1
        adc #<\2
        sta \3
        lda \1 + 1
        adc #>\2
        sta \3 + 1
        .endm
        
 ;********************************************
;*                                          *
;* PUSHREG                                  *
;*                                          *
;*  push registers on the stack             *
;*                                          *
;*  destroys a                              *
;*                                          *
;********************************************
        .macro PUSHREGS
        php
        pha
        tya
        pha
        txa
        pha
        .endm

;********************************************
;*                                          *
;* POPREG                                   *
;*                                          *
;*  restore registers on the stack          *
;*                                          *
;*  destroys a,x,y                          *
;*                                          *
;********************************************
        .macro POPREGS
        pla
        tax
        pla
        tay
        pla
        plp
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
;* SET_SCALE_I X, Y, Z                        *
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
        
         ; SET_ROTATION X, Y, Z

        .macro SET_ROTATION

        lda \1
        sta ROT_X_ANGLE

        lda \2
        sta ROT_Y_ANGLE

        lda \3
        sta ROT_Z_ANGLE

        jsr BUILD_ROTATION_MATRIX

        .endm
        
         .macro SET_ROTATION_I

        lda #\1
        sta ROT_X_ANGLE

        lda #\2
        sta ROT_Y_ANGLE

        lda #\3
        sta ROT_Z_ANGLE

        jsr BUILD_ROTATION_MATRIX

        .endm
        
 ;********************************************
;* MOVE16                                   *
;* Move a 16-bit variable                   *
;* \1 Source                                *
;* \2 Destination                           *
;* Destroys A                               *
;*******************************************
        .macro MOVE16
        lda \1
        sta \2
        lda \1 + 1
        sta \2 + 1
        .endm

;********************************************
;* RSHIFT16                                 *
;* 16-bit right shift                       *
;* \1 Variable                              *
;* \2 Bits to shift                         *
;* Destroys X                               *
;********************************************
        .macro RSHIFT16
        ldx #\2
        beq @RSH16Exit
@RSH16Loop:
        lsr \1 + 1
        ror \1
        dex
        bne @RSH16Loop
@RSH16Exit:
        .endm

;********************************************
;* ADD16                                    *
;* Add 16-bit variables                     *
;* \1 Variable 1                            *
;* \2 Variable 2                            *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD16
        clc
        lda \1
        adc \2
        sta \3
        lda \1 + 1
        adc \2 + 1
        sta \3 + 1
        .endm

;********************************************
;* MOVE8I                                   *
;* Move an 8-bit value to a variable        *
;* \1 Variable                              *
;* \2 Value                                 *
;* Destroys A                               *
;********************************************
        .macro MOVE8I
        lda #\2
        sta \1
        .endm

;********************************************
;* SUB8                                     *
;* Subtract 8-bit variables                 *
;* \1 Variable                              *
;* \2 Variable to subtract                  *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB8
        sec
        lda \1
        sbc \2
        sta \3
        .endm

;********************************************
;* BLE16                                    *
;* 16-bit branch if less than or equal      *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination label (if a <= b)         *
;* Destroys A                               *
;********************************************
        .macro BLE16
        lda \1 + 1
        cmp \2 + 1
        bcc \3
        bne @exit
        lda \1
        cmp \2
        bcc \3
        beq \3
@exit:
        .endm

;********************************************
;*                                          *
;*  SWAP16                                  *
;*                                          *
;*  Swap 2 16 bit values                    *
;*                                          *
;*  \1  Variable a     16-bit               *
;*  \2  Variable b     16 bit               *
;*                                          *
;********************************************
            .macro SWAP16
            ldx \1
            ldy \1 + 1
            lda \2
            sta \1
            lda \2 + 1
            sta \1 + 1
            stx \2
            sty \2 + 1
            .endm

;********************************************
;* SUB16                                    *
;* Subtract 16-bit variables                *
;* \1 Variable                              *
;* \2 Variable to subtract                  *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB16
        sec
        lda \1
        sbc \2
        sta \3
        lda \1 + 1
        sbc \2 + 1
        sta \3 + 1
        .endm
;********************************************
;* MOVE8                                    *
;* Move an 8-bit variable                   *
;* \1 Source                                *
;* \2 Destination                           *
;* Destroys A                               *
;********************************************
        .macro MOVE8
        lda \1
        sta \2
        .endm

;********************************************
;* BLT16                                    *
;* 16-bit branch if less than (a < b)       *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination label                     *
;* Destroys A                               *
;********************************************
        .macro BLT16
        lda \1 + 1
        cmp \2 + 1
        bcc \3
        bne @exit
        lda \1
        cmp \2
        bcc \3
@exit:
        .endm

;********************************************
;* LSHIFT16                                 *
;* 16-bit left shift                        *
;* \1 Variable                              *
;* \2 Bits to shift                         *
;* Destroys X                               *
;********************************************
        .macro LSHIFT16
        ldx #\2
        beq @LSH16Exit
@LS16Loop:
        asl \1
        rol \1 + 1
        dex
        bne @LS16Loop
@LSH16Exit:
        .endm

;********************************************
;* SUB168                                   *
;* Subtract 8-bit variable from 16-bit      *
;* \1 Variable (16-bit)                     *
;* \2 Variable to subtract (8-bit)          *
;* \3 Destination (16-bit)                  *
;* Destroys A                               *
;********************************************
        .macro SUB168
        sec
        lda \1
        sbc \2
        sta \3
        lda \1 + 1
        sbc #0
        sta \3 + 1
        .endm
;********************************************
;* SUB16I                                   *
;* Subtract 16-bit immediate from variable  *
;* \1 Variable                              *
;* \2 Value to subtract                     *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB16I
        sec
        lda \1
        sbc #<\2
        sta \3
        lda \1 + 1
        sbc #>\2
        sta \3 + 1
        .endm

