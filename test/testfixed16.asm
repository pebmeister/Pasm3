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
               
Calculate_Add
        MOVE16I VAR_A, 100
        MOVE16I VAR_A + 2, 100        
        MOVE16I VAR_B, 200
        MOVE16I VAR_B + 2, 200        
        ADDFIX16 VAR_A, VAR_B, VAR_C
        lda #'+'
        sta Op + 1
        rts

Calculate_Sub
        MOVE16I VAR_A, 300
        MOVE16I VAR_A + 2, 300        
        MOVE16I VAR_B, 200
        MOVE16I VAR_B + 2, 200        
        SUBFIX16 VAR_A, VAR_B, VAR_C
        lda #'-'
        sta Op + 1
        rts

Calculate_Mul:
        ; VAR_A = 12.34567 approximately
        MOVE16I VAR_A, 22654
        MOVE16I VAR_A + 2, 12

        ; VAR_B = 23.45678 approximately
        MOVE16I VAR_B, 29999
        MOVE16I VAR_B + 2, 23

        FIX16_MUL VAR_A, VAR_B, VAR_C

        lda #'*'
        sta Op + 1
        rts

Calculate_Div:
        ; VAR_A = 1.0
        MOVE16I VAR_A, 0
        MOVE16I VAR_A + 2, 1

        ; VAR_B = 3.0
        MOVE16I VAR_B, 0
        MOVE16I VAR_B + 2, 3

        FIX16_DIV VAR_A, VAR_B, VAR_C

        lda #'/'
        sta Op + 1
        rts
        
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
        jsr PRINT_FIX16         ; Populates FIX_STRING_BUF
        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr STROUT              ; Print VAR_A

        ; --- Print " + " ---
        lda #<Op
        ldy #>Op
        jsr STROUT

        ; --- Print VAR_B ---
        lda #<VAR_B
        sta FIXPTR
        lda #>VAR_B
        sta FIXPTR + 1
        jsr PRINT_FIX16         ; Populates FIX_STRING_BUF
        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr STROUT              ; Print VAR_B

        ; --- Print " = " ---
        lda #<Equals
        ldy #>Equals
        jsr STROUT

        ; --- Print VAR_C (Result) ---
        lda #<VAR_C
        sta FIXPTR
        lda #>VAR_C
        sta FIXPTR + 1
        jsr PRINT_FIX16         ; Populates FIX_STRING_BUF
        lda #<FIX_STRING_BUF
        ldy #>FIX_STRING_BUF
        jsr STROUT              ; Print VAR_C
        rts

Cls    .byte 147, 5, 0
Op     .byte "   ", 0
Equals .byte " = ", 0


PRINT_FIX16:
        ; Convert integer word (bytes 2 and 3)
        ldy #2
        lda (FIXPTR),y
        sta TEMP16
        iny
        lda (FIXPTR),y
        sta TEMP16+1

        ldx #0
        jsr U16_TO_4_ASCII

        ; Decimal point
        lda #$2E
        sta FIX_STRING_BUF+4

        ; Read fractional word (bytes 0 and 1)
        ldy #0
        lda (FIXPTR),y
        sta SCRATCH_FRAC
        iny
        lda (FIXPTR),y
        sta SCRATCH_FRAC+1

        ; Multiply fraction by 10000
        MULT16I 10000, SCRATCH_FRAC, TEMP_PROD32

        ; First four fractional digits
        lda TEMP_PROD32+2
        sta TEMP16
        lda TEMP_PROD32+3
        sta TEMP16+1

        ldx #5
        jsr U16_TO_4_ASCII

        ; Fifth digit:
        ; The low word is the remainder of
        ; (fraction * 10000) / 65536.
        ;
        ; Multiply that remainder by 10.
        lda TEMP_PROD32
        sta SCRATCH_FRAC
        lda TEMP_PROD32+1
        sta SCRATCH_FRAC+1

        MULT16I 10, SCRATCH_FRAC, TEMP_PROD32

        ; Upper word is the fifth decimal digit
        lda TEMP_PROD32+2
        clc
        adc #$30
        sta FIX_STRING_BUF+9

        ; Null terminator
        lda #0
        sta FIX_STRING_BUF+10
        rts



;********************************************
;* PRINT_4_FIX16                              *
;*                                          *
;* Input:  FIXPTR -> unsigned 16.16 value   *
;* Output: FIX_STRING_BUF = "nnnn.nnnn",0   *
;*                                          *
;* Destroys A, X, Y, TEMP16, SCRATCH_FRAC,  *
;* TEMP_PROD32                              *
;********************************************

PRINT_1_FIX16:
        ; Convert integer word (bytes 2 and 3)
        ldy #2
        lda (FIXPTR),y
        sta TEMP16
        iny
        lda (FIXPTR),y
        sta TEMP16+1

        ldx #0
        jsr U16_TO_4_ASCII

        ; Decimal point
        lda #$2E
        sta FIX_STRING_BUF+4

        ; Read fractional word (bytes 0 and 1)
        ldy #0
        lda (FIXPTR),y
        sta SCRATCH_FRAC
        iny
        lda (FIXPTR),y
        sta SCRATCH_FRAC+1

        ; fraction * 10000
        MULT16I 10000, SCRATCH_FRAC, TEMP_PROD32

        ; Upper 16 bits = floor(fraction * 10000 / 65536)
        lda TEMP_PROD32+2
        sta TEMP16
        lda TEMP_PROD32+3
        sta TEMP16+1

        ldx #5
        jsr U16_TO_4_ASCII

        ; Null terminator
        lda #0
        sta FIX_STRING_BUF+9
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
        .ds 20                  ; Reserves 20 bytes: nnnn . nnnn \0        
