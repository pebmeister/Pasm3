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
; DisplayResults
;
; Displays one or more FIX16 arrays as rows/columns.
;
; Input:
;   FIXPTR          = address of first FIX16 value
;   DISPLAY_ROWS    = number of rows
;   DISPLAY_COLS    = number of columns
;   DISPLAY_VECTORS = number of arrays to display
;
; Each array contains ROWS * COLS FIX16 values.
; Each FIX16 value occupies 4 bytes.
;
; FIXPTR is preserved.
; ====================================================

DisplayResults:

        ; Preserve master pointer
        lda FIXPTR
        sta @CurrPtr
        lda FIXPTR+1
        sta @CurrPtr+1

        lda #0
        sta @VectorCnt
        sta @RowCnt
        sta @ColCnt
        sta @ScrRow

@VectorLoop:

        lda #0
        sta @RowCnt

@RowLoop:

        ; Position cursor
        ldx @ScrRow
        ldy #2
        clc
        jsr PLOT

        lda #0
        sta @ColCnt

@ColLoop:

        ; Point FIXPTR at current value
        lda @CurrPtr
        sta FIXPTR
        lda @CurrPtr+1
        sta FIXPTR+1

        ; Format and print FIX16
        jsr FORMAT_FIX16

        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr SAFE_STROUT

        ; Advance to next FIX16 value
        ADD16I @CurrPtr, 4, @CurrPtr

        ; Advance column
        inc @ColCnt
        lda @ColCnt
        cmp DISPLAY_COLS
        beq @RowDone

        ; Print separator
        lda #<@SPC
        ldy #>@SPC
        jsr SAFE_STROUT

        jmp @ColLoop

@RowDone:

        ; Advance screen row
        inc @ScrRow

        ; Next row?
        inc @RowCnt
        lda @RowCnt
        cmp DISPLAY_ROWS
        beq @VectorDone

        jmp @RowLoop

@VectorDone:

        ; Next vector?
        inc @VectorCnt
        lda @VectorCnt
        cmp DISPLAY_VECTORS
        beq @Done

        ; Blank line between vectors
        inc @ScrRow

        jmp @VectorLoop

@Done:
        rts

; Local variables
@CurrPtr:    .ds 2
@VectorCnt:  .byte 0
@RowCnt:     .byte 0
@ColCnt:     .byte 0
@ScrRow:     .byte 0
@SPC:        .byte " ", 0


; ====================================================
; CLEARSCREEN
; ====================================================
CLEARSCREEN:
        lda #<@CLS
        ldy #>@CLS
        jsr SAFE_STROUT
        rts

@CLS      .byte 147, 5, 0
