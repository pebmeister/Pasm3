        .inc "basic.asm"
        .inc "kernal.asm"
        .inc "macros.asm"
        .inc "pagezero.asm"
        
; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================
        .basic_hdr
       
        jsr ClearScreen
        jsr RunMatrixTest       ; <--- Run the math first!
        jsr DisplayResults      ; <--- Then print everything
       
@wait
        jmp @wait
        

; ====================================================
; Safe Zero-Page Pointers (Free from ROM/BASIC collision)
; ====================================================
FIXPTR          = $FB       ; 2 bytes ($FB-$FC)
TEMP_PTR        = $FD       ; 2 bytes ($FD-$FE)

PTR_A           = $82
PTR_B           = $84
PTR_C           = $86

VAR_A           .ds 4
VAR_B           .ds 4
VAR_C           .ds 4

TEMP16          .ds 2
SCRATCH_FRAC    .ds 2
FMT_VAL         .ds 4
FMT_INTOFF      .ds 1
FMT_FRACOFF     .ds 1
FMT_DIG5IDX     .ds 1
FMT_NULLIDX     .ds 1
FMT_SIGNFLG     .ds 1
TEMP_PROD32     .ds 4
ROW_INDEX       .ds 1
PTR_MAT_A       .ds 2
PTR_MAT_B       .ds 2
PTR_MAT_C       .ds 2
MAT_K           .ds 1
MAT_M           .ds 1
MAT_N           .ds 1
DOT_LEN         .ds 1
DOT_RESULT      .ds 4
ROW             .byte 1

FIX_STRING_BUF  .ds 20      
Cls             .byte 147,0


; ====================================================
; FORMAT_FIX16 Routine
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

        lda FMT_VAL+3
        bmi @NegativeNumber

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
        lda FMT_SIGNFLG
        beq @SkipSign
        lda #'-'
        sta FIX_STRING_BUF
@SkipSign:

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

; ====================================================
; Test Data & Constants
; ====================================================
TestMatrixA:
        .word $0000, $0002,  $0000, $0000,  $0000, $0000
        .word $0000, $0000,  $0000, $0002,  $0000, $0000
        .word $0000, $0000,  $0000, $0000,  $0000, $0002

TestVectorB:
        .word $8000, $0001   ; 1.5
        .word $0000, $0002   ; 2.0
        .word $0000, $FFFE   ; -1.0

ResultVectorC:
        .ds 12              ; Space for 3 output 16.16 values

; ====================================================
; DisplayResults (Multi-Vector Loop Fixed)
; ====================================================
DisplayResults:
        lda #0
        sta @CUR_VEC

        ; Start pointer at Matrix A
        lda #<TestMatrixA
        sta FIXPTR
        lda #>TestMatrixA
        sta FIXPTR + 1

@Vec_Loop:
        ldx ROW
        ldy #0
        clc
        jsr PLOT

        ; Dynamically set vector letter ('A', 'B', 'C') based on @CUR_VEC index
        lda @CUR_VEC
        clc
        adc #'A'
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
        
        lda #<@SPC
        ldy #>@SPC
        jsr STROUT

        ; Advance pointer by 4 bytes for next element
        ADD16I FIXPTR, 4, FIXPTR
        
        inc @VEC_CUR_COL
        ldx @CUR_VEC
        lda @VEC_CUR_COL
        cmp @VEC_COLS,x
        bne @Vec_Col_Loop

        inc @VEC_CUR_ROW
        ldx @CUR_VEC
        lda @VEC_CUR_ROW
        cmp @VEC_ROWS,x
        bne @Vec_Row_Loop
       
        ADD8I ROW,2,ROW
        inc @CUR_VEC
        lda @CUR_VEC
        cmp #3
        bne @Vec_Loop
        
        rts

@CUR_VEC
        .byte 0        
@VEC_CUR_ROW
        .byte 0
@VEC_CUR_COL
        .byte 0

; Correct dimensions: Matrix A (3x3), Vector B (3x1), Result C (3x1)
@VEC_ROWS    
        .byte 3, 3, 3
@VEC_COLS
        .byte 3, 1, 1
        
@MESSAGE
        .byte 05, "VECTOR "
@VEC_NUM
        .byte "A", 0
@SPC    .byte " ", 0


CLEARSCREEN:
        lda #<Cls
        ldy #>Cls
        jsr STROUT              ; Clear screen    

        rts
 
RunMatrixTest:
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
        rts