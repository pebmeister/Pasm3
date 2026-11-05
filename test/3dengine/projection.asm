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

        ; Source vertices
        lda #<WORLD_VERTICES
        sta PROJ_SRC_PTR
        lda #>WORLD_VERTICES
        sta PROJ_SRC_PTR+1

        ; Destination vertices
        lda #<CLIP_VERTICES
        sta PROJ_DST_PTR
        lda #>CLIP_VERTICES
        sta PROJ_DST_PTR+1

        lda PYRAMID_VERTEX_COUNT
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

        jsr MAT4_VECTOR_MUL

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
        
        
NDC_VERTICES    .ds 256
  
;********************************************
;* DIVIDE_CLIP_VERTICES                     *
;*                                          *
;* Converts clip coordinates to NDC         *
;* X = X / W                                *
;* Y = Y / W                                *
;* Z = Z / W                                *
;* W = preserved                            *
;********************************************

DIVIDE_CLIP_VERTICES:

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

        lda PYRAMID_VERTEX_COUNT
        sta PROJ_VERTICES_LEFT

@DivideVertex:

        ;------------------------------------
        ; X / W
        ;------------------------------------

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

        ;------------------------------------
        ; Y / W
        ;------------------------------------

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

        ;------------------------------------
        ; Z / W
        ;------------------------------------

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

        ;------------------------------------
        ; Preserve original W
        ;------------------------------------

        ldy #12

@CopyW:
        lda (PROJ_SRC_PTR),y
        sta (PROJ_DST_PTR),y
        iny
        cpy #16
        bne @CopyW

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
        beq @exit
        jmp @DivideVertex
@exit
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

        lda PYRAMID_VERTEX_COUNT
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
        
        jsr FIX16_MUL

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
        