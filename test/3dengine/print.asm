; ====================================================
; SAFE_STROUT (KERNAL-Backed Drop-in Replacement)
; Overrides ROM $AB1E so all existing jsr STROUT calls 
; safely print null-terminated strings via KERNAL $FFEE.
; ====================================================
SAFE_STROUT:
        sta STR_PTR
        sty STR_PTR+1
        ldy #0
@PrintLoop:
        lda (STR_PTR),y
        beq @Done
        jsr CHROUT       ; KERNAL CHROUT prints character/control code
        iny
        bne @PrintLoop
@Done:
        rts
        
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
; DisplayResults (C64 40-Column Wrapped Grid Printer)
; All internal state and strings scoped as local labels
; ====================================================
; ====================================================
; DisplayResults (C64 40-Column Wrapped Grid Printer)
; Uses a local pointer copy so FIXPTR is never mutated
; ====================================================
DisplayResults:
        ; Copy master FIXPTR to local working pointers (@CurrPtr)
        lda FIXPTR
        sta @CurrPtr
        lda FIXPTR+1
        sta @CurrPtr+1

        lda #0
        sta @RowCnt

@MatrixRowLoop:
        lda @RowCnt
        asl
        clc
        adc #3
        sta @ScrRow

        ; --- PART A: Print Columns 0 & 1 on Screen Line N ---
        ldx @ScrRow
        ldy #2
        clc
        jsr PLOT

        lda #0
        sta @ColCnt
@SubColLoop1:
        ; Temporarily point FIXPTR to our walking @CurrPtr for FORMAT_FIX16
        lda @CurrPtr
        sta FIXPTR
        lda @CurrPtr+1
        sta FIXPTR+1

        jsr FORMAT_FIX16

        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr SAFE_STROUT

        lda #<@SPC
        ldy #>@SPC
        jsr SAFE_STROUT

        ; Advance local working pointer by 4 bytes (leaves master FIXPTR safe)
        ADD16I @CurrPtr, 4, @CurrPtr

        inc @ColCnt
        lda @ColCnt
        cmp #2
        bne @SubColLoop1

        ; --- PART B: Print Columns 2 & 3 on Screen Line N + 1 ---
        lda @ScrRow
        clc
        adc #1
        tax
        ldy #2
        clc
        jsr PLOT

        lda #2
        sta @ColCnt
@SubColLoop2:
        lda @CurrPtr
        sta FIXPTR
        lda @CurrPtr+1
        sta FIXPTR+1

        jsr FORMAT_FIX16

        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr SAFE_STROUT

        lda #<@SPC
        ldy #>@SPC
        jsr SAFE_STROUT

        ADD16I @CurrPtr, 4, @CurrPtr

        inc @ColCnt
        lda @ColCnt
        cmp #4
        bne @SubColLoop2

        inc @RowCnt
        lda @RowCnt
        cmp #4
        bne @MatrixRowLoop
        rts

; Local state variables
@RowCnt   .byte 0
@ColCnt   .byte 0
@ScrRow   .byte 0
@CurrPtr  .ds 2       ; Local pointer copy protecting master FIXPTR
@SPC      .byte "  ", 0

; ====================================================
; CLEARSCREEN
; ====================================================
CLEARSCREEN:
        lda #<@CLS
        ldy #>@CLS
        jsr SAFE_STROUT
        rts

@CLS      .byte 147, 5, 0
