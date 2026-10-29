;********************************************
;* MAT4_MUL
;*
;* Calculates C = A * B
;*
;* Matrix layout: 4x4 row-major
;* Each element: signed 16.16, 4 bytes
;* Each matrix: 64 bytes
;*
;* Inputs:
;*   MAT4_A_PTR -> Matrix A
;*   MAT4_B_PTR -> Matrix B
;*   MAT4_C_PTR -> Matrix C
;*
;* Uses FIX16_MUL and ADD_FIX16.
;* Matrix C must not overlap A or B.
;********************************************

MAT4_MUL:

        ; Initialize row pointer
        lda MAT4_A_PTR
        sta MAT_AROW
        lda MAT4_A_PTR+1
        sta MAT_AROW+1

        ; Initialize B column pointer
        lda MAT4_B_PTR
        sta MAT_BCOL
        lda MAT4_B_PTR+1
        sta MAT_BCOL+1

        ; Initialize output pointer
        lda MAT4_C_PTR
        sta MAT_CPTR
        lda MAT4_C_PTR+1
        sta MAT_CPTR+1

        lda #0
        sta MAT_ROW

M4M_RowLoop:

        lda #0
        sta MAT_COL

M4M_ColLoop:

        ; A pointer starts at current row
        lda MAT_AROW
        sta MAT_APTR
        lda MAT_AROW+1
        sta MAT_APTR+1

        ; B pointer starts at current column
        lda MAT_BCOL
        sta MAT_BPTR
        lda MAT_BCOL+1
        sta MAT_BPTR+1

        ; Clear 32-bit accumulator
        lda #0
        sta MAT_ACCUM
        sta MAT_ACCUM+1
        sta MAT_ACCUM+2
        sta MAT_ACCUM+3

        lda #0
        sta MAT_K

M4M_InnerLoop:

        ; Set FIX16 operand A pointer
        lda MAT_APTR
        sta FIX16_A_PTR
        lda MAT_APTR+1
        sta FIX16_A_PTR+1

        ; Set FIX16 operand B pointer
        lda MAT_BPTR
        sta FIX16_B_PTR
        lda MAT_BPTR+1
        sta FIX16_B_PTR+1

        ; Store product in MAT_PRODUCT
        lda #<MAT_PRODUCT
        sta FIX16_RESULT_PTR
        lda #>MAT_PRODUCT
        sta FIX16_RESULT_PTR+1

        ; Product = A[row][k] * B[k][col]
        jsr FIX16_MUL

        ; Accumulate product
        ADD_FIX16 MAT_ACCUM, MAT_PRODUCT, MAT_ACCUM

        ; A advances by 4 bytes
        clc
        lda MAT_APTR
        adc #4
        sta MAT_APTR
        bcc M4M_APtrReady
        inc MAT_APTR+1

M4M_APtrReady:

        ; B advances by 16 bytes
        clc
        lda MAT_BPTR
        adc #16
        sta MAT_BPTR
        bcc M4M_BPtrReady
        inc MAT_BPTR+1

M4M_BPtrReady:

        inc MAT_K
        lda MAT_K
        cmp #4
        bne M4M_InnerLoop

        ; Store C[row][col]
        ldy #0
        lda MAT_ACCUM
        sta (MAT_CPTR),y
        iny
        lda MAT_ACCUM+1
        sta (MAT_CPTR),y
        iny
        lda MAT_ACCUM+2
        sta (MAT_CPTR),y
        iny
        lda MAT_ACCUM+3
        sta (MAT_CPTR),y

        ; C advances by 4 bytes
        clc
        lda MAT_CPTR
        adc #4
        sta MAT_CPTR
        bcc M4M_CPtrReady
        inc MAT_CPTR+1

M4M_CPtrReady:

        ; B column advances by 4 bytes
        clc
        lda MAT_BCOL
        adc #4
        sta MAT_BCOL
        bcc M4M_BColReady
        inc MAT_BCOL+1

M4M_BColReady:

        inc MAT_COL
        lda MAT_COL
        cmp #4
        bne M4M_ColLoop

        ; A advances to next row
        clc
        lda MAT_AROW
        adc #16
        sta MAT_AROW
        bcc M4M_ARowReady
        inc MAT_AROW+1

M4M_ARowReady:

        ; Reset B column to beginning of B
        lda MAT4_B_PTR
        sta MAT_BCOL
        lda MAT4_B_PTR+1
        sta MAT_BCOL+1

        inc MAT_ROW
        lda MAT_ROW
        cmp #4
        bne M4M_RowLoop

        rts
        
        
;********************************************
;* FIX16_MUL
;*
;* Signed 16.16 fixed-point multiplication
;*
;* Inputs:
;*   FIX16_A_PTR      -> operand A (4 bytes)
;*   FIX16_B_PTR      -> operand B (4 bytes)
;*   FIX16_RESULT_PTR -> destination (4 bytes)
;*
;* Uses the original 32-iteration shift/add
;* algorithm.
;*
;* Source operands are preserved.
;********************************************

FIX16_MUL:

        ; Copy operand A to working storage
        ldy #0
        lda (FIX16_A_PTR),y
        sta FIX16_WORK_A
        iny
        lda (FIX16_A_PTR),y
        sta FIX16_WORK_A+1
        iny
        lda (FIX16_A_PTR),y
        sta FIX16_WORK_A+2
        iny
        lda (FIX16_A_PTR),y
        sta FIX16_WORK_A+3

        ; Copy operand B to working storage
        ldy #0
        lda (FIX16_B_PTR),y
        sta FIX16_WORK_B
        iny
        lda (FIX16_B_PTR),y
        sta FIX16_WORK_B+1
        iny
        lda (FIX16_B_PTR),y
        sta FIX16_WORK_B+2
        iny
        lda (FIX16_B_PTR),y
        sta FIX16_WORK_B+3

        ; Determine result sign
        lda #0
        sta FIX16_SIGN

        ; If A is negative, negate working A
        lda FIX16_WORK_A+3
        bpl F16M_CheckB

        inc FIX16_SIGN

        lda #0
        sec
        sbc FIX16_WORK_A
        sta FIX16_WORK_A
        lda #0
        sbc FIX16_WORK_A+1
        sta FIX16_WORK_A+1
        lda #0
        sbc FIX16_WORK_A+2
        sta FIX16_WORK_A+2
        lda #0
        sbc FIX16_WORK_A+3
        sta FIX16_WORK_A+3

F16M_CheckB:

        ; If B is negative, negate working B
        lda FIX16_WORK_B+3
        bpl F16M_Start

        lda FIX16_SIGN
        eor #1
        sta FIX16_SIGN

        lda #0
        sec
        sbc FIX16_WORK_B
        sta FIX16_WORK_B
        lda #0
        sbc FIX16_WORK_B+1
        sta FIX16_WORK_B+1
        lda #0
        sbc FIX16_WORK_B+2
        sta FIX16_WORK_B+2
        lda #0
        sbc FIX16_WORK_B+3
        sta FIX16_WORK_B+3

F16M_Start:

        ; Clear product accumulator
        lda #0
        sta FIX16_WORK_RESULT
        sta FIX16_WORK_RESULT+1
        sta FIX16_WORK_RESULT+2
        sta FIX16_WORK_RESULT+3

        ldx #32

F16M_MulLoop:

        ; Shift multiplier right.
        ; Carry indicates whether to add A.
        lda FIX16_WORK_B
        lsr
        bcc F16M_NoAdd

        clc
        lda FIX16_WORK_RESULT
        adc FIX16_WORK_A
        sta FIX16_WORK_RESULT
        lda FIX16_WORK_RESULT+1
        adc FIX16_WORK_A+1
        sta FIX16_WORK_RESULT+1
        lda FIX16_WORK_RESULT+2
        adc FIX16_WORK_A+2
        sta FIX16_WORK_RESULT+2
        lda FIX16_WORK_RESULT+3
        adc FIX16_WORK_A+3
        sta FIX16_WORK_RESULT+3

F16M_NoAdd:

        ; Shift combined 64-bit product/multiplier
        lsr FIX16_WORK_RESULT+3
        ror FIX16_WORK_RESULT+2
        ror FIX16_WORK_RESULT+1
        ror FIX16_WORK_RESULT
        ror FIX16_WORK_B+3
        ror FIX16_WORK_B+2
        ror FIX16_WORK_B+1
        ror FIX16_WORK_B

        dex
        bne F16M_MulLoop

        ; Extract the 16.16 result
        lda FIX16_WORK_RESULT+1
        sta FIX16_WORK_RESULT+3
        lda FIX16_WORK_RESULT
        sta FIX16_WORK_RESULT+2
        lda FIX16_WORK_B+3
        sta FIX16_WORK_RESULT+1
        lda FIX16_WORK_B+2
        sta FIX16_WORK_RESULT

        ; Negate result if signs differed
        lda FIX16_SIGN
        beq F16M_StoreResult

        lda #0
        sec
        sbc FIX16_WORK_RESULT
        sta FIX16_WORK_RESULT
        lda #0
        sbc FIX16_WORK_RESULT+1
        sta FIX16_WORK_RESULT+1
        lda #0
        sbc FIX16_WORK_RESULT+2
        sta FIX16_WORK_RESULT+2
        lda #0
        sbc FIX16_WORK_RESULT+3
        sta FIX16_WORK_RESULT+3

F16M_StoreResult:

        ; Copy result to caller's destination
        ldy #0
        lda FIX16_WORK_RESULT
        sta (FIX16_RESULT_PTR),y
        iny
        lda FIX16_WORK_RESULT+1
        sta (FIX16_RESULT_PTR),y
        iny
        lda FIX16_WORK_RESULT+2
        sta (FIX16_RESULT_PTR),y
        iny
        lda FIX16_WORK_RESULT+3
        sta (FIX16_RESULT_PTR),y

        rts
        
        
 ;********************************************
;* MAT4_VECTOR_MUL
;*
;* Calculates VOUT = Matrix * VIN
;*
;* Matrix:  64 bytes
;* Vectors: 16 bytes each
;*
;* Uses:
;*   MAT_MUL_A, MAT_MUL_B
;*   MAT_PRODUCT, MAT_ACCUM
;*   MAT_AROW, MAT_APTR, MAT_BPTR, MAT_CPTR
;*   MAT_ROW, MAT_K
;*
;* Input and output vectors must not overlap.
;********************************************

MAT4_VECTOR_MUL:

        ; Initialize matrix row pointer
        lda MAT4_MATRIX_PTR
        sta MAT_AROW
        lda MAT4_MATRIX_PTR+1
        sta MAT_AROW+1

        ; Initialize output pointer
        lda MAT4_VOUT_PTR
        sta MAT_CPTR
        lda MAT4_VOUT_PTR+1
        sta MAT_CPTR+1

        lda #0
        sta MAT_ROW

M4V_RowLoop:

        ; Matrix pointer = start of current row
        lda MAT_AROW
        sta MAT_APTR
        lda MAT_AROW+1
        sta MAT_APTR+1

        ; Input vector pointer = start of vector
        lda MAT4_VIN_PTR
        sta MAT_BPTR
        lda MAT4_VIN_PTR+1
        sta MAT_BPTR+1

        ; Clear 32-bit accumulator
        lda #0
        sta MAT_ACCUM
        sta MAT_ACCUM+1
        sta MAT_ACCUM+2
        sta MAT_ACCUM+3

        lda #0
        sta MAT_K

M4V_InnerLoop:

        ; Copy matrix element to multiplication operand A
        ldy #0
        lda (MAT_APTR),y
        sta MAT_MUL_A
        iny
        lda (MAT_APTR),y
        sta MAT_MUL_A+1
        iny
        lda (MAT_APTR),y
        sta MAT_MUL_A+2
        iny
        lda (MAT_APTR),y
        sta MAT_MUL_A+3

        ; Copy vector component to multiplication operand B
        ldy #0
        lda (MAT_BPTR),y
        sta MAT_MUL_B
        iny
        lda (MAT_BPTR),y
        sta MAT_MUL_B+1
        iny
        lda (MAT_BPTR),y
        sta MAT_MUL_B+2
        iny
        lda (MAT_BPTR),y
        sta MAT_MUL_B+3

        ; Product = A * B
        CALL_FIX16_MUL MAT_MUL_A, MAT_MUL_B, MAT_PRODUCT

        ; Accumulator += product
        ADD_FIX16 MAT_PRODUCT, MAT_ACCUM, MAT_ACCUM

        ; Advance matrix pointer by 4 bytes
        clc
        lda MAT_APTR
        adc #4
        sta MAT_APTR
        bcc M4V_APtrReady
        inc MAT_APTR+1
M4V_APtrReady:

        ; Advance vector pointer by 4 bytes
        clc
        lda MAT_BPTR
        adc #4
        sta MAT_BPTR
        bcc M4V_BPtrReady
        inc MAT_BPTR+1
M4V_BPtrReady:

        inc MAT_K
        lda MAT_K
        cmp #4
        bne M4V_InnerLoop

        ; Store accumulated result in output vector
        ldy #0
        lda MAT_ACCUM
        sta (MAT_CPTR),y
        iny
        lda MAT_ACCUM+1
        sta (MAT_CPTR),y
        iny
        lda MAT_ACCUM+2
        sta (MAT_CPTR),y
        iny
        lda MAT_ACCUM+3
        sta (MAT_CPTR),y

        ; Advance output pointer by 4 bytes
        clc
        lda MAT_CPTR
        adc #4
        sta MAT_CPTR
        bcc M4V_CPtrReady
        inc MAT_CPTR+1
M4V_CPtrReady:

        ; Advance matrix row by 16 bytes
        clc
        lda MAT_AROW
        adc #16
        sta MAT_AROW
        bcc M4V_ARowReady
        inc MAT_AROW+1
M4V_ARowReady:

        inc MAT_ROW
        lda MAT_ROW
        cmp #4
        bne M4V_RowLoop

        rts