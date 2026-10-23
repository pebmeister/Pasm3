
; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================
        .basic_hdr
       
        jsr ClearScreen
        ; jsr MatMulMatrixTest
        ; jsr RunYRotationTest
        ; jsr RunXRotationTest
        jsr RunZRotationTest
@wait
        jmp @wait
        
; ====================================================
; DisplayResults (Multi-Vector Loop Fixed)
; ====================================================
DisplayResults:
        lda #0
        sta @CUR_VEC

@Vec_Loop:
        ldx ROW
        ldy #0
        clc
        jsr PLOT

        ; Dynamically set vector letter ('A', 'B', 'C') based on @CUR_VEC index
        lda @CUR_VEC
        clc
        adc #'A'
        sta @VEC_NUM

        lda #<@MESSAGE
        ldy #>@MESSAGE
        jsr STROUT

        lda #0
        sta @VEC_CUR_ROW
    
@Vec_Row_Loop:
        inc ROW
        ldx ROW
        ldy #0
        clc
        jsr PLOT

        lda #0
        sta @VEC_CUR_COL
        
@Vec_Col_Loop:
        ; Print Element
        jsr FORMAT_FIX16
        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr STROUT
        
        lda #<@SPC
        ldy #>@SPC
        jsr STROUT

        ; Advance pointer by 4 bytes for next element
        ADD16I FIXPTR, 4, FIXPTR
        
        inc @VEC_CUR_COL
        ldx @CUR_VEC
        lda @VEC_CUR_COL
        cmp VEC_COLS,x
        bne @Vec_Col_Loop

        inc @VEC_CUR_ROW
        ldx @CUR_VEC
        lda @VEC_CUR_ROW
        cmp VEC_ROWS,x
        bne @Vec_Row_Loop
       
        ADD8I ROW,2,ROW
        inc @CUR_VEC
        lda @CUR_VEC
        cmp NUM_VECS
        bne @Vec_Loop
        
        rts

@CUR_VEC
        .byte 0       
@VEC_CUR_ROW
        .byte 0
@VEC_CUR_COL
        .byte 0

@MESSAGE
        .byte 05, "VECTOR "
@VEC_NUM
        .byte "A", 0
@SPC    .byte " ", 0

CLEARSCREEN:
        lda #<CLS
        ldy #>CLS
        jsr STROUT              ; Clear screen    
        rts
 
MatMulMatrixTest:
        lda #3
        sta MAT_M       ; Rows of A = 3
        sta MAT_K       ; Cols of A / Rows of B = 3
        lda #1
        sta MAT_N       ; Cols of B = 1

        lda #<TestMatrixA
        sta PTR_MAT_A
        lda #>TestMatrixA
        sta PTR_MAT_A+1

        lda #<TestVectorB
        sta PTR_MAT_B
        lda #>TestVectorB
        sta PTR_MAT_B+1

        lda #<ResultVectorC
        sta PTR_MAT_C
        lda #>ResultVectorC
        sta PTR_MAT_C+1

        jsr MAT_MUL_FIX16
        
; set up to print the vectors
        lda #3
        sta NUM_VECS
        
        lda #3
        ldx #0
@set_rows_loop:
        sta VEC_ROWS, x
        inx
        cpx #3
        bne @set_rows_loop

        lda #3
        sta VEC_COLS
        lda #1
        sta VEC_COLS + 1
        sta VEC_COLS + 2
        
        ; Start pointer at Matrix A
        lda #<TestMatrixA
        sta FIXPTR
        lda #>TestMatrixA
        sta FIXPTR + 1

        jsr DisplayResults

        rts
        
; ====================================================
; Test Y-Axis Rotation with TestVectorB
; ====================================================
RunYRotationTest:
        ; 1. Generate Y rotation matrix for angle 64 (90 degrees) into RotMatrixY
        lda #64
        jsr BUILD_ROT_Y

        ; 2. Set up Matrix Multiplication: RotMatrixY * TestVectorB -> ResultVectorC
        lda #<RotMatrixY
        sta PTR_MAT_A
        lda #>RotMatrixY
        sta PTR_MAT_A+1

        lda #<TestVectorB
        sta PTR_MAT_B
        lda #>TestVectorB
        sta PTR_MAT_B+1

        lda #<ResultVectorC
        sta PTR_MAT_C
        lda #>ResultVectorC
        sta PTR_MAT_C+1

        lda #3                  ; K = 3 (inner matrix dimension)
        sta MAT_K
        lda #3                  ; M = 3 (number of rows)
        sta MAT_M

        jsr MAT_MUL_FIX16       ; Perform 3x3 * 3x1 multiplication

        ; 3. Configure DisplayResults for the resulting 3x1 vector
        lda #1                  ; 1 vector/matrix to display
        sta NUM_VECS
        
        lda #3                  ; 3 rows in the result vector
        ldx #0
@set_res_rows:
        sta VEC_ROWS, x
        inx
        cpx #1                  ; For our 1 vector
        bne @set_res_rows

        lda #1                  ; 1 column for the vector
        sta VEC_COLS

        ; Point FIXPTR at our output buffer
        lda #<ResultVectorC
        sta FIXPTR
        lda #>ResultVectorC
        sta FIXPTR+1

        ; Print the rotated vector to the screen
        jsr DisplayResults
        rts
        
; ====================================================
; Test X-Axis Rotation with TestVectorB
; ====================================================
RunXRotationTest:
        ; 1. Generate X rotation matrix for angle 64 (90 degrees)
        lda #64
        jsr BUILD_ROT_X

        ; 2. Set up Matrix Multiplication: RotMatrix * TestVectorB -> RotMatrixX
        lda #<RotMatrixX
        sta PTR_MAT_A
        lda #>RotMatrixX
        sta PTR_MAT_A+1


        lda #<TestVectorB
        sta PTR_MAT_B
        lda #>TestVectorB
        sta PTR_MAT_B+1

        lda #<ResultVectorC
        sta PTR_MAT_C
        lda #>ResultVectorC
        sta PTR_MAT_C+1

        lda #3                  ; K = 3
        sta MAT_K
        lda #3                  ; M = 3
        sta MAT_M

        jsr MAT_MUL_FIX16

        ; 3. Configure DisplayResults
        lda #1
        sta NUM_VECS
        
        lda #3
        ldx #0
@set_res_rows_x:
        sta VEC_ROWS, x
        inx
        cpx #1
        bne @set_res_rows_x

        lda #1
        sta VEC_COLS

        lda #<ResultVectorC
        sta FIXPTR
        lda #>ResultVectorC
        sta FIXPTR+1

        jsr DisplayResults
        rts
        
 ; ====================================================
; Test Z-Axis Rotation with TestVectorB
; ====================================================
RunZRotationTest:
        ; 1. Generate Z rotation matrix for angle 64 (90 degrees)
        lda #64
        jsr BUILD_ROT_Z

        ; 2. Set up Matrix Multiplication: RotMatrix * TestVectorB -> RotMatrixZ
        lda #<RotMatrixZ
        sta PTR_MAT_A
        lda #>RotMatrixZ
        sta PTR_MAT_A+1

        lda #<TestVectorB
        sta PTR_MAT_B
        lda #>TestVectorB
        sta PTR_MAT_B+1

        lda #<ResultVectorC
        sta PTR_MAT_C
        lda #>ResultVectorC
        sta PTR_MAT_C+1

        lda #3                  ; K = 3
        sta MAT_K
        lda #3                  ; M = 3
        sta MAT_M

        jsr MAT_MUL_FIX16

        ; 3. Configure DisplayResults
        lda #1
        sta NUM_VECS
        
        lda #3
        ldx #0
@set_res_rows_z:
        sta VEC_ROWS, x
        inx
        cpx #1
        bne @set_res_rows_z

        lda #1
        sta VEC_COLS

        lda #<ResultVectorC
        sta FIXPTR
        lda #>ResultVectorC
        sta FIXPTR+1

        jsr DisplayResults
        rts
      