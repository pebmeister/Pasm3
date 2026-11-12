
;********************************************
;* MAT_I Idenity matrix
;********************************************
MAT_I:
        ; Row 0
        .word $0000, $0001    ; 1.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0

        ; Row 1
        .word $0000, $0000    ; 0.0
        .word $0000, $0001    ; 1.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0

        ; Row 2
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0001    ; 1.0
        .word $0000, $0000    ; 0.0

        ; Row 3
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0001    ; 1.0

ROT_X_MATRIX        .ds 64
ROT_Y_MATRIX        .ds 64
ROT_Z_MATRIX        .ds 64
ROTATION_MATRIX     .ds 64

SCALING_MATRIX      .ds 64
TRANSLATION_MATRIX  .ds 64


SCREEN_CENTER_X    = 160
SCREEN_CENTER_Y    = 100

ROT_TEMP_MATRIX:
        .ds 64
        
; Four-byte fixed-point values.
MAT_MUL_A:          .ds 8
MAT_MUL_B:          .ds 8
MAT_PRODUCT:        .ds 8
MAT_ACCUM:          .ds 8

        
SCALE_X:            .ds 4
SCALE_Y:            .ds 4
SCALE_Z:            .ds 4
TRANS_X:            .ds 4
TRANS_Y:            .ds 4
TRANS_Z:            .ds 4
        
; Formatter Workspace Variables
FMT_VAL         .ds 4
FMT_INTOFF      .ds 1
FMT_FRACOFF     .ds 1
FMT_DIG5IDX     .ds 1
FMT_NULLIDX     .ds 1
FMT_SIGNFLG     .ds 1
SCRATCH_FRAC    .ds 2
TEMP_PROD32     .ds 4

; Engine Buffers & Constants
STRING_BUF  .ds 50     

;********************************************
;* Rotation test variables
;********************************************
ROT_X_ANGLE:    .byte 32             ; 45
ROT_Y_ANGLE:    .byte 32             ; 45
ROT_Z_ANGLE:    .byte 32             ; 45

ROT_SINE:       .word $0000, $0000
ROT_COSINE:     .word $0000, $0000
ROT_NEG_SINE:   .word $0000, $0000
        
        
  ; Input vector: (1.0, 0.0, 0.0, 1.0)
VEC_IN:
                .word $0000, $0001
                .word $0000, $0000
                .word $0000, $0000
                .word $0000, $0001

; Output vector
VEC_OUT:
                .word $0000, $0000
                .word $0000, $0000
                .word $0000, $0000
                .word $0000, $0000
        
; Intermediate rotation matrices
MAT_ROT_X:      .ds 64
MAT_ROT_XY:     .ds 64

CURRENT_VERTEX_PTR .ds 2

;********************************************
;* Place pointers in zero page.
;********************************************
PC_SAVE        = *
;--------------------------------------
            * = 5
            XCOORD      .ds 2
            LOC         .ds 2
            DX          .ds 2
            DY          .ds 2
            XS          .ds 2
            YS          .ds 2
            K1          .ds 2
            K2          .ds 2
            _D          .ds 2
            _Y          .ds 1
            TMP         .ds 2
            YCOL        .ds 2
            COLORPTR    .ds 2
            X0          .ds 2
            X1          .ds 2
            Y0          .ds 1
            Y1          .ds 1
            XDIST       .ds 2
            YDIST       .ds 2
            StartX      .ds 2
            COLOR       .ds 1
            _X          = XCOORD
            COUNTER     = LOC
            CURLOC      = DX
            XD          = YCOL
;--------------------------------------
    SCREEN_SRC_PTR          .ds 2
    SCREEN_DST_PTR          .ds 2        
    SCREEN_VERTICES_LEFT    .ds 1
    SCREEN_TEMP_A           .ds 4
    SCREEN_TEMP_B           .ds 4
    SCREEN_TEMP_RESULT      .ds 4
        
            MAT_APTR        .ds 2       ; Current A element pointer
            MAT_BPTR        .ds 2       ; Current B element pointer
            MAT_CPTR        .ds 2       ; Current C element pointer
            MAT_AROW        .ds 2       ; Start of current A row
            MAT_BCOL        .ds 2       ; Start of current B column
            MAT4_A_PTR      .ds 2       ; Matrix A base argument
            MAT4_B_PTR      .ds 2       ; Matrix B base argument
            MAT4_C_PTR      .ds 2       ; Matrix C base argument
            MAT_ROW         .ds 1       ; Row counter (0-3)
            MAT_COL         .ds 1       ; Column counter (0-3)
            MAT_K           .ds 1       ; Inner loop counter (0-3)
            VEC_ROW         .ds 1
            VEC_K           .ds 1
            VEC_MPTR        .ds 2
            VEC_VPTR        .ds 2
            MAT4_VIN_PTR    .ds 2
            MAT4_VOUT_PTR   .ds 2
            MAT4_MATRIX_PTR .ds 2

       ;     *= $60
            FIXPTR           .ds 4
            TEMP16           .ds 2

            FIX16_SIGN       .ds 1
            STR_PTR          .ds 2

            ; --- Isolated Fixed-Point Math Workspace
            FIX16_A_PTR      .ds 4
            FIX16_B_PTR      .ds 4
            FIX16_RESULT_PTR .ds 4
            FIX16_WORK_A     .ds 4
            FIX16_WORK_B     .ds 4
            FIX16_WORK_RESULT .ds 4
            FIX16_SCRATCH    .ds 8       ; Dedicated extra room for 32-bit shifting           
            
            PROJ_SRC_PTR        .ds 2
            PROJ_DST_PTR        .ds 2
            PROJ_VERTICES_LEFT  .ds 1
            
            * = PC_SAVE

            DIV_WORKSPACE    .ds 18
            DIV_SIGN         .byte 0

            ; Display configuration
DISPLAY_ROWS:           .byte 4
DISPLAY_COLS:           .byte 1
DISPLAY_VECTORS:        .byte 1

;********************************************
;* INTERMEDIATE MATRICES
;********************************************
WORLD_MATRIX            .ds 64
MAT_TEMP                .ds 64

ROT_SCALE_MATRIX:       .ds 64
MODEL_MATRIX:           .ds 64
WORLD_VERTICES:         .ds 256
        
; --- Data Buffers & Lookups (Standard RAM) ---
TRANSFORMED_VERTEX      .ds 16  ; Temporary working buffer holding [x, y, z, w] in 16.16 fixed-point (4 bytes each)

SCREEN_VERTICES         .ds 256

SCREEN_ONE              .word $0000, $0001
SCREEN_SCALE_X          .word $0000, $00A0    ; 160.0
SCREEN_SCALE_Y          .word $0000, $0064    ; 100.0

DRAW_EDGE_INDEX         .ds 2
DRAW_EDGE_LEFT          .ds 2
DRAW_VERTEX_INDEX       .ds 2

; Scale: 1.0 (format: .word fractional, integer)
MY_SCALE_X              .word $0000, $0001
MY_SCALE_Y              .word $0000, $0001
MY_SCALE_Z              .word $0000, $0001

; Translation: Center X/Y, push forward on Z (e.g., Z = 2.5)
MY_TRANS_X              .word $0000, $0000   ; X = 0.0 (centered horizontally)
MY_TRANS_Y              .word $0000, $0000   ; Y = 0.0 (centered vertically)
MY_TRANS_Z              .word $0000, $0007   ;

; ============================================
; INITIAL TRS (Transform-Rotate-Scale) VALUES
; ============================================
; Rotation angles (0 to 255 for a full circle)
MY_ROT_X                .byte 0
MY_ROT_Y                .byte 0
MY_ROT_Z                .byte 0


ROT_DELTA               = 5
SCALE_INCREMENT:
        .word $199A, $0000     ; 0.1

SCALE_DECREMENT:
        .word $E666, $FFFF     ; -0.1
        
TRANS_INCREMENT:
        .word $199A, $0000     ; 0.1
TRANS_DECREMENT
        .word $E666, $FFFF     ; -0.1
