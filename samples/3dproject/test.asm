
Mat4MulTestResult   .byte '?',0
DivTestResult       .byte '?',0
Vec3Mat4TestResult  .byte '?',0

RunTests            
            jsr     DisplayVec3Mat4
            rts

            jsr     RunVec3Mat4Test                       
            rts
            
            jsr     RunMat4MulTest            
            jsr     RunDivTest

            rts
        
            lda     BORDER
            cmp     #5
            bne     @Done

            jsr     RunRotXTest
            lda     BORDER
            cmp     #5
            bne     @Done

            jsr     RunRotYTest
            lda     BORDER
            cmp     #5
            bne     @Done
            
            jsr     RunRotZTest
            lda     BORDER
            cmp     #5
            bne     @Done

            jsr     RunRotXyzTest1
            lda     BORDER
            cmp     #5
            bne     @Done
            
            jsr     RunRotXyzTest2
            lda     BORDER
            cmp     #5
            bne     @Done
         
            jsr     RunXformTest
            lda     BORDER
            cmp     #5
            bne     @Done
     
@Done
            jmp     @Done

        
; --------------------------------------------
; RunMat4MulTest
; --------------------------------------------
        
RunMat4MulTest
        lda #'P'
        sta Mat4MulTestResult
        
        CALL_MAT4_MUL @MAT_TEST_A, @MAT_TEST_B, @MAT_TEST_OUT

@TestLoop
        lda @MAT_TEST_OUT, x
        cmp @MAT_TEST_EXPECTED, x
        beq @Match

        lda #'F'
        sta Mat4MulTestResult
        rts

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
        lda #'P'
        sta DivTestResult

        lda #0
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

        lda #'F'
        sta DivTestResult
        rts
        
@ByteMatch
        inx
        iny
        cpy #4
        bne @CheckBytes

        inc @CASE_IDX
        lda @CASE_IDX
        cmp #7
        bne @CaseLoop

@Done        
        rts
        
@CUR_NUM        .ds 4
@CUR_DEN        .ds 4
@CUR_RES        .ds 4
@CASE_IDX       .ds 1
@BYTE_IDX       .ds 1
    
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
        lda #'P'
        sta Vec3Mat4TestResult

        CALL_VEC3_MAT4_MUL @TEST_MAT4_IN, @TEST_VEC3_IN, @TEST_VEC3_OUT

        ldx #0
@CmpLoop
        lda @TEST_VEC3_OUT,x
        cmp @TEST_VEC3_EXP,x
        beq @Match       
        
        lda #'F'
        sta Vec3Mat4TestResult
        

@Match
        inx
        cpx #12
        bne @CmpLoop
        
@Done
        rts
            

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
        .byte  $FF, $FF, $FF, $FF
        .byte  $FF, $FF, $FF, $FF
        .byte  $FF, $FF, $FF, $FF
        .byte  $FF, $FF, $FF, $FF
   
   
; --------------------------------------------
; RunRotXTest
; Tests CALL_ROT_X_MAT4 at angle 0 and 64
; --------------------------------------------
RunRotXTest
        jmp @Start

@ANGLE_0        .byte 0
@ANGLE_64       .byte 64
@ERR_FLAG       .ds 1
@ROT_OUT_0      .ds 64
@ROT_OUT_64     .ds 64

@EXP_ROT_0
        ; Row 0: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@EXP_ROT_64
        ; Row 0: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  0.0, -1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $FF, $FF
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@Start
        lda #1
        sta BORDER

        lda #0
        sta @ERR_FLAG

        CALL_ROT_X_MAT4 @ANGLE_0, @ROT_OUT_0

        ldx #0
@Cmp0Loop
        lda @ROT_OUT_0,x
        cmp @EXP_ROT_0,x
        beq @Match0

        lda #1
        sta @ERR_FLAG

@Match0
        inx
        cpx #64
        bne @Cmp0Loop

        CALL_ROT_X_MAT4 @ANGLE_64, @ROT_OUT_64

        ldx #0
@Cmp64Loop
        lda @ROT_OUT_64,x
        cmp @EXP_ROT_64,x
        beq @Match64

        lda #1
        sta @ERR_FLAG

@Match64
        inx
        cpx #64
        bne @Cmp64Loop

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
        
        
; --------------------------------------------
; RunRotYTest
; Tests CALL_ROT_Y_MAT4 at angle 0 and 64
; --------------------------------------------
RunRotYTest
        jmp @Start

@ANGLE_0        .byte 0
@ANGLE_64       .byte 64
@ERR_FLAG       .ds 1
@ROT_OUT_0      .ds 64
@ROT_OUT_64     .ds 64

@EXP_ROT_0
        ; Row 0: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@EXP_ROT_64
        ; Row 0: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [-1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $FF, $FF
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@Start
        lda #1
        sta BORDER

        lda #0
        sta @ERR_FLAG

        CALL_ROT_Y_MAT4 @ANGLE_0, @ROT_OUT_0

        ldx #0
@Cmp0Loop
        lda @ROT_OUT_0,x
        cmp @EXP_ROT_0,x
        beq @Match0

        lda #1
        sta @ERR_FLAG

@Match0
        inx
        cpx #64
        bne @Cmp0Loop

        CALL_ROT_Y_MAT4 @ANGLE_64, @ROT_OUT_64

        ldx #0
@Cmp64Loop
        lda @ROT_OUT_64,x
        cmp @EXP_ROT_64,x
        beq @Match64

        lda #1
        sta @ERR_FLAG

@Match64
        inx
        cpx #64
        bne @Cmp64Loop

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
        
; --------------------------------------------
; RunRotZTest
; Tests CALL_ROT_Z_MAT4 at angle 0 and 64
; --------------------------------------------
RunRotZTest
        jmp @Start

@ANGLE_0        .byte 0
@ANGLE_64       .byte 64
@ERR_FLAG       .ds 1
@ROT_OUT_0      .ds 64
@ROT_OUT_64     .ds 64

@EXP_ROT_0
        ; Row 0: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@EXP_ROT_64
        ; Row 0: [ 0.0, -1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $FF, $FF
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@Start
        lda #1
        sta BORDER

        lda #0
        sta @ERR_FLAG

        CALL_ROT_Z_MAT4 @ANGLE_0, @ROT_OUT_0

        ldx #0
@Cmp0Loop
        lda @ROT_OUT_0,x
        cmp @EXP_ROT_0,x
        beq @Match0

        lda #1
        sta @ERR_FLAG

@Match0
        inx
        cpx #64
        bne @Cmp0Loop

        CALL_ROT_Z_MAT4 @ANGLE_64, @ROT_OUT_64

        ldx #0
@Cmp64Loop
        lda @ROT_OUT_64,x
        cmp @EXP_ROT_64,x
        beq @Match64

        lda #1
        sta @ERR_FLAG

@Match64
        inx
        cpx #64
        bne @Cmp64Loop

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
        
; --------------------------------------------
; RunRotXyzTest
; Tests CALL_ROT_XYZ_MAT4 with (0,0,0),
; (64,0,0), and (64,64,0)
; --------------------------------------------
RunRotXyzTest1
        jmp @Start

@AX_ZERO        .byte 0
@AY_ZERO        .byte 0
@AZ_ZERO        .byte 0

@AX_64          .byte 64
@AY_0           .byte 0
@AZ_0           .byte 0

@AX_64_B        .byte 64
@AY_64_B        .byte 64
@AZ_0_B         .byte 0

@ERR_FLAG       .ds 1
@OUT_ZERO       .ds 64
@OUT_X64        .ds 64
@OUT_XY64       .ds 64

@EXP_XYZ_ZERO
        ; Row 0: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@EXP_XYZ_X64
        ; Row 0: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  0.0, -1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $FF, $FF
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@EXP_XYZ_XY64
        ; Row 0: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@Start
        lda #1
        sta BORDER

        lda #0
        sta @ERR_FLAG

        CALL_ROT_XYZ_MAT4 @AX_ZERO, @AY_ZERO, @AZ_ZERO, @OUT_ZERO

        ldx #0
@CmpZeroLoop
        lda @OUT_ZERO,x
        cmp @EXP_XYZ_ZERO,x
        beq @MatchZero

        lda #1
        sta @ERR_FLAG

@MatchZero
        inx
        cpx #64
        bne @CmpZeroLoop

        CALL_ROT_XYZ_MAT4 @AX_64, @AY_0, @AZ_0, @OUT_X64

        ldx #0
@CmpX64Loop
        lda @OUT_X64,x
        cmp @EXP_XYZ_X64,x
        beq @MatchX64

        lda #1
        sta @ERR_FLAG

@MatchX64
        inx
        cpx #64
        bne @CmpX64Loop

        CALL_ROT_XYZ_MAT4 @AX_64_B, @AY_64_B, @AZ_0_B, @OUT_XY64

        ldx #0
@CmpXy64Loop
        lda @OUT_XY64,x
        cmp @EXP_XYZ_XY64,x
        beq @MatchXy64

        lda #1
        sta @ERR_FLAG

@MatchXy64
        inx
        cpx #64
        bne @CmpXy64Loop

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
        
 ; --------------------------------------------
; RunRotXyzTest
; Tests CALL_ROT_XYZ_MAT4 with (0,0,0),
; (64,0,0), (64,64,0), and (0,0,64)
; --------------------------------------------
RunRotXyzTest2
        jmp @Start

@AX_ZERO        .byte 0
@AY_ZERO        .byte 0
@AZ_ZERO        .byte 0

@AX_64          .byte 64
@AY_0           .byte 0
@AZ_0           .byte 0

@AX_64_B        .byte 64
@AY_64_B        .byte 64
@AZ_0_B         .byte 0

@AX_0_Z         .byte 0
@AY_0_Z         .byte 0
@AZ_64_Z        .byte 64

@ERR_FLAG       .ds 1
@OUT_ZERO       .ds 64
@OUT_X64        .ds 64
@OUT_XY64       .ds 64
@OUT_Z64        .ds 64

@EXP_XYZ_ZERO
        ; Row 0: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@EXP_XYZ_X64
        ; Row 0: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  0.0, -1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $FF, $FF
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@EXP_XYZ_XY64
        ; Row 0: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@EXP_XYZ_Z64
        ; Row 0: [ 0.0, -1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $FF, $FF
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@Start
        lda #1
        sta BORDER

        lda #0
        sta @ERR_FLAG

        CALL_ROT_XYZ_MAT4 @AX_ZERO, @AY_ZERO, @AZ_ZERO, @OUT_ZERO

        ldx #0
@CmpZeroLoop
        lda @OUT_ZERO,x
        cmp @EXP_XYZ_ZERO,x
        beq @MatchZero

        lda #1
        sta @ERR_FLAG

@MatchZero
        inx
        cpx #64
        bne @CmpZeroLoop

        CALL_ROT_XYZ_MAT4 @AX_64, @AY_0, @AZ_0, @OUT_X64

        ldx #0
@CmpX64Loop
        lda @OUT_X64,x
        cmp @EXP_XYZ_X64,x
        beq @MatchX64

        lda #1
        sta @ERR_FLAG

@MatchX64
        inx
        cpx #64
        bne @CmpX64Loop

        CALL_ROT_XYZ_MAT4 @AX_64_B, @AY_64_B, @AZ_0_B, @OUT_XY64

        ldx #0
@CmpXy64Loop
        lda @OUT_XY64,x
        cmp @EXP_XYZ_XY64,x
        beq @MatchXy64

        lda #1
        sta @ERR_FLAG

@MatchXy64
        inx
        cpx #64
        bne @CmpXy64Loop

        CALL_ROT_XYZ_MAT4 @AX_0_Z, @AY_0_Z, @AZ_64_Z, @OUT_Z64

        ldx #0
@CmpZ64Loop
        lda @OUT_Z64,x
        cmp @EXP_XYZ_Z64,x
        beq @MatchZ64

        lda #1
        sta @ERR_FLAG

@MatchZ64
        inx
        cpx #64
        bne @CmpZ64Loop

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
        
        
; --------------------------------------------
; RunXformTest
; Tests CALL_CREATE_XFORM_MAT4 with identity
; and combined T=(10,-5,20), R=(0,0,64),
; S=(2,3,4)
; --------------------------------------------
RunXformTest
        jmp @Start

; Case 1 inputs: Identity
@ID_TX          .byte $00, $00, $00, $00
@ID_TY          .byte $00, $00, $00, $00
@ID_TZ          .byte $00, $00, $00, $00
@ID_RX          .byte 0
@ID_RY          .byte 0
@ID_RZ          .byte 0
@ID_SX          .byte $00, $00, $01, $00
@ID_SY          .byte $00, $00, $01, $00
@ID_SZ          .byte $00, $00, $01, $00

; Case 2 inputs: T=(10,-5,20), R=(0,0,64), S=(2,3,4)
@TRS_TX         .byte $00, $00, $0A, $00
@TRS_TY         .byte $00, $00, $FB, $FF
@TRS_TZ         .byte $00, $00, $14, $00
@TRS_RX         .byte 0
@TRS_RY         .byte 0
@TRS_RZ         .byte 64
@TRS_SX         .byte $00, $00, $02, $00
@TRS_SY         .byte $00, $00, $03, $00
@TRS_SZ         .byte $00, $00, $04, $00

@ERR_FLAG       .ds 1
@OUT_ID         .ds 64
@OUT_TRS        .ds 64

@EXP_ID
        ; Row 0: [ 1.0,  0.0,  0.0,  0.0]
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 1: [ 0.0,  1.0,  0.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00

        ; Row 2: [ 0.0,  0.0,  1.0,  0.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00
        .byte $00, $00, $00, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@EXP_TRS
        ; Row 0: [ 0.0, -3.0,  0.0, 10.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $FD, $FF
        .byte $00, $00, $00, $00
        .byte $00, $00, $0A, $00

        ; Row 1: [ 2.0,  0.0,  0.0, -5.0]
        .byte $00, $00, $02, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $FB, $FF

        ; Row 2: [ 0.0,  0.0,  4.0, 20.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $04, $00
        .byte $00, $00, $14, $00

        ; Row 3: [ 0.0,  0.0,  0.0,  1.0]
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $00, $00
        .byte $00, $00, $01, $00

@Start
        lda #1
        sta BORDER

        lda #0
        sta @ERR_FLAG

        CALL_CREATE_XFORM_MAT4 @ID_TX, @ID_TY, @ID_TZ, @ID_RX, @ID_RY, @ID_RZ, @ID_SX, @ID_SY, @ID_SZ, @OUT_ID

        ldx #0
@CmpIdLoop
        lda @OUT_ID,x
        cmp @EXP_ID,x
        beq @MatchId

        lda #1
        sta @ERR_FLAG

@MatchId
        inx
        cpx #64
        bne @CmpIdLoop

        CALL_CREATE_XFORM_MAT4 @TRS_TX, @TRS_TY, @TRS_TZ, @TRS_RX, @TRS_RY, @TRS_RZ, @TRS_SX, @TRS_SY, @TRS_SZ, @OUT_TRS

        ldx #0
@CmpTrsLoop
        lda @OUT_TRS,x
        cmp @EXP_TRS,x
        beq @MatchTrs

        lda #1
        sta @ERR_FLAG

@MatchTrs
        inx
        cpx #64
        bne @CmpTrsLoop

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
        