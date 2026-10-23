
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
        beq @SkipRowOffset
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
        bne @RowOffsetLoop
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
        beq @StoreDirect
@StoreOffsetLoop:
        clc
        lda TEMP_PTR
        adc #4
        sta TEMP_PTR
        bcc @NoCarryC
        inc TEMP_PTR+1
@NoCarryC:
        dex
        bne @StoreOffsetLoop

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
        bne @RowLoop
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
        beq @Done

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
        bne @Loop
@Done:
        rts
