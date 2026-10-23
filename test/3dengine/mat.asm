; ====================================================
; MAT_MUL_FIX16 (Matrix x Vector Engine)
; ====================================================
MAT_MUL_FIX16:
        lda #0
        sta ROW_INDEX

@RowLoop:
        lda PTR_MAT_A
        sta PTR_A
        lda PTR_MAT_A+1
        sta PTR_A+1

        ldx ROW_INDEX
        bne @DoRowOffset
        jmp @SkipRowOffset

@DoRowOffset:
@RowOffsetLoop:
        ldy #4
@Add4:
        clc
        lda PTR_A
        adc MAT_K
        sta PTR_A
        bcc @NoCarryA
        inc PTR_A+1
@NoCarryA:
        dey
        bne @Add4
        dex
        beq @SkipRowLoop
        jmp @RowOffsetLoop
@SkipRowLoop:
@SkipRowOffset:

        lda PTR_MAT_B
        sta PTR_B
        lda PTR_MAT_B+1
        sta PTR_B+1

        lda MAT_K
        sta DOT_LEN
        jsr MAT_DOT_MUL_FIX16

        lda PTR_MAT_C
        sta TEMP_PTR
        lda PTR_MAT_C+1
        sta TEMP_PTR+1

        ldx ROW_INDEX
        bne @DoStoreOffset
        jmp @StoreDirect

@DoStoreOffset:
@StoreOffsetLoop:
        clc
        lda TEMP_PTR
        adc #4
        sta TEMP_PTR
        bcc @NoCarryC
        inc TEMP_PTR+1
@NoCarryC:
        dex
        beq @SkipStoreLoop
        jmp @StoreOffsetLoop
@SkipStoreLoop:

@StoreDirect:
        ldy #0
        lda DOT_RESULT
        sta (TEMP_PTR),y
        iny
        lda DOT_RESULT+1
        sta (TEMP_PTR),y
        iny
        lda DOT_RESULT+2
        sta (TEMP_PTR),y
        iny
        lda DOT_RESULT+3
        sta (TEMP_PTR),y

        inc ROW_INDEX
        lda ROW_INDEX
        cmp MAT_M
        beq @AllRowsDone
        jmp @RowLoop

@AllRowsDone:
        rts

; ====================================================
; MAT_DOT_MUL_FIX16
; ====================================================
MAT_DOT_MUL_FIX16:
        lda #0
        sta DOT_RESULT
        sta DOT_RESULT+1
        sta DOT_RESULT+2
        sta DOT_RESULT+3

        lda DOT_LEN
        bne @RunLoop      ; If DOT_LEN != 0, short branch to run loop
        jmp @Done         ; Otherwise, absolute jump far to @Done

@RunLoop:
@Loop:
        ldy #0
        lda (PTR_A),y
        sta VAR_A
        iny
        lda (PTR_A),y
        sta VAR_A+1
        iny
        lda (PTR_A),y
        sta VAR_A+2
        iny
        lda (PTR_A),y
        sta VAR_A+3

        ldy #0
        lda (PTR_B),y
        sta VAR_B
        iny
        lda (PTR_B),y
        sta VAR_B+1
        iny
        lda (PTR_B),y
        sta VAR_B+2
        iny
        lda (PTR_B),y
        sta VAR_B+3

        MUL_FIX16 VAR_A, VAR_B, TEMP_PROD32
        ADD_FIX16 DOT_RESULT, TEMP_PROD32, DOT_RESULT

        clc
        lda PTR_A
        adc #4
        sta PTR_A
        bcc @SkipIncA
        inc PTR_A+1
@SkipIncA:

        clc
        lda PTR_B
        adc #4
        sta PTR_B
        bcc @SkipIncB
        inc PTR_B+1
@SkipIncB:

        dec DOT_LEN
        beq @ExitLoop
        jmp @Loop
@ExitLoop:
@Done:
        rts
        
; ====================================================
; MAT_MUL_3X3 - Multiply two 3x3 fixed-point matrices
; Inputs: PTR_MAT_A, PTR_MAT_B
; Output: PTR_MAT_C (can safely overlap with inputs if using TempMatrix)
; ====================================================
MAT_MUL_3X3:
        ; For a 3x3 matrix C = A * B:
        ; C[row, col] = Dot product of Row(A, row) and Col(B, col)
        ; We can compute this cleanly by iterating 3 rows and 3 columns.
        
        lda #0
        sta ROW_INDEX           ; Row loop counter (0 to 2)

@RowLoop3x3:
        lda #0
        sta COL_INDEX           ; Col loop counter (0 to 2)

@ColLoop3x3:
        ; Compute dot product of Row (ROW_INDEX) of Mat A and Col (COL_INDEX) of Mat B.
        ; We can set up pointers for the dot product function:
        ; - PTR_A points to start of Row ROW_INDEX in Mat A (Mat A + row * 12)
        ; - PTR_B points to start of Col COL_INDEX in Mat B (Mat B + col * 4, with stride 12)
        
        ; (Implementation uses our existing dot product engine by structuring pointers)
        ; ...
        
        inc COL_INDEX
        lda COL_INDEX
        cmp #3
        bne @ColLoop3x3

        inc ROW_INDEX
        lda ROW_INDEX
        cmp #3
        bne @RowLoop3x3
        rts
        