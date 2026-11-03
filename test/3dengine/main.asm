; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================

        .basic_hdr

        jsr TestRot

@MainWait:
        ;lda #COLOR_GREEN
        ;jsr _HGRFColor
       ; jsr TEST_MANUAL_LINE
        jmp @MainWait


TestRot:
        SET_SCALE       MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z
        SET_ROTATION    MY_ROT_X, MY_ROT_Y, MY_ROT_Z
        SET_TRANSLATION MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z

        CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
        CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX

        jsr TRANSFORM_MODEL_VERTICES
        
        jsr CLEARSCREEN 
        PRINT_MAT WORLD_VERTICES, 8, 2
        rts

BUILD_MODEL
        SET_SCALE       MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z
        SET_ROTATION    MY_ROT_X, MY_ROT_Y, MY_ROT_Z
        SET_TRANSLATION MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z

        CALL_MAT4_MUL   ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
        CALL_MAT4_MUL   TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX      
        rts
        
        
; ============================================
; INITIAL TRS (Transform-Rotate-Scale) VALUES
; ============================================
; Rotation angles (0 to 255 for a full circle)
MY_ROT_X        .byte 32   
MY_ROT_Y        .byte 32
MY_ROT_Z        .byte 32

; Scale: 1.0 (format: .word fractional, integer)
MY_SCALE_X      .word $0000, $0001
MY_SCALE_Y      .word $0000, $0001
MY_SCALE_Z      .word $0000, $0001

; Translation: Center X/Y, push forward on Z (e.g., Z = 2.5)
MY_TRANS_X      .word $0000, $0000   ; X = 0.0 (centered horizontally)
MY_TRANS_Y      .word $0000, $0000   ; Y = 0.0 (centered vertically)
MY_TRANS_Z      .word $8000, $0002   ; Z = 2.5 (pushed away from camera into view)

; ============================================
; DIAGNOSTIC TEST: Draw a single manual line
; ============================================
TEST_MANUAL_LINE:
        MOVE16I X0, 10       
        MOVE8I  Y0, 10
        MOVE16I X1, 300
        MOVE8I  Y1, 10

        ; 3. Call gr library line drawer directly
        jsr _Line

        rts
