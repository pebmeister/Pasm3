; ====================================================
; SAFE_STROUT (KERNAL-Backed Drop-in Replacement)
; ROM $AB1E so all existing jsr STROUT calls 
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
;
; IN: FIXPTR  Pointer to fix16 value
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
        sta STRING_BUF

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
        sta STRING_BUF,x

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
        sta STRING_BUF,x

        lda #0
        ldx FMT_NULLIDX
        sta STRING_BUF,x
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
        sta STRING_BUF,x
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
        sta STRING_BUF,x
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
        sta STRING_BUF,x
        inx

        lda TEMP16
        clc
        adc #$30
        sta STRING_BUF,x
        rts

; ====================================================
; CLEARSCREEN
; ====================================================
CLEARSCREEN:
        lda #<@CLS
        ldy #>@CLS
        jsr SAFE_STROUT
        rts
@CLS:   .byte 147, 0

PRINT_SP    
        lda #<@SPC
        ldy #>@SPC
        jsr SAFE_STROUT
        rts
@SPC:        .byte " ", 0
        
; ============================================
; PRINT_INT16
; Input: TEMP16 = unsigned 16-bit integer
; Output: Decimal ASCII via SAFE_STROUT
; Preserves TEMP16
; ============================================

PRINT_INT16:
        lda #0
        sta @INT_LEADING_FLAG

        ldx #0
        ldy #0

@DigitLoop:
        lda #$30
        sta @INT_DIGIT_CHAR

@Subtract:
        sec
        lda TEMP16
        sbc @POWER10_L,x
        sta @INT_TEMP
        lda TEMP16+1
        sbc @POWER10_H,x
        bcc @DigitDone

        sta TEMP16+1
        lda @INT_TEMP
        sta TEMP16
        inc @INT_DIGIT_CHAR
        jmp @Subtract

@DigitDone:
        lda @INT_DIGIT_CHAR
        cmp #$30
        bne @OutputDigit

        lda @INT_LEADING_FLAG
        bne @OutputDigit

        cpx #4
        beq @OutputDigit
        jmp @NextDigit

@OutputDigit:
        lda #1
        sta @INT_LEADING_FLAG

        lda @INT_DIGIT_CHAR
        sta STRING_BUF,y
        iny

@NextDigit:
        inx
        cpx #5
        bne @DigitLoop

        lda #0
        sta STRING_BUF,y

        lda #<STRING_BUF
        ldy #>STRING_BUF
        jsr SAFE_STROUT
        rts

; ============================================
; Variables
; ============================================
@INT_LEADING_FLAG    .ds 1
@INT_DIGIT_CHAR      .ds 1
@INT_TEMP            .ds 1

@POWER10_L:
        .byte <10000, <1000, <100, <10, <1

@POWER10_H:
        .byte >10000, >1000, >100, >10, >1
       
; ============================================
; PRINT_INT16_HEX
; Input: TEMP16 = unsigned 16-bit integer
; Output: $0000-$FFFF via SAFE_STROUT
; Preserves TEMP16
; ============================================

PRINT_INT16_HEX:
        ldy #0

        ; Print '$' prefix
        lda #'$'
        sta STRING_BUF,y
        iny

        ; High byte first
        lda TEMP16+1
        lsr
        lsr
        lsr
        lsr
        jsr @PrintNibble

        lda TEMP16+1
        and #$0F
        jsr @PrintNibble

        ; Low byte
        lda TEMP16
        lsr
        lsr
        lsr
        lsr
        jsr @PrintNibble

        lda TEMP16
        and #$0F
        jsr @PrintNibble

        lda #0
        sta STRING_BUF,y

        lda #<STRING_BUF
        ldy #>STRING_BUF
        jsr SAFE_STROUT
        rts

@PrintNibble:
        cmp #10
        bcc @HexDigit

        clc
        adc #('A' - 10)
        bne @StoreDigit

@HexDigit:
        clc
        adc #'0'

@StoreDigit:
        sta STRING_BUF,y
        iny
        rts
        
; ============================================
; PRINT_FIX16
; IN: FIXPTR - Pointer to 16.16 fixed-point value
; ============================================      
PRINT_FIX16:
        
        jsr FORMAT_FIX16
        jsr TRIM_FIX_STRING
        lda #<STRING_BUF
        ldy #>STRING_BUF
        jsr SAFE_STROUT
        rts

;********************************************
;* TRIM_FIX_STRING                          *
;*                                          *
;* Remove leading space, leading integer    *
;* zeroes and trailing fractional zeroes.   *
;* Preserve negative sign.                 *
;********************************************
TRIM_FIX_STRING

        ;------------------------------------
        ; Skip leading space
        ;------------------------------------
        ldx #0
        lda STRING_BUF
        cmp #' '
        bne @CheckSign
        inx

@CheckSign
        ; Preserve minus sign
        lda STRING_BUF,x
        cmp #'-'
        bne @FindInteger
        inx

@FindInteger
        ;------------------------------------
        ; Skip leading integer zeroes.
        ; Keep at least one integer digit.
        ;------------------------------------
        lda STRING_BUF,x
        cmp #'0'
        bne @IntegerFound

        lda STRING_BUF + 1,x
        cmp #'.'
        beq @IntegerFound

        inx
        jmp @FindInteger

@IntegerFound
        stx TMP

        ;------------------------------------
        ; Shift remaining string to start
        ;------------------------------------
        ldy #0
        ldx TMP

@Shift
        lda STRING_BUF,x
        sta STRING_BUF,y
        inx
        iny
        cmp #0
        bne @Shift

        ;------------------------------------
        ; Find end of string
        ;------------------------------------
        dey
        tya
        tax

        ;------------------------------------
        ; Trim trailing fractional zeroes
        ;------------------------------------
@TrimFraction
        dex
        lda STRING_BUF,x
        cmp #'0'
        beq @TrimFraction

        ; Remove decimal point if last
        cmp #'.'
        bne @Terminate
        dex

@Terminate
        inx
        lda #0
        sta STRING_BUF,x
        rts
        