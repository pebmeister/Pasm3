
; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================
        .basic_hdr
       
        ; jsr ClearScreen
        ; lda #0
        ; sta ROW        
        ; jsr MatMulMatrixTest
        ; jsr RunYRotationTest
        ; jsr RunXRotationTest
        ; jsr RunZRotationTest
        ; jsr RunGeneralRotationTest
        
        jsr Test_SingleProjection
@wait
        jmp @wait
        

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
      
; ====================================================
; Test General Euler Rotation with TestVectorB
; ====================================================
RunGeneralRotationTest:
        ; 1. Set sample Euler angles (e.g., X=64, Y=32, Z=16)
        lda #64
        sta AngleX
        lda #32
        sta AngleY
        lda #16
        sta AngleZ

        ; 2. Build the combined rotation matrix into RotMatrix
        jsr BUILD_ROT_GENERAL

        ; 3. Set up Matrix Multiplication: RotMatrix * TestVectorB -> ResultVectorC
        lda #<RotMatrix
        sta PTR_MAT_A
        lda #>RotMatrix
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

        jsr MAT_MUL_FIX16       ; Perform combined matrix * vector multiplication

        ; 4. Configure DisplayResults for the resulting 3x1 vector
        lda #1                  ; 1 vector/matrix to display
        sta NUM_VECS
        
        lda #3                  ; 3 rows in the result vector
        ldx #0
@set_res_rows_gen:
        sta VEC_ROWS, x
        inx
        cpx #1                  ; For our 1 vector
        bne @set_res_rows_gen

        lda #1                  ; 1 column for the vector
        sta VEC_COLS

        ; Point FIXPTR at our output buffer
        lda #<ResultVectorC
        sta FIXPTR
        lda #>ResultVectorC
        sta FIXPTR+1

        ; Print the transformed vector to the screen
        jsr DisplayResults
        rts

Start3D:

        jsr HGROn

@MainFrameLoop:
        lda #1                  ; White foreground
        jsr _HGRFColor
        lda #0                  ; Black background
        jsr _HGRBColor
        jsr HGRCls

        inc AngleX
        jsr BUILD_ROT_GENERAL
        jsr TransformAndProjectVertices

        ; --- DIAGNOSTIC: Plot 8 vertex dots instead of edges ---
        jsr PlotVertexDots

        jmp @MainFrameLoop
        
 

 
 ; ====================================================
; ISOLATED PROJECTION TEST (Run Once)
; ====================================================
Test_SingleProjection:
        jsr HGROn

        lda #1                  ; White foreground
        jsr _HGRFColor
        lda #0                  ; Black background
        jsr _HGRBColor

        jsr HGRCls


; 1. Build the rotation matrices
        lda #32
        sta AngleX
        lda #0
        sta AngleY
        sta AngleZ
        jsr BUILD_ROT_GENERAL

        ; 2. CRITICAL: Explicitly point PTR_MAT_A to the final master RotMatrix
        lda #<RotMatrix
        sta PTR_MAT_A
        lda #>RotMatrix
        sta PTR_MAT_A+1

        ; 3. Point PTR_MAT_B to Vertex 1 (CubeVertices + 6)
        lda #<(CubeVertices + 6)
        sta PTR_MAT_B
        lda #>(CubeVertices + 6)
        sta PTR_MAT_B+1

        ; 4. Rotate Vertex 1
        jsr RotateVertex

        ; 5. Project the rotated coordinates
        jsr ProjectToScreen

        ; 6. Plot using the verified contract
        ldx YCOL
        
        jsr _Plot

@Halt:
        jmp @Halt
        