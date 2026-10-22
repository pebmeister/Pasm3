        .inc "basic.asm"
        .inc "kernal.asm"
        .inc "macros.asm"
        .inc "pagezero.asm"
        
        VAR_A           = $80   ; $80-$83 (4 bytes)
        VAR_B           = $84   ; $84-$87 (4 bytes)
        VAR_C           = $88   ; $88-$8B (4 bytes)
        TEMP16          = $8C   ; $8C-$8D (2 bytes)
        SCRATCH_FRAC    = $8E   ; $8E-$8F (2 bytes)
        TEMP_PROD32     = $90   ; $90-$93 (4 bytes)
        BCD_TEMP        = $94   ; $94 (1 byte)
        SCRATCH_INT     = $95   ; $95 (1 byte)
        FIXPTR          = $96   ; $96-$97 (2 bytes)
        FIX_BUFFER_FRAC = $98   ; $98 (1 byte)
        
        
        ROW             = $FB
        
        .basic_hdr

        lda #<Cls
        ldy #>Cls
        jsr STROUT              ; Clear screen    
    
        lda #0
        sta ROW

        jsr Calculate_Add
        jsr DisplayResults
        inc ROW

        jsr Calculate_Sub
        jsr DisplayResults
        inc ROW
        
        jsr Calculate_Mul
        jsr DisplayResults
        inc ROW
        
        jsr Calculate_Div
        jsr DisplayResults
        inc ROW
        
@Wait
        jmp @Wait
               
; ====================================================
;
; Calculate_Add
;
; ====================================================

Calculate_Add
        MOVE16I VAR_A, 100
        MOVE16I VAR_A + 2, 100        
        MOVE16I VAR_B, 200
        MOVE16I VAR_B + 2, 200        
        ADD_FIX16 VAR_A, VAR_B, VAR_C
        lda #'+'
        sta Op + 1
        rts

; ====================================================
;
; Calculate_Sub
;
; ====================================================
Calculate_Sub
        MOVE16I VAR_A, 300
        MOVE16I VAR_A + 2, 300        
        MOVE16I VAR_B, 200
        MOVE16I VAR_B + 2, 200        
        SUB_FIX16 VAR_A, VAR_B, VAR_C
        lda #'-'
        sta Op + 1
        rts

; ====================================================
;
; Calculate_Mul
;
; ====================================================
Calculate_1_Mul:
        ; VAR_A = 12.34567 approximately
        MOVE16I VAR_A, 22654
        MOVE16I VAR_A + 2, 12

        ; VAR_B = 23.45678 approximately
        MOVE16I VAR_B, 29999
        MOVE16I VAR_B + 2, 23

        MUL_FIX16 VAR_A, VAR_B, VAR_C

        lda #'*'
        sta Op + 1
        rts

; ====================================================
; Calculate_Mul (Signed Test: -2.5 * 4.0 = -10.0)
; ====================================================
Calculate_Mul:
        ; VAR_A = -2.5
        ; Integer part: -3 ($FFFD), Fractional part: 0.5 ($8000)
        MOVE16I VAR_A, $8000
        MOVE16I VAR_A + 2, $FFFD

        ; VAR_B = 4.0 (Positive)
        MOVE16I VAR_B, 0
        MOVE16I VAR_B + 2, 4

        ; Calculate: VAR_C = VAR_A * VAR_B (-10.00000)
        MUL_FIX16 VAR_A, VAR_B, VAR_C

        lda #'*'
        sta Op + 1
        rts
        
; ====================================================
;
; Calculate_Div
;
; ====================================================
Calculate_Div:
        ; VAR_A = 1.0
        MOVE16I VAR_A, 0
        MOVE16I VAR_A + 2, 1

        ; VAR_B = 3.0
        MOVE16I VAR_B, 0
        MOVE16I VAR_B + 2, 3

        ; DIV_MY_FIX16 VAR_A, VAR_B, VAR_C
        DIV_FIX16 VAR_A, VAR_B, VAR_C, DIV_SCRATCH

        lda #'/'
        sta Op + 1
        rts
        
; ====================================================
;
; DisplayResults
;
; ====================================================
DisplayResults:
        ldx ROW
        ldy #0
        clc
        jsr PLOT

        ; --- Print VAR_A ---
        lda #<VAR_A
        sta FIXPTR
        lda #>VAR_A
        sta FIXPTR + 1
        jsr FORMAT_FIX16            ; Populates FIX_STRING_BUF
        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr STROUT                  ; Print VAR_A

        ; --- Print " + " ---
        lda #<Op
        ldy #>Op
        jsr STROUT

        ; --- Print VAR_B ---
        lda #<VAR_B
        sta FIXPTR
        lda #>VAR_B
        sta FIXPTR + 1
        jsr FORMAT_FIX16            ; Populates FIX_STRING_BUF
        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr STROUT                  ; Print VAR_B

        ; --- Print " = " ---
        lda #<Equals
        ldy #>Equals
        jsr STROUT

        ; --- Print VAR_C (Result) ---
        lda #<VAR_C
        sta FIXPTR
        lda #>VAR_C
        sta FIXPTR + 1
        jsr FORMAT_FIX16            ; Populates FIX_STRING_BUF
        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr STROUT                  ; Print VAR_C
        rts

; ====================================================
; FORMAT_FIX16 (Signed Support Added)
; ====================================================

; Map local formatting workspace aliases to DIV_SCRATCH bytes
FMT_VAL     = DIV_SCRATCH       ; 4 bytes: Working copy for conversion
FMT_INTOFF  = DIV_SCRATCH+4     ; 1 byte: Integer string offset (0 or 1)
FMT_FRACOFF = DIV_SCRATCH+5     ; 1 byte: Fractional string offset (5 or 6)
FMT_DIG5IDX = DIV_SCRATCH+6     ; 1 byte: 5th digit string index (9 or 10)
FMT_NULLIDX = DIV_SCRATCH+7     ; 1 byte: Null terminator index (10 or 11)
FMT_SIGNFLG = DIV_SCRATCH+8     ; 1 byte: Sign flag (0 = positive, 1 = negative)

FORMAT_FIX16:
        ; Copy 4-byte fixed point value from (FIXPTR) to working buffer
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

        ; Check sign bit (bit 7 of highest byte)
        lda FMT_VAL+3
        bmi @NegativeNumber

        ; --- POSITIVE NUMBER CONFIG ---
        lda #0
        sta FMT_INTOFF
        lda #5
        sta FMT_FRACOFF
        lda #9
        sta FMT_DIG5IDX
        lda #10
        sta FMT_NULLIDX
        lda #0
        sta FMT_SIGNFLG
        jmp @FormatCore

@NegativeNumber:
        ; --- NEGATIVE NUMBER CONFIG ---
        lda #1
        sta FMT_INTOFF
        lda #6
        sta FMT_FRACOFF
        lda #10
        sta FMT_DIG5IDX
        lda #11
        sta FMT_NULLIDX
        lda #1
        sta FMT_SIGNFLG

        ; Negate FMT_VAL (Two's complement: invert all bits and add 1)
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
        ; If negative, put '-' at the very beginning of the string buffer
        lda FMT_SIGNFLG
        beq @SkipSign
        lda #'-'
        sta FIX_STRING_BUF
@SkipSign:

        ; Convert integer word (bytes 2 and 3 of FMT_VAL)
        lda FMT_VAL+2
        sta TEMP16
        lda FMT_VAL+3
        sta TEMP16+1

        ldx FMT_INTOFF
        jsr U16_TO_4_ASCII

        ; Decimal point (always 4 positions after integer start)
        ldx FMT_INTOFF
        inx
        inx
        inx
        inx
        lda #$2E        ; ASCII '.'
        sta FIX_STRING_BUF,x

        ; Read fractional word (bytes 0 and 1 of FMT_VAL)
        lda FMT_VAL
        sta SCRATCH_FRAC
        lda FMT_VAL+1
        sta SCRATCH_FRAC+1

        ; Multiply fraction by 10000
        MULT16I 10000, SCRATCH_FRAC, TEMP_PROD32

        ; First four fractional digits
        lda TEMP_PROD32+2
        sta TEMP16
        lda TEMP_PROD32+3
        sta TEMP16+1

        ldx FMT_FRACOFF
        jsr U16_TO_4_ASCII

        ; Fifth digit: remainder * 10
        lda TEMP_PROD32
        sta SCRATCH_FRAC
        lda TEMP_PROD32+1
        sta SCRATCH_FRAC+1

        MULT16I 10, SCRATCH_FRAC, TEMP_PROD32

        ; Upper word is the fifth decimal digit
        lda TEMP_PROD32+2
        clc
        adc #$30
        ldx FMT_DIG5IDX
        sta FIX_STRING_BUF,x

        ; Null terminator
        lda #0
        ldx FMT_NULLIDX
        sta FIX_STRING_BUF,x
        rts
        


;********************************************
;* U16_TO_4_ASCII                           *
;*                                          *
;* Input: TEMP16 = unsigned 16-bit value    *
;*        X = starting buffer offset        *
;* Output: four ASCII decimal digits        *
;*                                          *
;* Value must be in range 0..9999           *
;********************************************

U16_TO_4_ASCII:
        ; Thousands
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

        ; Hundreds
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

        ; Tens
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

        ; Ones (remaining value is 0..9)
        lda TEMP16
        clc
        adc #$30
        sta FIX_STRING_BUF,x
        rts
        
; ========================================
; String Buffer Declaration
; ========================================
FIX_STRING_BUF:
        .ds 20          ; Reserves 20 bytes: nnnn . nnnn \0        
DIV_SCRATCH  
        .ds 18          ; (18 bytes)

Cls    .byte 147, 5, 0
Op     .byte "   ", 0
Equals .byte " = ", 0
