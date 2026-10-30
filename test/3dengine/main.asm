; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================

        .basic_hdr

        jsr Test

@MainWait:
        jmp @MainWait


;********************************************
;* TEST
;********************************************

Test:
        SET_ROTATION 32, 32, 32
        
        jsr CLEARSCREEN
        PRINT_MAT ROTATION_MATRIX, 8, 2
        rts
        
        jsr BUILD_MODEL_MATRIX

        ;------------------------------------
        ; Transform test vector
        ;------------------------------------

        lda #<MODEL_MATRIX
        sta MAT4_MATRIX_PTR
        lda #>MODEL_MATRIX
        sta MAT4_MATRIX_PTR+1

        lda #<TEST_VECTOR
        sta MAT4_VIN_PTR
        lda #>TEST_VECTOR
        sta MAT4_VIN_PTR+1

        lda #<WORLD_VECTOR
        sta MAT4_VOUT_PTR
        lda #>WORLD_VECTOR
        sta MAT4_VOUT_PTR+1

        jsr MAT4_VECTOR_MUL

        jsr CLEARSCREEN
        PRINT_VECTOR WORLD_VECTOR, 4

        rts


;********************************************
;* BUILD_MODEL_MATRIX
;*
;* Builds:
;* MODEL_MATRIX = T * Rz * S
;*
;* Inputs:
;* ROT_Z_ANGLE
;* TRANSLATION_MATRIX
;* SCALING_MATRIX
;*
;* Output:
;* MODEL_MATRIX
;*
;* Uses:
;* MAT_B
;* ROT_SCALE_MATRIX
;********************************************

BUILD_MODEL_MATRIX:

        ;------------------------------------
        ; Generate Z rotation matrix
        ; Result is placed in MAT_B
        ;------------------------------------

        lda #32
        sta ROT_Z_ANGLE
        jsr ROTATION_Z

        ;------------------------------------
        ; Calculate:
        ; ROT_SCALE_MATRIX = MAT_B * SCALING_MATRIX
        ;------------------------------------

        CALL_MAT4_MUL MAT_B, SCALING_MATRIX, ROT_SCALE_MATRIX

        ;------------------------------------
        ; Calculate:
        ; MODEL_MATRIX = TRANSLATION_MATRIX * ROT_SCALE_MATRIX
        ;------------------------------------

        CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX
        rts


;********************************************
;* TEST DATA
;********************************************

TEST_VECTOR:

        .word $0000,$0001      ; X = 1
        .word $0000,$0001      ; Y = 1
        .word $0000,$0001      ; Z = 1
        .word $0000,$0001      ; W = 1


RESULT_VECTOR:
        .ds 16


WORLD_VECTOR:
        .ds 16
