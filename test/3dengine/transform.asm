;********************************************
;* TRANSFORM_PYRAMID_VERTICES               *
;*                                          *
;* Specialized transform for five pyramid  *
;* vertices.                                *
;*                                          *
;* Input:                                   *
;*   MODEL_MATRIX                           *
;*                                          *
;* Output:                                  *
;*   WORLD_VERTICES                         *
;*                                          *
;* Scratch:                                 *
;*   SCREEN_TEMP_A                          *
;*   SCREEN_TEMP_B                          *
;********************************************

TRANSFORM_PYRAMID_VERTICES:

        ;====================================
        ; ROW 0 - X coordinates
        ;====================================

        ; P = M03 - M01
        ; N = M03 + M01

        SUB_FIX16 MODEL_MATRIX+12, MODEL_MATRIX+4, SCREEN_TEMP_A
        ADD_FIX16 MODEL_MATRIX+12, MODEL_MATRIX+4, SCREEN_TEMP_B

        ; V0 X = P - M00 - M02
        SUB_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+0, WORLD_VERTICES+0
        SUB_FIX16 WORLD_VERTICES+0, MODEL_MATRIX+8, WORLD_VERTICES+0

        ; V1 X = P + M00 - M02
        ADD_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+0, WORLD_VERTICES+16
        SUB_FIX16 WORLD_VERTICES+16, MODEL_MATRIX+8, WORLD_VERTICES+16

        ; V2 X = P + M00 + M02
        ADD_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+0, WORLD_VERTICES+32
        ADD_FIX16 WORLD_VERTICES+32, MODEL_MATRIX+8, WORLD_VERTICES+32

        ; V3 X = P - M00 + M02
        SUB_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+0, WORLD_VERTICES+48
        ADD_FIX16 WORLD_VERTICES+48, MODEL_MATRIX+8, WORLD_VERTICES+48

        ; V4 X = N
        ADD_FIX16 MODEL_MATRIX+12, MODEL_MATRIX+4, WORLD_VERTICES+64


        ;====================================
        ; ROW 1 - Y coordinates
        ;====================================

        ; P = M13 - M11
        ; N = M13 + M11

        SUB_FIX16 MODEL_MATRIX+28, MODEL_MATRIX+20, SCREEN_TEMP_A
        ADD_FIX16 MODEL_MATRIX+28, MODEL_MATRIX+20, SCREEN_TEMP_B

        ; V0 Y = P - M10 - M12
        SUB_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+16, WORLD_VERTICES+4
        SUB_FIX16 WORLD_VERTICES+4, MODEL_MATRIX+24, WORLD_VERTICES+4

        ; V1 Y = P + M10 - M12
        ADD_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+16, WORLD_VERTICES+20
        SUB_FIX16 WORLD_VERTICES+20, MODEL_MATRIX+24, WORLD_VERTICES+20

        ; V2 Y = P + M10 + M12
        ADD_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+16, WORLD_VERTICES+36
        ADD_FIX16 WORLD_VERTICES+36, MODEL_MATRIX+24, WORLD_VERTICES+36

        ; V3 Y = P - M10 + M12
        SUB_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+16, WORLD_VERTICES+52
        ADD_FIX16 WORLD_VERTICES+52, MODEL_MATRIX+24, WORLD_VERTICES+52

        ; V4 Y = N
        ADD_FIX16 MODEL_MATRIX+28, MODEL_MATRIX+20, WORLD_VERTICES+68


        ;====================================
        ; ROW 2 - Z coordinates
        ;====================================

        ; P = M23 - M21
        ; N = M23 + M21

        SUB_FIX16 MODEL_MATRIX+44, MODEL_MATRIX+36, SCREEN_TEMP_A
        ADD_FIX16 MODEL_MATRIX+44, MODEL_MATRIX+36, SCREEN_TEMP_B

        ; V0 Z = P - M20 - M22
        SUB_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+32, WORLD_VERTICES+8
        SUB_FIX16 WORLD_VERTICES+8, MODEL_MATRIX+40, WORLD_VERTICES+8

        ; V1 Z = P + M20 - M22
        ADD_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+32, WORLD_VERTICES+24
        SUB_FIX16 WORLD_VERTICES+24, MODEL_MATRIX+40, WORLD_VERTICES+24

        ; V2 Z = P + M20 + M22
        ADD_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+32, WORLD_VERTICES+40
        ADD_FIX16 WORLD_VERTICES+40, MODEL_MATRIX+40, WORLD_VERTICES+40

        ; V3 Z = P - M20 + M22
        SUB_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+32, WORLD_VERTICES+56
        ADD_FIX16 WORLD_VERTICES+56, MODEL_MATRIX+40, WORLD_VERTICES+56

        ; V4 Z = N
        ADD_FIX16 MODEL_MATRIX+44, MODEL_MATRIX+36, WORLD_VERTICES+72


        ;====================================
        ; W = 1.0 for all five vertices
        ;====================================

        lda #$00

        sta WORLD_VERTICES+12
        sta WORLD_VERTICES+13
        sta WORLD_VERTICES+15

        sta WORLD_VERTICES+28
        sta WORLD_VERTICES+29
        sta WORLD_VERTICES+31

        sta WORLD_VERTICES+44
        sta WORLD_VERTICES+45
        sta WORLD_VERTICES+47

        sta WORLD_VERTICES+60
        sta WORLD_VERTICES+61
        sta WORLD_VERTICES+63

        sta WORLD_VERTICES+76
        sta WORLD_VERTICES+77
        sta WORLD_VERTICES+79

        lda #$01

        sta WORLD_VERTICES+14
        sta WORLD_VERTICES+30
        sta WORLD_VERTICES+46
        sta WORLD_VERTICES+62
        sta WORLD_VERTICES+78

        rts

TRANSFORM_WORLD_VERTICES:

        ; Set model matrix pointer
        lda #<MODEL_MATRIX
        sta MAT4_MATRIX_PTR
        lda #>MODEL_MATRIX
        sta MAT4_MATRIX_PTR+1

        ; Initialize source pointer
        lda #<PYRAMID_VERTICES
        sta @MODEL_SRC_PTR
        lda #>PYRAMID_VERTICES
        sta @MODEL_SRC_PTR+1

        ; Initialize destination pointer
        lda #<WORLD_VERTICES
        sta @MODEL_DST_PTR
        lda #>WORLD_VERTICES
        sta @MODEL_DST_PTR+1

        ; Eight vertices
        lda PYRAMID_VERTEX_COUNT
        sta @WORLD_VERTICES_LEFT

@TransformLoop:

        ; Set input vector pointer
        lda @MODEL_SRC_PTR
        sta MAT4_VIN_PTR
        lda @MODEL_SRC_PTR+1
        sta MAT4_VIN_PTR+1

        ; Set output vector pointer
        lda @MODEL_DST_PTR
        sta MAT4_VOUT_PTR
        lda @MODEL_DST_PTR+1
        sta MAT4_VOUT_PTR+1

        ; Transform vertex
        jsr MAT3_VECTOR_MUL

        ; Advance source pointer by 16
        clc
        lda @MODEL_SRC_PTR
        adc #16
        sta @MODEL_SRC_PTR
        bcc @SourceReady
        inc @MODEL_SRC_PTR+1

@SourceReady:

        ; Advance destination pointer by 16
        clc
        lda @MODEL_DST_PTR
        adc #16
        sta @MODEL_DST_PTR
        bcc @DestinationReady
        inc @MODEL_DST_PTR+1

@DestinationReady:

        dec @WORLD_VERTICES_LEFT
        bne @TransformLoop

        rts
        
@MODEL_SRC_PTR:
        .word 0

@MODEL_DST_PTR:
        .word 0

@WORLD_VERTICES_LEFT:
        .byte 0
        
        
 