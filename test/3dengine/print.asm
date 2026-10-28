
; ====================================================
; FORMAT_FIX16 Routine (Space-padded for alignment)
; ====================================================
FORMAT_FIX16:
        ldy #0
        lda (FIXPTR),y
        sta FMT_VAL
        iny
        lda (FIXPTR),y
        sta FMT_VAL+1
        iny
        lda (FIXPTR),y
        sta FMT_VAL+2
        iny
        lda (FIXPTR),y
        sta FMT_VAL+3

        ; Set uniform offsets for both positive and negative (Index 0 reserved for sign/space)
        lda #1
        sta FMT_INTOFF
        lda #6
        sta FMT_FRACOFF
        lda #10
        sta FMT_DIG5IDX
        lda #11
        sta FMT_NULLIDX

        lda FMT_VAL+3
        bmi @NegativeNumber

        lda #0
        sta FMT_SIGNFLG
        jmp @FormatCore

@NegativeNumber:
        lda #1
        sta FMT_SIGNFLG

        lda FMT_VAL
        eor #$FF
        sta FMT_VAL
        lda FMT_VAL+1
        eor #$FF
        sta FMT_VAL+1
        lda FMT_VAL+2
        eor #$FF
        sta FMT_VAL+2
        lda FMT_VAL+3
        eor #$FF
        sta FMT_VAL+3

        inc FMT_VAL
        bne @FormatCore
        inc FMT_VAL+1
        bne @FormatCore
        inc FMT_VAL+2
        bne @FormatCore
        inc FMT_VAL+3

@FormatCore:
        ; Put space (' ') for positive, minus ('-') for negative at index 0
        lda FMT_SIGNFLG
        bne @StoreMinus
        lda #' '
        jmp @WriteSign
@StoreMinus:
        lda #'-'
@WriteSign:
        sta FIX_STRING_BUF

        lda FMT_VAL+2
        sta TEMP16
        lda FMT_VAL+3
        sta TEMP16+1

        ldx FMT_INTOFF
        jsr U16_TO_4_ASCII

        ldx FMT_INTOFF
        inx
        inx
        inx
        inx
        lda #$2E
        sta FIX_STRING_BUF,x

        lda FMT_VAL
        sta SCRATCH_FRAC
        lda FMT_VAL+1
        sta SCRATCH_FRAC+1

        MULT16I 10000, SCRATCH_FRAC, TEMP_PROD32

        lda TEMP_PROD32+2
        sta TEMP16
        lda TEMP_PROD32+3
        sta TEMP16+1

        ldx FMT_FRACOFF
        jsr U16_TO_4_ASCII

        lda TEMP_PROD32
        sta SCRATCH_FRAC
        lda TEMP_PROD32+1
        sta SCRATCH_FRAC+1

        MULT16I 10, SCRATCH_FRAC, TEMP_PROD32

        lda TEMP_PROD32+2
        clc
        adc #$30
        ldx FMT_DIG5IDX
        sta FIX_STRING_BUF,x

        lda #0
        ldx FMT_NULLIDX
        sta FIX_STRING_BUF,x
        rts
        
; ====================================================
; U16_TO_4_ASCII
; ====================================================
U16_TO_4_ASCII:
        ldy #$30
@Thousands:
        sec
        lda TEMP16
        sbc #<1000
        sta TEMP16
        lda TEMP16+1
        sbc #>1000
        sta TEMP16+1
        bcc @ThousandsDone
        iny
        jmp @Thousands

@ThousandsDone:
        clc
        lda TEMP16
        adc #<1000
        sta TEMP16
        lda TEMP16+1
        adc #>1000
        sta TEMP16+1
        tya
        sta FIX_STRING_BUF,x
        inx

        ldy #$30
@Hundreds:
        sec
        lda TEMP16
        sbc #<100
        sta TEMP16
        lda TEMP16+1
        sbc #>100
        sta TEMP16+1
        bcc @HundredsDone
        iny
        jmp @Hundreds

@HundredsDone:
        clc
        lda TEMP16
        adc #<100
        sta TEMP16
        lda TEMP16+1
        adc #>100
        sta TEMP16+1
        tya
        sta FIX_STRING_BUF,x
        inx

        ldy #$30
@Tens:
        sec
        lda TEMP16
        sbc #10
        sta TEMP16
        lda TEMP16+1
        sbc #0
        sta TEMP16+1
        bcc @TensDone
        iny
        jmp @Tens

@TensDone:
        clc
        lda TEMP16
        adc #10
        sta TEMP16
        lda TEMP16+1
        adc #0
        sta TEMP16+1
        tya
        sta FIX_STRING_BUF,x
        inx

        lda TEMP16
        clc
        adc #$30
        sta FIX_STRING_BUF,x
        rts
        
; ====================================================
; DisplayResults (Multi-Vector Loop Fixed)
; ====================================================
DisplayResults:
        lda #0
        sta @CUR_VEC
        sta @PRINT_COL
        
@Vec_Loop:
        ldx ROW
        ldy #0
        clc
        jsr PLOT

        ; Dynamically set vector letter ('A', 'B', 'C') based on @CUR_VEC index
        lda @CUR_VEC
        clc
        adc #'C'
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
   
        ldy @PRINT_COL
        beq @continue

        inc ROW
        ldx ROW
        clc
        jsr PLOT
        
        ldy #0
        jmp @incPtr

 @continue           
        lda #<@SPC
        ldy #>@SPC
        jsr STROUT      
        ldy @PRINT_COL
        iny

@incPtr        
        sty @PRINT_COL

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
        beq @exit
        jmp @Vec_Loop
@exit        
        rts

@CUR_VEC
        .byte 0       
@VEC_CUR_ROW
        .byte 0
@VEC_CUR_COL
        .byte 0

@PRINT_COL .byte 0
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
        