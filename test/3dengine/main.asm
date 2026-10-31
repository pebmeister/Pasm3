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
; 1. Generate component matrices
        SET_SCALE               MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z  ; result in SCALING_MATRIX
        SET_ROTATION            MY_ROT_X, MY_ROT_Y, MY_ROT_Z        ; result ROTATION_MATRIX
        SET_TRANSLATION         MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z  ; result TRANSLATION_MATRIX

        ; 2. Concatenate: Temp = Rotation * Scale
        
        CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, MAT_TEMP
        CALL_MAT4_MUL TRANSLATION_MATRIX, MAT_TEMP, WORLD_MATRIX
        jsr MAT4_MUL
        
        jsr CLEARSCREEN
        PRINT_MAT WORLD_MATRIX, 4, 2
        rts
        
MY_SCALE_X
        .word $0000, $00001
MY_SCALE_Y
        .word $0000, $00001
MY_SCALE_Z
        .word $0000, $00001
        

MY_TRANS_X
        .word $0000, $00001
MY_TRANS_Y
        .word $0000, $00001
MY_TRANS_Z
        .word $0000, $00001

MY_ROT_X .byte 32
MY_ROT_Y .byte 32
MY_ROT_Z .byte 32


