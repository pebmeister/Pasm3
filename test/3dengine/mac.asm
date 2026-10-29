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
        lda #1                  ; 1 vector/matrix to display
        sta NUM_VECS
        
        lda #\2                 ; 3 rows in the result vector
        ldx #0
@set_res_rows_gen:
        sta VEC_ROWS, x
        inx
        cpx #1                  ; For our 1 vector
        bne @set_res_rows_gen

        lda #4                  ; 1 column for the vector
        sta VEC_COLS


        lda #<\1
        sta FIXPTR
        lda #>\1
        sta FIXPTR+1

        jsr DisplayResults

        .endm

;********************************************
        .macro PRINT_VECTOR
        PRINT_MAT \1, 1
        .endm
        
;********************************************

        .macro PRINT_ONE
        lda #1                  ; 1 vector/matrix to display
        sta NUM_VECS        
        sta VEC_ROWS
        sta VEC_COLS

        lda #(<\1) & $FF
        sta FIXPTR
        lda #(>\1) & $FF
        sta FIXPTR+1

        jsr DisplayResults
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
