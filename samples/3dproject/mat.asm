
;********************************************
;* MAT4_MUL                                 *
;* Subroutine: R = A * B (4x4 Fix16)        *
;* IN: MAT_A_PTR, MAT_B_PTR, MAT_R_PTR      *
;********************************************
MAT4_MUL
        ; Clear all 64 bytes of result matrix R
        lda MAT_R_PTR
        sta CUR_R_PTR
        lda MAT_R_PTR + 1
        sta CUR_R_PTR + 1

        ldx #0
        lda #0
@ClearLoop
        ldy #0
        sta (CUR_R_PTR),y
        INC16 CUR_R_PTR
        inx
        cpx #64
        bne @ClearLoop

        ; i = 0..3
        lda #0
        sta @IDX_I

@LoopI
        ; j = 0..3
        lda #0
        sta @IDX_J

@LoopJ
        ; CUR_R_PTR = MAT_R_PTR + ((@IDX_I * 4 + @IDX_J) * 4)
        lda @IDX_I
        asl
        asl
        clc
        adc @IDX_J
        asl
        asl
        clc
        adc MAT_R_PTR
        sta CUR_R_PTR
        lda #0
        adc MAT_R_PTR + 1
        sta CUR_R_PTR + 1

        ; k = 0..3
        lda #0
        sta @IDX_K

@LoopK
        ; CUR_A_PTR = MAT_A_PTR + ((@IDX_I * 4 + @IDX_K) * 4)
        lda @IDX_I
        asl
        asl
        clc
        adc @IDX_K
        asl
        asl
        clc
        adc MAT_A_PTR
        sta CUR_A_PTR
        lda #0
        adc MAT_A_PTR + 1
        sta CUR_A_PTR + 1

        ; CUR_B_PTR = MAT_B_PTR + ((@IDX_K * 4 + @IDX_J) * 4)
        lda @IDX_K
        asl
        asl
        clc
        adc @IDX_J
        asl
        asl
        clc
        adc MAT_B_PTR
        sta CUR_B_PTR
        lda #0
        adc MAT_B_PTR + 1
        sta CUR_B_PTR + 1

        ; Load elements into direct buffers and multiply
        LOAD_FIX16_PTR CUR_A_PTR, @A_ELEM
        LOAD_FIX16_PTR CUR_B_PTR, @B_ELEM
        CALL_FIX16_MUL @A_ELEM, @B_ELEM, PROD

        ; Load current R[i][j], add PROD, and store back
        LOAD_FIX16_PTR CUR_R_PTR, @ACC_TMP
        ADD_FIX16 PROD, @ACC_TMP, @ACC_TMP
        STORE_FIX16_PTR @ACC_TMP, CUR_R_PTR

        inc @IDX_K
        lda @IDX_K
        cmp #4
        beq @LoopK_Exit
        jmp @LoopK
@LoopK_Exit
        inc @IDX_J
        lda @IDX_J
        cmp #4
        beq @LoopJ_Exit
        jmp @LoopJ
@LoopJ_Exit
        inc @IDX_I
        lda @IDX_I
        cmp #4
        beq @LoopI_Exit
        jmp @LoopI
@LoopI_Exit
        rts

@IDX_I          .ds 1
@IDX_J          .ds 1
@IDX_K          .ds 1
@A_ELEM         .ds 4
@B_ELEM         .ds 4
@ACC_TMP        .ds 4


        
;********************************************
;* FIX16_MUL
;*
;* Signed 16.16 fixed-point multiplication
;*
;* Inputs:
;*   FIX16_A_PTR      -> operand A (4 bytes)
;*   FIX16_B_PTR      -> operand B (4 bytes)
;*   FIX16_RESULT_PTR -> destination (4 bytes)
;*
;* Uses the original 32-iteration shift/add
;* algorithm.
;*
;* Source operands are preserved.
;********************************************

FIX16_MUL:
            ldx     #0
            lda     #0

            ; Copy operand A to working storage
            ldy     #0
            lda     (FIX16_A_PTR),y
            sta     FIX16_WORK_A
            iny
            lda     (FIX16_A_PTR),y
            sta     FIX16_WORK_A+1
            iny
            lda     (FIX16_A_PTR),y
            sta     FIX16_WORK_A+2
            iny
            lda     (FIX16_A_PTR),y
            sta     FIX16_WORK_A+3

            ; Copy operand B to working storage
            ldy     #0
            lda     (FIX16_B_PTR),y
            sta     FIX16_WORK_B
            iny
            lda     (FIX16_B_PTR),y
            sta     FIX16_WORK_B+1
            iny
            lda     (FIX16_B_PTR),y
            sta     FIX16_WORK_B+2
            iny
            lda     (FIX16_B_PTR),y
            sta     FIX16_WORK_B+3

            ; Determine result sign
            lda     #0
            sta     FIX16_SIGN

            ; If A is negative, negate working A
            lda     FIX16_WORK_A+3
            bpl     @F16M_CheckB

            inc     FIX16_SIGN

            lda     #0
            sec
            sbc     FIX16_WORK_A
            sta     FIX16_WORK_A
            lda     #0
            sbc     FIX16_WORK_A+1
            sta     FIX16_WORK_A+1
            lda     #0
            sbc     FIX16_WORK_A+2
            sta     FIX16_WORK_A+2
            lda     #0
            sbc     FIX16_WORK_A+3
            sta     FIX16_WORK_A+3

@F16M_CheckB:

            ; If B is negative, negate working B
            lda     FIX16_WORK_B+3
            bpl     @F16M_Start

            lda     FIX16_SIGN
            eor     #1
            sta     FIX16_SIGN

            lda     #0
            sec
            sbc     FIX16_WORK_B
            sta     FIX16_WORK_B
            lda     #0
            sbc     FIX16_WORK_B+1
            sta     FIX16_WORK_B+1
            lda     #0
            sbc     FIX16_WORK_B+2
            sta     FIX16_WORK_B+2
            lda     #0
            sbc     FIX16_WORK_B+3
            sta     FIX16_WORK_B+3

@F16M_Start:

            ; Clear product accumulator
            lda     #0
            sta     FIX16_WORK_RESULT
            sta     FIX16_WORK_RESULT+1
            sta     FIX16_WORK_RESULT+2
            sta     FIX16_WORK_RESULT+3

            ldx     #32

@F16M_MulLoop:

            ; Shift multiplier right.
            ; Carry indicates whether to add A.
            lda     FIX16_WORK_B
            lsr
            bcc     @F16M_NoAdd

            clc
            lda     FIX16_WORK_RESULT
            adc     FIX16_WORK_A
            sta     FIX16_WORK_RESULT
            lda     FIX16_WORK_RESULT+1
            adc     FIX16_WORK_A+1
            sta     FIX16_WORK_RESULT+1
            lda     FIX16_WORK_RESULT+2
            adc     FIX16_WORK_A+2
            sta     FIX16_WORK_RESULT+2
            lda     FIX16_WORK_RESULT+3
            adc     FIX16_WORK_A+3
            sta     FIX16_WORK_RESULT+3

@F16M_NoAdd:

            ; Shift combined 64-bit product/multiplier
            lsr     FIX16_WORK_RESULT+3
            ror     FIX16_WORK_RESULT+2
            ror     FIX16_WORK_RESULT+1
            ror     FIX16_WORK_RESULT
            ror     FIX16_WORK_B+3
            ror     FIX16_WORK_B+2
            ror     FIX16_WORK_B+1
            ror     FIX16_WORK_B

            dex
            bne     @F16M_MulLoop

            ; Extract the 16.16 result
            lda     FIX16_WORK_RESULT+1
            sta     FIX16_WORK_RESULT+3
            lda     FIX16_WORK_RESULT
            sta     FIX16_WORK_RESULT+2
            lda     FIX16_WORK_B+3
            sta     FIX16_WORK_RESULT+1
            lda     FIX16_WORK_B+2
            sta     FIX16_WORK_RESULT

            ; Negate result if signs differed
            lda     FIX16_SIGN
            beq     @F16M_StoreResult

            lda     #0
            sec
            sbc     FIX16_WORK_RESULT
            sta     FIX16_WORK_RESULT
            lda     #0
            sbc     FIX16_WORK_RESULT+1
            sta     FIX16_WORK_RESULT+1
            lda     #0
            sbc     FIX16_WORK_RESULT+2
            sta     FIX16_WORK_RESULT+2
            lda     #0
            sbc     FIX16_WORK_RESULT+3
            sta     FIX16_WORK_RESULT+3

@F16M_StoreResult:

            ; Copy result to caller's destination
            ldy     #0
            lda     FIX16_WORK_RESULT
            sta     (FIX16_RESULT_PTR),y
            iny
            lda     FIX16_WORK_RESULT+1
            sta     (FIX16_RESULT_PTR),y
            iny
            lda     FIX16_WORK_RESULT+2
            sta     (FIX16_RESULT_PTR),y
            iny
            lda     FIX16_WORK_RESULT+3
            sta     (FIX16_RESULT_PTR),y

            rts

;********************************************
;* FIX16_DIV                                *
;* Signed 16.16 division subroutine         *
;* IN:  FIX16_DIV_A_PTR, FIX16_DIV_B_PTR,   *
;*      FIX16_DIV_RES_PTR                   *
;* ZP:  FIX16_DIV_ZP (19 bytes)             *
;*      +0..3  working dividend / abs(A)    *
;*      +4..7  working divisor / abs(B)     *
;*      +8..12 5-byte remainder             *
;*      +13..16 32-bit quotient             *
;*      +17    incoming shifted bit         *
;*      +18    sign flag ($00 or $80)       *
;********************************************
FIX16_DIV
        lda #0
        sta FIX16_DIV_ZP + 18

        ; Load dividend into ZP +0..3 and take abs if negative
        ldy #0
        lda (FIX16_DIV_A_PTR),y
        sta FIX16_DIV_ZP
        iny
        lda (FIX16_DIV_A_PTR),y
        sta FIX16_DIV_ZP + 1
        iny
        lda (FIX16_DIV_A_PTR),y
        sta FIX16_DIV_ZP + 2
        iny
        lda (FIX16_DIV_A_PTR),y
        sta FIX16_DIV_ZP + 3
        bpl @AbsAPos

        lda #$80
        sta FIX16_DIV_ZP + 18

        sec
        lda #0
        sbc FIX16_DIV_ZP
        sta FIX16_DIV_ZP
        lda #0
        sbc FIX16_DIV_ZP + 1
        sta FIX16_DIV_ZP + 1
        lda #0
        sbc FIX16_DIV_ZP + 2
        sta FIX16_DIV_ZP + 2
        lda #0
        sbc FIX16_DIV_ZP + 3
        sta FIX16_DIV_ZP + 3

@AbsAPos
        ; Load divisor into ZP +4..7 and take abs if negative
        ldy #0
        lda (FIX16_DIV_B_PTR),y
        sta FIX16_DIV_ZP + 4
        iny
        lda (FIX16_DIV_B_PTR),y
        sta FIX16_DIV_ZP + 5
        iny
        lda (FIX16_DIV_B_PTR),y
        sta FIX16_DIV_ZP + 6
        iny
        lda (FIX16_DIV_B_PTR),y
        sta FIX16_DIV_ZP + 7
        bpl @AbsBPos

        lda FIX16_DIV_ZP + 18
        eor #$80
        sta FIX16_DIV_ZP + 18

        sec
        lda #0
        sbc FIX16_DIV_ZP + 4
        sta FIX16_DIV_ZP + 4
        lda #0
        sbc FIX16_DIV_ZP + 5
        sta FIX16_DIV_ZP + 5
        lda #0
        sbc FIX16_DIV_ZP + 6
        sta FIX16_DIV_ZP + 6
        lda #0
        sbc FIX16_DIV_ZP + 7
        sta FIX16_DIV_ZP + 7

@AbsBPos
        ; Division by zero check on magnitude of divisor
        lda FIX16_DIV_ZP + 4
        ora FIX16_DIV_ZP + 5
        ora FIX16_DIV_ZP + 6
        ora FIX16_DIV_ZP + 7
        bne @NotDiveZero
        jmp @DivZero
@NotDiveZero
        ; Clear 5-byte remainder (+8..12) and 32-bit quotient (+13..16)
        lda #0
        sta FIX16_DIV_ZP + 8
        sta FIX16_DIV_ZP + 9
        sta FIX16_DIV_ZP + 10
        sta FIX16_DIV_ZP + 11
        sta FIX16_DIV_ZP + 12
        sta FIX16_DIV_ZP + 13
        sta FIX16_DIV_ZP + 14
        sta FIX16_DIV_ZP + 15
        sta FIX16_DIV_ZP + 16

        ldx #48

@DivLoop
        asl FIX16_DIV_ZP
        rol FIX16_DIV_ZP + 1
        rol FIX16_DIV_ZP + 2
        rol FIX16_DIV_ZP + 3

        lda #0
        rol
        sta FIX16_DIV_ZP + 17

        asl FIX16_DIV_ZP + 13
        rol FIX16_DIV_ZP + 14
        rol FIX16_DIV_ZP + 15
        rol FIX16_DIV_ZP + 16

        asl FIX16_DIV_ZP + 8
        rol FIX16_DIV_ZP + 9
        rol FIX16_DIV_ZP + 10
        rol FIX16_DIV_ZP + 11
        rol FIX16_DIV_ZP + 12

        lda FIX16_DIV_ZP + 8
        ora FIX16_DIV_ZP + 17
        sta FIX16_DIV_ZP + 8

        lda FIX16_DIV_ZP + 12
        bne @DoSub

        lda FIX16_DIV_ZP + 11
        cmp FIX16_DIV_ZP + 7
        bcc @SkipSub
        bne @DoSub

        lda FIX16_DIV_ZP + 10
        cmp FIX16_DIV_ZP + 6
        bcc @SkipSub
        bne @DoSub

        lda FIX16_DIV_ZP + 9
        cmp FIX16_DIV_ZP + 5
        bcc @SkipSub
        bne @DoSub

        lda FIX16_DIV_ZP + 8
        cmp FIX16_DIV_ZP + 4
        bcc @SkipSub

@DoSub
        sec
        lda FIX16_DIV_ZP + 8
        sbc FIX16_DIV_ZP + 4
        sta FIX16_DIV_ZP + 8
        lda FIX16_DIV_ZP + 9
        sbc FIX16_DIV_ZP + 5
        sta FIX16_DIV_ZP + 9
        lda FIX16_DIV_ZP + 10
        sbc FIX16_DIV_ZP + 6
        sta FIX16_DIV_ZP + 10
        lda FIX16_DIV_ZP + 11
        sbc FIX16_DIV_ZP + 7
        sta FIX16_DIV_ZP + 11
        lda FIX16_DIV_ZP + 12
        sbc #0
        sta FIX16_DIV_ZP + 12

        lda FIX16_DIV_ZP + 13
        ora #1
        sta FIX16_DIV_ZP + 13

@SkipSub
        dex
        bne @DivLoop

        ; Negate quotient if signs differed
        lda FIX16_DIV_ZP + 18
        beq @StoreResult

        sec
        lda #0
        sbc FIX16_DIV_ZP + 13
        sta FIX16_DIV_ZP + 13
        lda #0
        sbc FIX16_DIV_ZP + 14
        sta FIX16_DIV_ZP + 14
        lda #0
        sbc FIX16_DIV_ZP + 15
        sta FIX16_DIV_ZP + 15
        lda #0
        sbc FIX16_DIV_ZP + 16
        sta FIX16_DIV_ZP + 16

@StoreResult
        ldy #0
        lda FIX16_DIV_ZP + 13
        sta (FIX16_DIV_RES_PTR),y
        iny
        lda FIX16_DIV_ZP + 14
        sta (FIX16_DIV_RES_PTR),y
        iny
        lda FIX16_DIV_ZP + 15
        sta (FIX16_DIV_RES_PTR),y
        iny
        lda FIX16_DIV_ZP + 16
        sta (FIX16_DIV_RES_PTR),y
        rts

@DivZero
        ldy #0
        lda #0
        sta (FIX16_DIV_RES_PTR),y
        iny
        sta (FIX16_DIV_RES_PTR),y
        iny
        sta (FIX16_DIV_RES_PTR),y
        iny
        sta (FIX16_DIV_RES_PTR),y
        rts
        

;********************************************
;* VEC3_MAT4_MUL                            *
;* Transform 3D Fix16 vec by 4x4 mat (W=1)  *
;* with perspective divide if W != 0, 1.0   *
;* IN:  MAT_A_PTR -> 64-byte 4x4 Fix16 mat   *
;*      VEC_IN_PTR -> 12-byte (X,Y,Z) Fix16 *
;*      VEC_OUT_PTR -> 12-byte (X,Y,Z) Fix16*
;********************************************
VEC3_MAT4_MUL
        jmp @Start

@OUT_BUF        .ds 16
@ROW_IDX        .ds 1
@COL_IDX        .ds 1
@ROW_OFF        .ds 1
@M_ELEM         .ds 4
@V_ELEM         .ds 4
@ACC_SUM        .ds 4
@DIV_TMP        .ds 4

@Start
        ; Compute X', Y', Z', W' into @OUT_BUF (16 bytes)
        lda #0
        sta @ROW_IDX

@RowLoop
        ; Start accumulator with mat[row][3] (byte offset row*16 + 12)
        lda @ROW_IDX
        asl
        asl
        asl
        asl
        clc
        adc #12
        clc
        adc MAT_A_PTR
        sta CUR_A_PTR
        lda #0
        adc MAT_A_PTR + 1
        sta CUR_A_PTR + 1

        LOAD_FIX16_PTR CUR_A_PTR, @ACC_SUM

        ; Accumulate mat[row][col] * vec[col] for col = 0..2
        lda #0
        sta @COL_IDX

@ColLoop
        lda @ROW_IDX
        asl
        asl
        asl
        asl
        sta @ROW_OFF
        lda @COL_IDX
        asl
        asl
        clc
        adc @ROW_OFF
        clc
        adc MAT_A_PTR
        sta CUR_A_PTR
        lda #0
        adc MAT_A_PTR + 1
        sta CUR_A_PTR + 1

        lda @COL_IDX
        asl
        asl
        clc
        adc VEC_IN_PTR
        sta CUR_V_PTR
        lda #0
        adc VEC_IN_PTR + 1
        sta CUR_V_PTR + 1

        LOAD_FIX16_PTR CUR_A_PTR, @M_ELEM
        LOAD_FIX16_PTR CUR_V_PTR, @V_ELEM
        CALL_FIX16_MUL @M_ELEM, @V_ELEM, PROD

        ADD_FIX16 PROD, @ACC_SUM, @ACC_SUM

        inc @COL_IDX
        lda @COL_IDX
        cmp #3
        beq @ExitColLoop
        jmp @ColLoop
@ExitColLoop
        ; Save row result into @OUT_BUF + (@ROW_IDX * 4)
        lda @ROW_IDX
        asl
        asl
        tax
        ldy #0
@StoreRow
        lda @ACC_SUM,y
        sta @OUT_BUF,x
        inx
        iny
        cpy #4
        bne @StoreRow

        inc @ROW_IDX
        lda @ROW_IDX
        cmp #4
        beq @RowLoopExit
        jmp @RowLoop
@RowLoopExit
        ; Check if W' (@OUT_BUF + 12..15) is zero
        lda @OUT_BUF + 12
        ora @OUT_BUF + 13
        ora @OUT_BUF + 14
        ora @OUT_BUF + 15
        bne @ExitCopy        
        jmp @CopyOut
@ExitCopy
        ; Check if W' == $00010000 (little-endian: $00, $00, $01, $00)
        lda @OUT_BUF + 12
        bne @DoDiv
        lda @OUT_BUF + 13
        bne @DoDiv
        lda @OUT_BUF + 14
        cmp #$01
        bne @DoDiv
        lda @OUT_BUF + 15
        bne @DoDiv
        beq @CopyOut

@DoDiv
        CALL_FIX16_DIV @OUT_BUF + 0, @OUT_BUF + 12, @DIV_TMP, FIX16_DIV_ZP
        ldy #0
@CopyDivX
        lda @DIV_TMP,y
        sta @OUT_BUF + 0,y
        iny
        cpy #4
        bne @CopyDivX

        CALL_FIX16_DIV @OUT_BUF + 4, @OUT_BUF + 12, @DIV_TMP, FIX16_DIV_ZP
        ldy #0
@CopyDivY
        lda @DIV_TMP,y
        sta @OUT_BUF + 4,y
        iny
        cpy #4
        bne @CopyDivY

        CALL_FIX16_DIV @OUT_BUF + 8, @OUT_BUF + 12, @DIV_TMP, FIX16_DIV_ZP
        ldy #0
@CopyDivZ
        lda @DIV_TMP,y
        sta @OUT_BUF + 8,y
        iny
        cpy #4
        bne @CopyDivZ

@CopyOut
        ; Copy 12 bytes (X, Y, Z) to VEC_OUT_PTR
        ldy #0
@OutLoop
        lda @OUT_BUF,y
        sta (VEC_OUT_PTR),y
        iny
        cpy #12
        bne @OutLoop

        rts

;********************************************
;* ROT_X_MAT4                               *
;* Builds 4x4 Fix16 X-rotation matrix in     *
;* (ROT_OUT_PTR) from ROT_X_ANGLE (0..255)   *
;* Uses GET_COSINE and GET_SINE             *
;********************************************
ROT_X_MAT4
        jmp @Start

@COS_VAL        .ds 4
@SIN_VAL        .ds 4
@NEG_SIN        .ds 4

@Start
        ; Copy 64-byte identity matrix MAT_I to (ROT_OUT_PTR)
        ldx #0
@CopyIdLoop
        lda MAT_I,x
        ldy #0
        sta (ROT_OUT_PTR),y
        inc ROT_OUT_PTR
        bne @NoIncHi1
        inc ROT_OUT_PTR + 1
@NoIncHi1
        inx
        cpx #64
        bne @CopyIdLoop

        ; Restore ROT_OUT_PTR back by 64 bytes
        sec
        lda ROT_OUT_PTR
        sbc #64
        sta ROT_OUT_PTR
        lda ROT_OUT_PTR + 1
        sbc #0
        sta ROT_OUT_PTR + 1

        ; Fetch cos(angle) and sin(angle) into 16.16 variables
        GET_COSINE ROT_X_ANGLE, @COS_VAL
        GET_SINE ROT_X_ANGLE, @SIN_VAL

        ; Compute -sin = (~sin) + 1 (two's complement 32-bit)
        sec
        lda #0
        sbc @SIN_VAL
        sta @NEG_SIN
        lda #0
        sbc @SIN_VAL + 1
        sta @NEG_SIN + 1
        lda #0
        sbc @SIN_VAL + 2
        sta @NEG_SIN + 2
        lda #0
        sbc @SIN_VAL + 3
        sta @NEG_SIN + 3

        ; Write mat[1][1] = cos at offset +20 (16 + 4)
        ldy #20
        lda @COS_VAL
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 3
        sta (ROT_OUT_PTR),y

        ; Write mat[1][2] = -sin at offset +24 (16 + 8)
        ldy #24
        lda @NEG_SIN
        sta (ROT_OUT_PTR),y
        iny
        lda @NEG_SIN + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @NEG_SIN + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @NEG_SIN + 3
        sta (ROT_OUT_PTR),y

        ; Write mat[2][1] = sin at offset +36 (32 + 4)
        ldy #36
        lda @SIN_VAL
        sta (ROT_OUT_PTR),y
        iny
        lda @SIN_VAL + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @SIN_VAL + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @SIN_VAL + 3
        sta (ROT_OUT_PTR),y

        ; Write mat[2][2] = cos at offset +40 (32 + 8)
        ldy #40
        lda @COS_VAL
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 3
        sta (ROT_OUT_PTR),y

        rts

;********************************************
;* ROT_Y_MAT4                               *
;* Builds 4x4 Fix16 Y-rotation matrix in     *
;* (ROT_OUT_PTR) from ROT_Y_ANGLE (0..255)   *
;* Uses GET_COSINE and GET_SINE             *
;********************************************
ROT_Y_MAT4
        jmp @Start

@COS_VAL        .ds 4
@SIN_VAL        .ds 4
@NEG_SIN        .ds 4

@Start
        ; Copy 64-byte identity matrix MAT_I to (ROT_OUT_PTR)
        ldx #0
@CopyIdLoop
        lda MAT_I,x
        ldy #0
        sta (ROT_OUT_PTR),y
        inc ROT_OUT_PTR
        bne @NoIncHi1
        inc ROT_OUT_PTR + 1
@NoIncHi1
        inx
        cpx #64
        bne @CopyIdLoop

        ; Restore ROT_OUT_PTR back by 64 bytes
        sec
        lda ROT_OUT_PTR
        sbc #64
        sta ROT_OUT_PTR
        lda ROT_OUT_PTR + 1
        sbc #0
        sta ROT_OUT_PTR + 1

        ; Fetch cos(angle) and sin(angle) into 16.16 variables
        GET_COSINE ROT_Y_ANGLE, @COS_VAL
        GET_SINE ROT_Y_ANGLE, @SIN_VAL

        ; Compute -sin = (~sin) + 1 (two's complement 32-bit)
        sec
        lda #0
        sbc @SIN_VAL
        sta @NEG_SIN
        lda #0
        sbc @SIN_VAL + 1
        sta @NEG_SIN + 1
        lda #0
        sbc @SIN_VAL + 2
        sta @NEG_SIN + 2
        lda #0
        sbc @SIN_VAL + 3
        sta @NEG_SIN + 3

        ; Write mat[0][0] = cos at offset +0
        ldy #0
        lda @COS_VAL
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 3
        sta (ROT_OUT_PTR),y

        ; Write mat[0][2] = sin at offset +8
        ldy #8
        lda @SIN_VAL
        sta (ROT_OUT_PTR),y
        iny
        lda @SIN_VAL + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @SIN_VAL + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @SIN_VAL + 3
        sta (ROT_OUT_PTR),y

        ; Write mat[2][0] = -sin at offset +32
        ldy #32
        lda @NEG_SIN
        sta (ROT_OUT_PTR),y
        iny
        lda @NEG_SIN + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @NEG_SIN + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @NEG_SIN + 3
        sta (ROT_OUT_PTR),y

        ; Write mat[2][2] = cos at offset +40
        ldy #40
        lda @COS_VAL
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 3
        sta (ROT_OUT_PTR),y

        rts

;********************************************
;* ROT_Z_MAT4                               *
;* Builds 4x4 Fix16 Z-rotation matrix in     *
;* (ROT_OUT_PTR) from ROT_Z_ANGLE (0..255)   *
;* Uses GET_COSINE and GET_SINE             *
;********************************************
ROT_Z_MAT4
        jmp @Start

@COS_VAL        .ds 4
@SIN_VAL        .ds 4
@NEG_SIN        .ds 4

@Start
        ; Copy 64-byte identity matrix MAT_I to (ROT_OUT_PTR)
        ldx #0
@CopyIdLoop
        lda MAT_I,x
        ldy #0
        sta (ROT_OUT_PTR),y
        inc ROT_OUT_PTR
        bne @NoIncHi1
        inc ROT_OUT_PTR + 1
@NoIncHi1
        inx
        cpx #64
        bne @CopyIdLoop

        ; Restore ROT_OUT_PTR back by 64 bytes
        sec
        lda ROT_OUT_PTR
        sbc #64
        sta ROT_OUT_PTR
        lda ROT_OUT_PTR + 1
        sbc #0
        sta ROT_OUT_PTR + 1

        ; Fetch cos(angle) and sin(angle) into 16.16 variables
        GET_COSINE ROT_Z_ANGLE, @COS_VAL
        GET_SINE ROT_Z_ANGLE, @SIN_VAL

        ; Compute -sin = (~sin) + 1 (two's complement 32-bit)
        sec
        lda #0
        sbc @SIN_VAL
        sta @NEG_SIN
        lda #0
        sbc @SIN_VAL + 1
        sta @NEG_SIN + 1
        lda #0
        sbc @SIN_VAL + 2
        sta @NEG_SIN + 2
        lda #0
        sbc @SIN_VAL + 3
        sta @NEG_SIN + 3

        ; Write mat[0][0] = cos at offset +0
        ldy #0
        lda @COS_VAL
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 3
        sta (ROT_OUT_PTR),y

        ; Write mat[0][1] = -sin at offset +4
        ldy #4
        lda @NEG_SIN
        sta (ROT_OUT_PTR),y
        iny
        lda @NEG_SIN + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @NEG_SIN + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @NEG_SIN + 3
        sta (ROT_OUT_PTR),y

        ; Write mat[1][0] = sin at offset +16
        ldy #16
        lda @SIN_VAL
        sta (ROT_OUT_PTR),y
        iny
        lda @SIN_VAL + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @SIN_VAL + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @SIN_VAL + 3
        sta (ROT_OUT_PTR),y

        ; Write mat[1][1] = cos at offset +20
        ldy #20
        lda @COS_VAL
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 1
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 2
        sta (ROT_OUT_PTR),y
        iny
        lda @COS_VAL + 3
        sta (ROT_OUT_PTR),y

        rts

;********************************************
;* ROT_XYZ_MAT4                             *
;* Builds ((Rx * Ry) * Rz) in (ROT_OUT_PTR) *
;* Preserves and calls ROT_X_MAT4,          *
;* ROT_Y_MAT4, and ROT_Z_MAT4               *
;********************************************
ROT_XYZ_MAT4
        jmp @Start

@MAT_RX         .ds 64
@MAT_RY         .ds 64
@MAT_XY         .ds 64
@FINAL_PTR      .ds 2

@Start
        ; Save caller destination pointer so ROT_OUT_PTR can be reused
        lda ROT_OUT_PTR
        sta @FINAL_PTR
        lda ROT_OUT_PTR + 1
        sta @FINAL_PTR + 1

        ; Build Rx, Ry, and Rz into dedicated buffers
        CALL_ROT_X_MAT4 ROT_XYZ_AX, @MAT_RX
        CALL_ROT_Y_MAT4 ROT_XYZ_AY, @MAT_RY

        ; Compute @MAT_XY = @MAT_RX * @MAT_RY
        CALL_MAT4_MUL @MAT_RX, @MAT_RY, @MAT_XY

        ; Build Rz into caller output buffer, then multiply (@MAT_XY * Rz)
        lda @FINAL_PTR
        sta ROT_OUT_PTR
        lda @FINAL_PTR + 1
        sta ROT_OUT_PTR + 1

        CALL_ROT_Z_MAT4 ROT_XYZ_AZ, ROT_OUT_PTR
        CALL_MAT4_MUL @MAT_XY, @MAT_RX, @MAT_XY

        rts
        
;********************************************
;* MAT_I Identity matrix
;********************************************
MAT_I:
            ; Row 0
            .word   $0000, $0001        ; 1.0
            .word   $0000, $0000        ; 0.0
            .word   $0000, $0000        ; 0.0
            .word   $0000, $0000        ; 0.0

            ; Row 1
            .word   $0000, $0000        ; 0.0
            .word   $0000, $0001        ; 1.0
            .word   $0000, $0000        ; 0.0
            .word   $0000, $0000        ; 0.0

            ; Row 2
            .word   $0000, $0000        ; 0.0
            .word   $0000, $0000        ; 0.0
            .word   $0000, $0001        ; 1.0
            .word   $0000, $0000        ; 0.0

            ; Row 3
            .word   $0000, $0000        ; 0.0
            .word   $0000, $0000        ; 0.0
            .word   $0000, $0000        ; 0.0
            .word   $0000, $0001        ; 1.0
            