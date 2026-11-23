        
; --------------------------------------------
; RunMat4MulTest
; --------------------------------------------
        
RunMat4MulTest
        lda #1
        sta BORDER
        CALL_MAT4_MUL @MAT_TEST_A, @MAT_TEST_B, @MAT_TEST_OUT
        lda #5
        sta BORDER
        ldx #0

@TestLoop
        lda @MAT_TEST_OUT, x
        cmp @MAT_TEST_EXPECTED, x
        beq @Match

        lda #2
        sta BORDER
@Match
        inx
        cpx #64
        bne @TestLoop
        rts

@MAT_TEST_A
        ; Row 0: [  2.0,  0.5,  0.0,  1.0 ]
        .byte $00, $00, $02, $00
        .byte $00, $80, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

        ; Row 1: [  0.0,  1.0,  0.5,  2.0 ]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $80, $00, $00
        .byte $00, $00, $02, $00

        ; Row 2: [ -1.0,  0.0,  2.0,  3.0 ]
        .byte $00, $00, $FF, $FF
        .byte $00, $00, $00, $00
        .byte $00, $00, $02, $00
        .byte $00, $00, $03, $00

        ; Row 3: [  0.0,  0.0,  0.0,  1.0 ]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@MAT_TEST_B
        ; Row 0: [  1.0,  2.0,  0.0,  0.0 ]
        .byte $00, $00, $01, $00
        .byte $00, $00, $02, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [  0.0,  0.5,  1.0,  0.0 ]
        .byte $00, $00, $00, $00
        .byte $00, $80, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 2: [  0.0,  0.0,  1.0,  0.0 ]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 3: [  3.0, -1.0,  2.0,  1.0 ]
        .byte $00, $00, $03, $00
        .byte $00, $00, $FF, $FF
        .byte $00, $00, $02, $00
        .byte $00, $00, $01, $00

@MAT_TEST_OUT
        .ds 64
 
@MAT_TEST_EXPECTED
        ; Row 0: [  5.0,  3.25,  2.5,  1.0 ]
        .byte $00, $00, $05, $00
        .byte $00, $40, $03, $00
        .byte $00, $80, $02, $00
        .byte $00, $00, $01, $00

        ; Row 1: [  6.0, -1.5,   5.5,  2.0 ]
        .byte $00, $00, $06, $00
        .byte $00, $80, $FE, $FF
        .byte $00, $80, $05, $00
        .byte $00, $00, $02, $00

        ; Row 2: [  8.0, -5.0,   8.0,  3.0 ]
        .byte $00, $00, $08, $00
        .byte $00, $00, $FB, $FF
        .byte $00, $00, $08, $00
        .byte $00, $00, $03, $00

        ; Row 3: [  3.0, -1.0,   2.0,  1.0 ]
        .byte $00, $00, $03, $00
        .byte $00, $00, $FF, $FF
        .byte $00, $00, $02, $00
        .byte $00, $00, $01, $00        
        
; --------------------------------------------
; RunDivTest
; --------------------------------------------
RunDivTest
        lda #1
        sta BORDER

        lda #0
        sta @ERR_FLAG
        sta @CASE_IDX

@CaseLoop
        ; Compute byte offset = @CASE_IDX * 4
        lda @CASE_IDX
        asl
        asl
        tax

        ; Copy 4-byte dividend and divisor for this case
        ldy #0
@CopyInputs
        lda @DIV_NUM_TABLE,x
        sta @CUR_NUM,y
        lda @DIV_DEN_TABLE,x
        sta @CUR_DEN,y
        inx
        iny
        cpy #4
        bne @CopyInputs

        CALL_FIX16_DIV @CUR_NUM, @CUR_DEN, @CUR_RES, FIX16_DIV_ZP

        ; Store result into @DIV_OUT_TABLE and compare against @DIV_EXP_TABLE
        lda @CASE_IDX
        asl
        asl
        tax
        ldy #0

@CheckBytes
        lda @CUR_RES,y
        sta @DIV_OUT_TABLE,x
        cmp @DIV_EXP_TABLE,x
        beq @ByteMatch

        lda #1
        sta @ERR_FLAG

@ByteMatch
        inx
        iny
        cpy #4
        bne @CheckBytes

        inc @CASE_IDX
        lda @CASE_IDX
        cmp #7
        bne @CaseLoop

        ; Set border: green (5) if all 28 bytes match, red (2) on any mismatch
        lda @ERR_FLAG
        bne @TestFail

        lda #5
        sta BORDER
        jmp @Done

@TestFail
        lda #2
        sta BORDER

@Done        
        rts
        
@CUR_NUM        .ds 4
@CUR_DEN        .ds 4
@CUR_RES        .ds 4
@CASE_IDX       .ds 1
@BYTE_IDX       .ds 1
@ERR_FLAG       .ds 1
    
;********************************************
;* FIX16_DIV Test Harness (7 cases x 4B)    *
;********************************************
@DIV_NUM_TABLE
        ;  6.5 ($00068000)
        .byte $00, $80, $06, $00
        ; -6.5 ($FFF98000)
        .byte $00, $80, $F9, $FF
        ;  6.5 ($00068000)
        .byte $00, $80, $06, $00
        ; -6.5 ($FFF98000)
        .byte $00, $80, $F9, $FF
        ;  1.0 ($00010000)
        .byte $00, $00, $01, $00
        ; -1.0 ($FFFF0000)
        .byte $00, $00, $FF, $FF
        ;  5.0 ($00050000)
        .byte $00, $00, $05, $00

@DIV_DEN_TABLE
        ;  2.0 ($00020000)
        .byte $00, $00, $02, $00
        ;  2.0 ($00020000)
        .byte $00, $00, $02, $00
        ; -2.0 ($FFFE0000)
        .byte $00, $00, $FE, $FF
        ; -2.0 ($FFFE0000)
        .byte $00, $00, $FE, $FF
        ;  4.0 ($00040000)
        .byte $00, $00, $04, $00
        ;  0.5 ($00008000)
        .byte $00, $80, $00, $00
        ;  0.0 ($00000000)
        .byte $00, $00, $00, $00

@DIV_EXP_TABLE
        ;  3.25 ($00034000)
        .byte $00, $40, $03, $00
        ; -3.25 ($FFFCC000)
        .byte $00, $C0, $FC, $FF
        ; -3.25 ($FFFCC000)
        .byte $00, $C0, $FC, $FF
        ;  3.25 ($00034000)
        .byte $00, $40, $03, $00
        ;  0.25 ($00004000)
        .byte $00, $40, $00, $00
        ; -2.0  ($FFFE0000)
        .byte $00, $00, $FE, $FF
        ;  0.0  ($00000000)
        .byte $00, $00, $00, $00

@DIV_OUT_TABLE
        .ds 28
        

; --------------------------------------------
; RunVec3Mat4Test
; --------------------------------------------
RunVec3Mat4Test
        lda #1
        sta BORDER

        lda #0
        sta @ERR_FLAG

        CALL_VEC3_MAT4_MUL @TEST_MAT4_IN, @TEST_VEC3_IN, @TEST_VEC3_OUT

        ldx #0
@CmpLoop
        lda @TEST_VEC3_OUT,x
        cmp @TEST_VEC3_EXP,x
        beq @Match

        lda #1
        sta @ERR_FLAG

@Match
        inx
        cpx #12
        bne @CmpLoop

        lda @ERR_FLAG
        bne @Fail

        lda #5
        sta BORDER
        jmp @Done

@Fail
        lda #2
        sta BORDER

@Done
        rts

@ERR_FLAG
        .byte 0

;********************************************
;* VEC3_MAT4_MUL Test (12-byte output)      *
;********************************************
@TEST_VEC3_IN
        ; X =  2.0 ($00020000)
        .byte $00, $00, $02, $00
        ; Y = -1.0 ($FFFF0000)
        .byte $00, $00, $FF, $FF
        ; Z =  4.0 ($00040000)
        .byte $00, $00, $04, $00

@TEST_MAT4_IN
        ; Row 0: [ 2.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $02, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

        ; Row 1: [ 0.0,  3.0,  0.0, -2.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $03, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $FE, $FF

        ; Row 2: [ 0.0,  0.0,  0.5,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $80, $00, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.5,  0.0] -> W' = 2.0
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $80, $00, $00
        .byte $00, $00, $00, $00

@TEST_VEC3_EXP
        ; X =  2.5 ($00028000)
        .byte $00, $80, $02, $00
        ; Y = -2.5 ($FFFD8000)
        .byte $00, $80, $FD, $FF
        ; Z =  1.0 ($00010000)
        .byte $00, $00, $01, $00

@TEST_VEC3_OUT
        .ds 12
        