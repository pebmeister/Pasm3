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

;********************************************
;* TRANSFORM_CUBE_VERTICES                 *
;*                                          *
;* Specialized transform for eight cube     *
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
;*   SCREEN_TEMP_RESULT                     *
;********************************************

TRANSFORM_CUBE_VERTICES:

        ;====================================
        ; ROW 0 - X coordinates
        ;====================================

        ; P = M03 - M01
        ; N = M03 + M01

        SUB_FIX16 MODEL_MATRIX+12, MODEL_MATRIX+4, SCREEN_TEMP_A
        ADD_FIX16 MODEL_MATRIX+12, MODEL_MATRIX+4, SCREEN_TEMP_B

        ;------------------------------------
        ; V0 X = P - M02 - M00
        ; V1 X = P - M02 + M00
        ;------------------------------------

        SUB_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+8, SCREEN_TEMP_RESULT

        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+0, WORLD_VERTICES+0
        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+0, WORLD_VERTICES+16

        ;------------------------------------
        ; V2 X = N - M02 + M00
        ; V3 X = N - M02 - M00
        ;------------------------------------

        SUB_FIX16 SCREEN_TEMP_B, MODEL_MATRIX+8, SCREEN_TEMP_RESULT

        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+0, WORLD_VERTICES+32
        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+0, WORLD_VERTICES+48

        ;------------------------------------
        ; V4 X = P + M02 - M00
        ; V5 X = P + M02 + M00
        ;------------------------------------

        ADD_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+8, SCREEN_TEMP_RESULT

        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+0, WORLD_VERTICES+64
        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+0, WORLD_VERTICES+80

        ;------------------------------------
        ; V6 X = N + M02 + M00
        ; V7 X = N + M02 - M00
        ;------------------------------------

        ADD_FIX16 SCREEN_TEMP_B, MODEL_MATRIX+8, SCREEN_TEMP_RESULT

        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+0, WORLD_VERTICES+96
        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+0, WORLD_VERTICES+112


        ;====================================
        ; ROW 1 - Y coordinates
        ;====================================

        ; P = M13 - M11
        ; N = M13 + M11

        SUB_FIX16 MODEL_MATRIX+28, MODEL_MATRIX+20, SCREEN_TEMP_A
        ADD_FIX16 MODEL_MATRIX+28, MODEL_MATRIX+20, SCREEN_TEMP_B

        ;------------------------------------
        ; V0 Y = P - M12 - M10
        ; V1 Y = P - M12 + M10
        ;------------------------------------

        SUB_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+24, SCREEN_TEMP_RESULT

        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+16, WORLD_VERTICES+4
        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+16, WORLD_VERTICES+20

        ;------------------------------------
        ; V2 Y = N - M12 + M10
        ; V3 Y = N - M12 - M10
        ;------------------------------------

        SUB_FIX16 SCREEN_TEMP_B, MODEL_MATRIX+24, SCREEN_TEMP_RESULT

        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+16, WORLD_VERTICES+36
        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+16, WORLD_VERTICES+52

        ;------------------------------------
        ; V4 Y = P + M12 - M10
        ; V5 Y = P + M12 + M10
        ;------------------------------------

        ADD_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+24, SCREEN_TEMP_RESULT

        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+16, WORLD_VERTICES+68
        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+16, WORLD_VERTICES+84

        ;------------------------------------
        ; V6 Y = N + M12 + M10
        ; V7 Y = N + M12 - M10
        ;------------------------------------

        ADD_FIX16 SCREEN_TEMP_B, MODEL_MATRIX+24, SCREEN_TEMP_RESULT

        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+16, WORLD_VERTICES+100
        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+16, WORLD_VERTICES+116


        ;====================================
        ; ROW 2 - Z coordinates
        ;====================================

        ; P = M23 - M21
        ; N = M23 + M21

        SUB_FIX16 MODEL_MATRIX+44, MODEL_MATRIX+36, SCREEN_TEMP_A
        ADD_FIX16 MODEL_MATRIX+44, MODEL_MATRIX+36, SCREEN_TEMP_B

        ;------------------------------------
        ; V0 Z = P - M22 - M20
        ; V1 Z = P - M22 + M20
        ;------------------------------------

        SUB_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+40, SCREEN_TEMP_RESULT

        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+32, WORLD_VERTICES+8
        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+32, WORLD_VERTICES+24

        ;------------------------------------
        ; V2 Z = N - M22 + M20
        ; V3 Z = N - M22 - M20
        ;------------------------------------

        SUB_FIX16 SCREEN_TEMP_B, MODEL_MATRIX+40, SCREEN_TEMP_RESULT

        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+32, WORLD_VERTICES+40
        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+32, WORLD_VERTICES+56

        ;------------------------------------
        ; V4 Z = P + M22 - M20
        ; V5 Z = P + M22 + M20
        ;------------------------------------

        ADD_FIX16 SCREEN_TEMP_A, MODEL_MATRIX+40, SCREEN_TEMP_RESULT

        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+32, WORLD_VERTICES+72
        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+32, WORLD_VERTICES+88

        ;------------------------------------
        ; V6 Z = N + M22 + M20
        ; V7 Z = N + M22 - M20
        ;------------------------------------

        ADD_FIX16 SCREEN_TEMP_B, MODEL_MATRIX+40, SCREEN_TEMP_RESULT

        ADD_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+32, WORLD_VERTICES+104
        SUB_FIX16 SCREEN_TEMP_RESULT, MODEL_MATRIX+32, WORLD_VERTICES+120


        ;====================================
        ; W = 1.0 for all eight vertices
        ;====================================

        lda #$00

        ; V0
        sta WORLD_VERTICES+12
        sta WORLD_VERTICES+13
        sta WORLD_VERTICES+15

        ; V1
        sta WORLD_VERTICES+28
        sta WORLD_VERTICES+29
        sta WORLD_VERTICES+31

        ; V2
        sta WORLD_VERTICES+44
        sta WORLD_VERTICES+45
        sta WORLD_VERTICES+47

        ; V3
        sta WORLD_VERTICES+60
        sta WORLD_VERTICES+61
        sta WORLD_VERTICES+63

        ; V4
        sta WORLD_VERTICES+76
        sta WORLD_VERTICES+77
        sta WORLD_VERTICES+79

        ; V5
        sta WORLD_VERTICES+92
        sta WORLD_VERTICES+93
        sta WORLD_VERTICES+95

        ; V6
        sta WORLD_VERTICES+108
        sta WORLD_VERTICES+109
        sta WORLD_VERTICES+111

        ; V7
        sta WORLD_VERTICES+124
        sta WORLD_VERTICES+125
        sta WORLD_VERTICES+127

        lda #$01

        sta WORLD_VERTICES+14
        sta WORLD_VERTICES+30
        sta WORLD_VERTICES+46
        sta WORLD_VERTICES+62
        sta WORLD_VERTICES+78
        sta WORLD_VERTICES+94
        sta WORLD_VERTICES+110
        sta WORLD_VERTICES+126

        rts
        
TRANSFORM_WORLD_VERTICES:

        ; Set model matrix pointer
        lda #<MODEL_MATRIX
        sta MAT4_MATRIX_PTR
        lda #>MODEL_MATRIX
        sta MAT4_MATRIX_PTR+1

        ; Initialize source pointer
        lda MODEL_VERTICES_PTR        
        sta @MODEL_SRC_PTR
        lda MODEL_VERTICES_PTR + 1
        sta @MODEL_SRC_PTR+1

        ; Initialize destination pointer
        lda #<WORLD_VERTICES
        sta @MODEL_DST_PTR
        lda #>WORLD_VERTICES
        sta @MODEL_DST_PTR+1

        ; Eight vertices
        lda MODEL_VERTEX_COUNT
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
        
        
 