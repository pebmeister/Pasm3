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
; MAT_MUL_3X3 - Multiply two 3x3 matrices: A * B -> C
; Inputs: PTR_MAT_A, PTR_MAT_B, PTR_MAT_C
; ====================================================
MAT_MUL_3X3:
        lda PTR_MAT_B
        sta SavedMatB
        lda PTR_MAT_B+1
        sta SavedMatB+1

        lda PTR_MAT_C
        sta SavedMatC
        lda PTR_MAT_C+1
        sta SavedMatC+1

        ; --- Column 0 (Y = 0) ---
        ldy #0
        jsr CopyColToTemp
        jsr DoMatrixMulVector
        lda SavedMatC
        sta PTR_MAT_C
        lda SavedMatC+1
        sta PTR_MAT_C+1
        ldy #0
        jsr CopyTempToColC

        ; --- Column 1 (Y = 4) ---
        lda SavedMatB
        sta PTR_MAT_B
        lda SavedMatB+1
        sta PTR_MAT_B+1
        ldy #4
        jsr CopyColToTemp
        jsr DoMatrixMulVector
        lda SavedMatC
        sta PTR_MAT_C
        lda SavedMatC+1
        sta PTR_MAT_C+1
        ldy #4
        jsr CopyTempToColC

        ; --- Column 2 (Y = 8) ---
        lda SavedMatB
        sta PTR_MAT_B
        lda SavedMatB+1
        sta PTR_MAT_B+1
        ldy #8
        jsr CopyColToTemp
        jsr DoMatrixMulVector
        lda SavedMatC
        sta PTR_MAT_C
        lda SavedMatC+1
        sta PTR_MAT_C+1
        ldy #8
        jsr CopyTempToColC
        rts


; --- Helper Routines for Column Extraction & Multiplication ---

CopyColToTemp:
        sty ColOffset
        ldy ColOffset
        lda (PTR_MAT_B),y
        sta TempCol
        iny
        lda (PTR_MAT_B),y
        sta TempCol+1
        iny
        lda (PTR_MAT_B),y
        sta TempCol+2
        iny
        lda (PTR_MAT_B),y
        sta TempCol+3

        ldy ColOffset
        tya
        clc
        adc #12
        tay
        lda (PTR_MAT_B),y
        sta TempCol+4
        iny
        lda (PTR_MAT_B),y
        sta TempCol+5
        iny
        lda (PTR_MAT_B),y
        sta TempCol+6
        iny
        lda (PTR_MAT_B),y
        sta TempCol+7

        ldy ColOffset
        tya
        clc
        adc #24
        tay
        lda (PTR_MAT_B),y
        sta TempCol+8
        iny
        lda (PTR_MAT_B),y
        sta TempCol+9
        iny
        lda (PTR_MAT_B),y
        sta TempCol+10
        iny
        lda (PTR_MAT_B),y
        sta TempCol+11
        rts

DoMatrixMulVector:
        lda #<TempCol
        sta PTR_MAT_B
        lda #>TempCol
        sta PTR_MAT_B+1

        lda #<TempResult
        sta PTR_MAT_C
        lda #>TempResult
        sta PTR_MAT_C+1

        lda #3
        sta MAT_K
        lda #3
        sta MAT_M

        jsr MAT_MUL_FIX16
        rts

CopyTempToColC:
        sty ColOffset
        ldy ColOffset
        lda TempResult
        sta (PTR_MAT_C),y
        iny
        lda TempResult+1
        sta (PTR_MAT_C),y
        iny
        lda TempResult+2
        sta (PTR_MAT_C),y
        iny
        lda TempResult+3
        sta (PTR_MAT_C),y

        ldy ColOffset
        tya
        clc
        adc #12
        tay
        lda TempResult+4
        sta (PTR_MAT_C),y
        iny
        lda TempResult+5
        sta (PTR_MAT_C),y
        iny
        lda TempResult+6
        sta (PTR_MAT_C),y
        iny
        lda TempResult+7
        sta (PTR_MAT_C),y

        ldy ColOffset
        tya
        clc
        adc #24
        tay
        lda TempResult+8
        sta (PTR_MAT_C),y
        iny
        lda TempResult+9
        sta (PTR_MAT_C),y
        iny
        lda TempResult+10
        sta (PTR_MAT_C),y
        iny
        lda TempResult+11
        sta (PTR_MAT_C),y
        rts
        
        