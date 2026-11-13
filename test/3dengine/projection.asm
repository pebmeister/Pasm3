;********************************************
;* PROJECT_VECTOR
;*
;* Specialized perspective projection
;*
;* Input:  MAT4_VIN_PTR
;* Output: MAT4_VOUT_PTR
;*
;* Assumes the current PROJECTION_MATRIX.
;*
;* Only two fixed-point multiplications:
;*   X = X * 0.625
;*   Z = (Z - W) * 1.11111
;*
;* Y and W are copied directly.
;********************************************

PROJECT_VECTOR:

        ;------------------------------------
        ; Xclip = Xworld * 0.625
        ;------------------------------------

        ; Load projection X coefficient
        lda PROJECTION_MATRIX
        sta MAT_MUL_A
        lda PROJECTION_MATRIX+1
        sta MAT_MUL_A+1
        lda PROJECTION_MATRIX+2
        sta MAT_MUL_A+2
        lda PROJECTION_MATRIX+3
        sta MAT_MUL_A+3

        ; Load input X
        ldy #0
        lda (MAT4_VIN_PTR),y
        sta MAT_MUL_B
        iny
        lda (MAT4_VIN_PTR),y
        sta MAT_MUL_B+1
        iny
        lda (MAT4_VIN_PTR),y
        sta MAT_MUL_B+2
        iny
        lda (MAT4_VIN_PTR),y
        sta MAT_MUL_B+3

        CALL_FIX16_MUL MAT_MUL_A, MAT_MUL_B, MAT_PRODUCT

        ; Store Xclip
        ldy #0
        lda MAT_PRODUCT
        sta (MAT4_VOUT_PTR),y
        iny
        lda MAT_PRODUCT+1
        sta (MAT4_VOUT_PTR),y
        iny
        lda MAT_PRODUCT+2
        sta (MAT4_VOUT_PTR),y
        iny
        lda MAT_PRODUCT+3
        sta (MAT4_VOUT_PTR),y

        ;------------------------------------
        ; Yclip = Yworld
        ;------------------------------------

        ldy #4
        lda (MAT4_VIN_PTR),y
        sta (MAT4_VOUT_PTR),y
        iny
        lda (MAT4_VIN_PTR),y
        sta (MAT4_VOUT_PTR),y
        iny
        lda (MAT4_VIN_PTR),y
        sta (MAT4_VOUT_PTR),y
        iny
        lda (MAT4_VIN_PTR),y
        sta (MAT4_VOUT_PTR),y

        ;------------------------------------
        ; Zclip = (Zworld - Wworld) * 1.11111
        ;------------------------------------

        ; Subtract W from Z
        sec
        ldy #8
        lda (MAT4_VIN_PTR),y
        ldy #12
        sbc (MAT4_VIN_PTR),y
        sta MAT_ACCUM

        ldy #9
        lda (MAT4_VIN_PTR),y
        ldy #13
        sbc (MAT4_VIN_PTR),y
        sta MAT_ACCUM+1

        ldy #10
        lda (MAT4_VIN_PTR),y
        ldy #14
        sbc (MAT4_VIN_PTR),y
        sta MAT_ACCUM+2

        ldy #11
        lda (MAT4_VIN_PTR),y
        ldy #15
        sbc (MAT4_VIN_PTR),y
        sta MAT_ACCUM+3

        ; Load projection Z coefficient
        lda PROJECTION_MATRIX+40
        sta MAT_MUL_A
        lda PROJECTION_MATRIX+41
        sta MAT_MUL_A+1
        lda PROJECTION_MATRIX+42
        sta MAT_MUL_A+2
        lda PROJECTION_MATRIX+43
        sta MAT_MUL_A+3

        ; Load difference into operand B
        lda MAT_ACCUM
        sta MAT_MUL_B
        lda MAT_ACCUM+1
        sta MAT_MUL_B+1
        lda MAT_ACCUM+2
        sta MAT_MUL_B+2
        lda MAT_ACCUM+3
        sta MAT_MUL_B+3

        CALL_FIX16_MUL MAT_MUL_A, MAT_MUL_B, MAT_PRODUCT

        ; Store Zclip
        ldy #8
        lda MAT_PRODUCT
        sta (MAT4_VOUT_PTR),y
        iny
        lda MAT_PRODUCT+1
        sta (MAT4_VOUT_PTR),y
        iny
        lda MAT_PRODUCT+2
        sta (MAT4_VOUT_PTR),y
        iny
        lda MAT_PRODUCT+3
        sta (MAT4_VOUT_PTR),y

        ;------------------------------------
        ; Wclip = Zworld
        ;------------------------------------

        ldy #8
        lda (MAT4_VIN_PTR),y
        ldy #12
        sta (MAT4_VOUT_PTR),y

        ldy #9
        lda (MAT4_VIN_PTR),y
        ldy #13
        sta (MAT4_VOUT_PTR),y

        ldy #10
        lda (MAT4_VIN_PTR),y
        ldy #14
        sta (MAT4_VOUT_PTR),y

        ldy #11
        lda (MAT4_VIN_PTR),y
        ldy #15
        sta (MAT4_VOUT_PTR),y

        rts
        
PROJECTION_MATRIX:

        ; Row 0
        .word $A000, $0000    ;  0.62500
        .word $0000, $0000    ;  0
        .word $0000, $0000    ;  0
        .word $0000, $0000    ;  0

        ; Row 1
        .word $0000, $0000    ;  0
        .word $0000, $0001    ;  1.0
        .word $0000, $0000    ;  0
        .word $0000, $0000    ;  0

        ; Row 2
        .word $0000, $0000    ;  0
        .word $0000, $0000    ;  0
        .word $1C72, $0001    ;  1.11111
        .word $E38E, $FFFE    ; -1.11111

        ; Row 3
        .word $0000, $0000    ;  0
        .word $0000, $0000    ;  0
        .word $0000, $0001    ;  1.0
        .word $0000, $0000    ;  0
        
        CLIP_VERTICES   .ds 256
        

PROJECT_WORLD_VERTICES:
        ; Projection matrix
        lda #<PROJECTION_MATRIX
        sta MAT4_MATRIX_PTR
        lda #>PROJECTION_MATRIX
        sta MAT4_MATRIX_PTR+1

        ; Source vertices (uses generic MODEL_VERTICES_PTR)
        lda MODEL_VERTICES_PTR
        sta PROJ_SRC_PTR
        lda MODEL_VERTICES_PTR+1
        sta PROJ_SRC_PTR+1

        ; Destination vertices
        lda #<CLIP_VERTICES
        sta PROJ_DST_PTR
        lda #>CLIP_VERTICES
        sta PROJ_DST_PTR+1

        lda MODEL_VERTEX_COUNT
        sta PROJ_VERTICES_LEFT

@ProjectLoop:
        lda PROJ_SRC_PTR
        sta MAT4_VIN_PTR
        lda PROJ_SRC_PTR+1
        sta MAT4_VIN_PTR+1

        lda PROJ_DST_PTR
        sta MAT4_VOUT_PTR
        lda PROJ_DST_PTR+1
        sta MAT4_VOUT_PTR+1

        jsr PROJECT_VECTOR

        ; Advance source by 16 bytes
        clc
        lda PROJ_SRC_PTR
        adc #16
        sta PROJ_SRC_PTR
        bcc @SourceReady
        inc PROJ_SRC_PTR+1
@SourceReady:

        ; Advance destination by 16 bytes
        clc
        lda PROJ_DST_PTR
        adc #16
        sta PROJ_DST_PTR
        bcc @DestinationReady
        inc PROJ_DST_PTR+1
@DestinationReady:

        dec PROJ_VERTICES_LEFT
        bne @ProjectLoop
        rts


DIVIDE_CLIP_VERTICES:
        lda #<CLIP_VERTICES
        sta PROJ_SRC_PTR
        lda #>CLIP_VERTICES
        sta PROJ_SRC_PTR+1

        lda #<NDC_VERTICES
        sta PROJ_DST_PTR
        lda #>NDC_VERTICES
        sta PROJ_DST_PTR+1

        lda MODEL_VERTEX_COUNT
        sta PROJ_VERTICES_LEFT

@DivideVertex:
        ; X / W
        lda PROJ_SRC_PTR
        sta FIX16_A_PTR
        lda PROJ_SRC_PTR+1
        sta FIX16_A_PTR+1

        clc
        lda PROJ_SRC_PTR
        adc #12
        sta FIX16_B_PTR
        lda PROJ_SRC_PTR+1
        adc #0
        sta FIX16_B_PTR+1

        lda PROJ_DST_PTR
        sta FIX16_RESULT_PTR
        lda PROJ_DST_PTR+1
        sta FIX16_RESULT_PTR+1

        jsr FIX16_DIV

        ; Y / W
        clc
        lda PROJ_SRC_PTR
        adc #4
        sta FIX16_A_PTR
        lda PROJ_SRC_PTR+1
        adc #0
        sta FIX16_A_PTR+1

        clc
        lda PROJ_SRC_PTR
        adc #12
        sta FIX16_B_PTR
        lda PROJ_SRC_PTR+1
        adc #0
        sta FIX16_B_PTR+1

        clc
        lda PROJ_DST_PTR
        adc #4
        sta FIX16_RESULT_PTR
        lda PROJ_DST_PTR+1
        adc #0
        sta FIX16_RESULT_PTR+1

        jsr FIX16_DIV

        ; Z / W
        clc
        lda PROJ_SRC_PTR
        adc #8
        sta FIX16_A_PTR
        lda PROJ_SRC_PTR+1
        adc #0
        sta FIX16_A_PTR+1

        clc
        lda PROJ_SRC_PTR
        adc #12
        sta FIX16_B_PTR
        lda PROJ_SRC_PTR+1
        adc #0
        sta FIX16_B_PTR+1

        clc
        lda PROJ_DST_PTR
        adc #8
        sta FIX16_RESULT_PTR
        lda PROJ_DST_PTR+1
        adc #0
        sta FIX16_RESULT_PTR+1

        jsr FIX16_DIV

        ; Preserve original W
        ldy #12
@CopyW:
        lda (PROJ_SRC_PTR),y
        sta (PROJ_DST_PTR),y
        iny
        cpy #16
        bne @CopyW

        clc
        lda PROJ_SRC_PTR
        adc #16
        sta PROJ_SRC_PTR
        bcc @SourceReady
        inc PROJ_SRC_PTR+1
@SourceReady:

        clc
        lda PROJ_DST_PTR
        adc #16
        sta PROJ_DST_PTR
        bcc @DestinationReady
        inc PROJ_DST_PTR+1
@DestinationReady:

        dec PROJ_VERTICES_LEFT
        beq @exit
        jmp @DivideVertex
@exit:
        rts
        
        
SCREEN_MUL_SIGN: .ds 1

;********************************************
;* SCREEN_MUL160
;*
;* SCREEN_TEMP_RESULT = SCREEN_TEMP_A * 160
;*
;* Signed 16.16 multiplication by 160.
;********************************************

SCREEN_MUL160:

        ; Save sign
        lda #0
        sta SCREEN_MUL_SIGN

        lda SCREEN_TEMP_A+3
        bpl @Positive

        inc SCREEN_MUL_SIGN

        ; Absolute value
        sec
        lda #0
        sbc SCREEN_TEMP_A
        sta SCREEN_TEMP_A
        lda #0
        sbc SCREEN_TEMP_A+1
        sta SCREEN_TEMP_A+1
        lda #0
        sbc SCREEN_TEMP_A+2
        sta SCREEN_TEMP_A+2
        lda #0
        sbc SCREEN_TEMP_A+3
        sta SCREEN_TEMP_A+3

@Positive:

        ; B = A
        ldx #3
@Copy:
        lda SCREEN_TEMP_A,x
        sta SCREEN_TEMP_B,x
        sta SCREEN_TEMP_RESULT,x
        dex
        bpl @Copy

        ; B = A * 128
        ldx #7
@Shift128:
        asl SCREEN_TEMP_B
        rol SCREEN_TEMP_B+1
        rol SCREEN_TEMP_B+2
        rol SCREEN_TEMP_B+3
        dex
        bne @Shift128

        ; RESULT = A * 32
        ldx #5
@Shift32:
        asl SCREEN_TEMP_RESULT
        rol SCREEN_TEMP_RESULT+1
        rol SCREEN_TEMP_RESULT+2
        rol SCREEN_TEMP_RESULT+3
        dex
        bne @Shift32

        ; RESULT = A*128 + A*32
        clc
        lda SCREEN_TEMP_RESULT
        adc SCREEN_TEMP_B
        sta SCREEN_TEMP_RESULT
        lda SCREEN_TEMP_RESULT+1
        adc SCREEN_TEMP_B+1
        sta SCREEN_TEMP_RESULT+1
        lda SCREEN_TEMP_RESULT+2
        adc SCREEN_TEMP_B+2
        sta SCREEN_TEMP_RESULT+2
        lda SCREEN_TEMP_RESULT+3
        adc SCREEN_TEMP_B+3
        sta SCREEN_TEMP_RESULT+3

        ; Restore sign
        lda SCREEN_MUL_SIGN
        beq @Done

        sec
        lda #0
        sbc SCREEN_TEMP_RESULT
        sta SCREEN_TEMP_RESULT
        lda #0
        sbc SCREEN_TEMP_RESULT+1
        sta SCREEN_TEMP_RESULT+1
        lda #0
        sbc SCREEN_TEMP_RESULT+2
        sta SCREEN_TEMP_RESULT+2
        lda #0
        sbc SCREEN_TEMP_RESULT+3
        sta SCREEN_TEMP_RESULT+3

@Done:
        rts
        
;********************************************
;* SCREEN_MUL100
;*
;* SCREEN_TEMP_RESULT = SCREEN_TEMP_A * 100
;*
;* Signed 16.16 multiplication by 100.
;********************************************

SCREEN_MUL100:

        ; Save sign
        lda #0
        sta SCREEN_MUL_SIGN

        lda SCREEN_TEMP_A+3
        bpl @Positive

        inc SCREEN_MUL_SIGN

        ; Absolute value
        sec
        lda #0
        sbc SCREEN_TEMP_A
        sta SCREEN_TEMP_A
        lda #0
        sbc SCREEN_TEMP_A+1
        sta SCREEN_TEMP_A+1
        lda #0
        sbc SCREEN_TEMP_A+2
        sta SCREEN_TEMP_A+2
        lda #0
        sbc SCREEN_TEMP_A+3
        sta SCREEN_TEMP_A+3

@Positive:

        ; B = A
        ldx #3
@Copy:
        lda SCREEN_TEMP_A,x
        sta SCREEN_TEMP_B,x
        sta SCREEN_TEMP_RESULT,x
        dex
        bpl @Copy

        ; B = A * 64
        ldx #6
@Shift64:
        asl SCREEN_TEMP_B
        rol SCREEN_TEMP_B+1
        rol SCREEN_TEMP_B+2
        rol SCREEN_TEMP_B+3
        dex
        bne @Shift64

        ; RESULT = A * 32
        ldx #5
@Shift32:
        asl SCREEN_TEMP_RESULT
        rol SCREEN_TEMP_RESULT+1
        rol SCREEN_TEMP_RESULT+2
        rol SCREEN_TEMP_RESULT+3
        dex
        bne @Shift32

        ; RESULT = A*64 + A*32
        clc
        lda SCREEN_TEMP_RESULT
        adc SCREEN_TEMP_B
        sta SCREEN_TEMP_RESULT
        lda SCREEN_TEMP_RESULT+1
        adc SCREEN_TEMP_B+1
        sta SCREEN_TEMP_RESULT+1
        lda SCREEN_TEMP_RESULT+2
        adc SCREEN_TEMP_B+2
        sta SCREEN_TEMP_RESULT+2
        lda SCREEN_TEMP_RESULT+3
        adc SCREEN_TEMP_B+3
        sta SCREEN_TEMP_RESULT+3

        ; Add A * 4
        asl SCREEN_TEMP_A
        rol SCREEN_TEMP_A+1
        rol SCREEN_TEMP_A+2
        rol SCREEN_TEMP_A+3

        asl SCREEN_TEMP_A
        rol SCREEN_TEMP_A+1
        rol SCREEN_TEMP_A+2
        rol SCREEN_TEMP_A+3

        clc
        lda SCREEN_TEMP_RESULT
        adc SCREEN_TEMP_A
        sta SCREEN_TEMP_RESULT
        lda SCREEN_TEMP_RESULT+1
        adc SCREEN_TEMP_A+1
        sta SCREEN_TEMP_RESULT+1
        lda SCREEN_TEMP_RESULT+2
        adc SCREEN_TEMP_A+2
        sta SCREEN_TEMP_RESULT+2
        lda SCREEN_TEMP_RESULT+3
        adc SCREEN_TEMP_A+3
        sta SCREEN_TEMP_RESULT+3

        ; Restore sign
        lda SCREEN_MUL_SIGN
        beq @Done

        sec
        lda #0
        sbc SCREEN_TEMP_RESULT
        sta SCREEN_TEMP_RESULT
        lda #0
        sbc SCREEN_TEMP_RESULT+1
        sta SCREEN_TEMP_RESULT+1
        lda #0
        sbc SCREEN_TEMP_RESULT+2
        sta SCREEN_TEMP_RESULT+2
        lda #0
        sbc SCREEN_TEMP_RESULT+3
        sta SCREEN_TEMP_RESULT+3

@Done:
        rts
        
        
;********************************************
;* CONVERT_NDC_TO_SCREEN                    *
;*                                          *
;* Input:  NDC_VERTICES                     *
;* Output: SCREEN_VERTICES                  *
;*                                          *
;* Each output vertex:                      *
;*   +0 = X low                             *
;*   +1 = X high                            *
;*   +2 = Y                                 *
;********************************************

CONVERT_NDC_TO_SCREEN:        
        lda #<NDC_VERTICES
        sta SCREEN_SRC_PTR
        lda #>NDC_VERTICES
        sta SCREEN_SRC_PTR+1

        lda #<SCREEN_VERTICES
        sta SCREEN_DST_PTR
        lda #>SCREEN_VERTICES
        sta SCREEN_DST_PTR+1

        lda MODEL_VERTEX_COUNT
        sta SCREEN_VERTICES_LEFT

@ConvertVertex:

        ;------------------------------------
        ; X = (NDC X + 1.0) * 160
        ;------------------------------------

        ldy #0
@CopyX:
        lda (SCREEN_SRC_PTR),y
        sta SCREEN_TEMP_A,y
        iny
        cpy #4
        bne @CopyX
        
        ADD_FIX16 SCREEN_TEMP_A, SCREEN_ONE, SCREEN_TEMP_A
        
        lda #<SCREEN_TEMP_A
        sta FIX16_A_PTR
        lda #>SCREEN_TEMP_A
        sta FIX16_A_PTR+1

        lda #<SCREEN_SCALE_X
        sta FIX16_B_PTR
        lda #>SCREEN_SCALE_X
        sta FIX16_B_PTR+1

        lda #<SCREEN_TEMP_RESULT
        sta FIX16_RESULT_PTR
        lda #>SCREEN_TEMP_RESULT
        sta FIX16_RESULT_PTR+1


;        jsr SCREEN_MUL160

        jsr FIX16_MUL

        ; Store integer X
        ldy #0
        lda SCREEN_TEMP_RESULT+2
        sta (SCREEN_DST_PTR),y
        iny
        lda SCREEN_TEMP_RESULT+3
        sta (SCREEN_DST_PTR),y

        ;------------------------------------
        ; Y = (1.0 - NDC Y) * 100
        ;------------------------------------

        ldy #4
@CopyY:
        lda (SCREEN_SRC_PTR),y
        sta SCREEN_TEMP_B-4,y
        iny
        cpy #8
        bne @CopyY

        ; SCREEN_TEMP_A = 1.0 - NDC Y
        sec
        lda SCREEN_ONE
        sbc SCREEN_TEMP_B
        sta SCREEN_TEMP_A

        lda SCREEN_ONE+1
        sbc SCREEN_TEMP_B+1
        sta SCREEN_TEMP_A+1

        lda SCREEN_ONE+2
        sbc SCREEN_TEMP_B+2
        sta SCREEN_TEMP_A+2

        lda SCREEN_ONE+3
        sbc SCREEN_TEMP_B+3
        sta SCREEN_TEMP_A+3

        lda #<SCREEN_TEMP_A
        sta FIX16_A_PTR
        lda #>SCREEN_TEMP_A
        sta FIX16_A_PTR+1

        lda #<SCREEN_SCALE_Y
        sta FIX16_B_PTR
        lda #>SCREEN_SCALE_Y
        sta FIX16_B_PTR+1

        lda #<SCREEN_TEMP_RESULT
        sta FIX16_RESULT_PTR
        lda #>SCREEN_TEMP_RESULT
        sta FIX16_RESULT_PTR+1
        
        ; jsr FIX16_MUL
        jsr SCREEN_MUL100
        
        ; Store integer Y
        ldy #2
        lda SCREEN_TEMP_RESULT+2
        sta (SCREEN_DST_PTR),y

        ;------------------------------------
        ; Advance pointers
        ;------------------------------------

        clc
        lda SCREEN_SRC_PTR
        adc #16
        sta SCREEN_SRC_PTR
        bcc @SourceReady
        inc SCREEN_SRC_PTR+1

@SourceReady:

        clc
        lda SCREEN_DST_PTR
        adc #3
        sta SCREEN_DST_PTR
        bcc @DestinationReady
        inc SCREEN_DST_PTR+1

@DestinationReady:
        dec SCREEN_VERTICES_LEFT
        beq @exit
        jmp @ConvertVertex
@exit
        rts
        
 
 RECIP_W:
        .ds 4
;********************************************
;* DIVIDE_CLIP_VERTICES_XY
;*
;* Optimized perspective divide for wireframe
;*
;* Calculates:
;*   RECIP_W = 1.0 / W
;*   X = X * RECIP_W
;*   Y = Y * RECIP_W
;*
;* Z and W are preserved in clip coordinates.
;*
;* One division and two multiplications
;* per vertex.
;********************************************

DIVIDE_CLIP_VERTICES_XY:

        ; Source: CLIP_VERTICES
        lda #<CLIP_VERTICES
        sta PROJ_SRC_PTR
        lda #>CLIP_VERTICES
        sta PROJ_SRC_PTR+1

        ; Destination: NDC_VERTICES
        lda #<NDC_VERTICES
        sta PROJ_DST_PTR
        lda #>NDC_VERTICES
        sta PROJ_DST_PTR+1

        lda MODEL_VERTEX_COUNT
        sta PROJ_VERTICES_LEFT

@DivideXYVertex:

        ;------------------------------------
        ; RECIP_W = 1.0 / W
        ;------------------------------------

        ; Dividend = 1.0
        lda #<SCREEN_ONE
        sta FIX16_A_PTR
        lda #>SCREEN_ONE
        sta FIX16_A_PTR+1

        ; Divisor = source W (+12)
        clc
        lda PROJ_SRC_PTR
        adc #12
        sta FIX16_B_PTR
        lda PROJ_SRC_PTR+1
        adc #0
        sta FIX16_B_PTR+1

        ; Result = RECIP_W
        lda #<RECIP_W
        sta FIX16_RESULT_PTR
        lda #>RECIP_W
        sta FIX16_RESULT_PTR+1

        jsr FIX16_DIV

        ;------------------------------------
        ; X = X * RECIP_W
        ;------------------------------------

        ; Input X
        lda PROJ_SRC_PTR
        sta FIX16_A_PTR
        lda PROJ_SRC_PTR+1
        sta FIX16_A_PTR+1

        ; Multiplier = RECIP_W
        lda #<RECIP_W
        sta FIX16_B_PTR
        lda #>RECIP_W
        sta FIX16_B_PTR+1

        ; Output X
        lda PROJ_DST_PTR
        sta FIX16_RESULT_PTR
        lda PROJ_DST_PTR+1
        sta FIX16_RESULT_PTR+1

        jsr FIX16_MUL

        ;------------------------------------
        ; Y = Y * RECIP_W
        ;------------------------------------

        ; Input Y (+4)
        clc
        lda PROJ_SRC_PTR
        adc #4
        sta FIX16_A_PTR
        lda PROJ_SRC_PTR+1
        adc #0
        sta FIX16_A_PTR+1

        ; Multiplier = RECIP_W
        lda #<RECIP_W
        sta FIX16_B_PTR
        lda #>RECIP_W
        sta FIX16_B_PTR+1

        ; Output Y (+4)
        clc
        lda PROJ_DST_PTR
        adc #4
        sta FIX16_RESULT_PTR
        lda PROJ_DST_PTR+1
        adc #0
        sta FIX16_RESULT_PTR+1

        jsr FIX16_MUL

        ;------------------------------------
        ; Preserve original Z and W
        ;------------------------------------

        ldy #8

@CopyZW:
        lda (PROJ_SRC_PTR),y
        sta (PROJ_DST_PTR),y
        iny
        cpy #16
        bne @CopyZW

        ;------------------------------------
        ; Advance to next vertex
        ;------------------------------------

        clc
        lda PROJ_SRC_PTR
        adc #16
        sta PROJ_SRC_PTR
        bcc @SourceReady
        inc PROJ_SRC_PTR+1

@SourceReady:

        clc
        lda PROJ_DST_PTR
        adc #16
        sta PROJ_DST_PTR
        bcc @DestinationReady
        inc PROJ_DST_PTR+1

@DestinationReady:

        dec PROJ_VERTICES_LEFT
        beq @Exit
        jmp @DivideXYVertex

@Exit:
        rts
        