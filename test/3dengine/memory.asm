; ====================================================
; memory.asm - Centralized Zero-Page Pointers & Workspace
; ====================================================

PLOT    = $E50A
CHROUT  = $FFD2

;********************************************
;* MAT_Z - Zero matrix
;********************************************
MAT_Z:
        ; Row 0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0

        ; Row 1
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0

        ; Row 2
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0

        ; Row 3
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0
        .word $0000, $0000    ; 0.0

;********************************************
;* MAT_I - Identity matrix
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

;********************************************
;* MAT_A - Identity matrix
;********************************************
MAT_A:
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
        
;********************************************
;* MAT_B - 4x4
;********************************************
MAT_B:
        ; Row 0
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000

        ; Row 1
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000

        ; Row 2
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0001
        .word $0000, $0000

        ; Row 3
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0001
        
        
;********************************************
;* MAT_C - 4x4 Matrix
;********************************************
MAT_C:
        ; 16 zero-valued 16.16 elements
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000

        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000

        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000

        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000
        .word $0000, $0000
        
; Four-byte fixed-point values.
MAT_MUL_A:
        .word $0000, $0000
        .ds 8
        
MAT_MUL_B:
        .word $0000, $0000
        .ds 8
MAT_PRODUCT:
        .ds 8

MAT_ACCUM:
        .word $0000, $0000    
        .ds 8
    
; Formatter Workspace Variables
FMT_VAL         .ds 4
FMT_INTOFF      .ds 1
FMT_FRACOFF     .ds 1
FMT_DIG5IDX     .ds 1
FMT_NULLIDX     .ds 1
FMT_SIGNFLG     .ds 1
SCRATCH_FRAC    .ds 2
TEMP_PROD32     .ds 4

ROW             .ds 1

; params for DisplayResults
; set FIXPTR to point at first vector
NUM_VECS        .ds 1
VEC_ROWS        .ds 10
VEC_COLS        .ds 10

; Engine Buffers & Constants
FIX_STRING_BUF  .ds 50     

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

;********************************************
;* MATRIX MULTIPLICATION WORKSPACE
;* Place pointers in zero page.
;********************************************
PC_SAVE        = *
*= $60
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

; --- Other Pointers (Safely isolated above workspace) ---
MAT4_MATRIX_PTR  .ds 2
MAT4_VIN_PTR     .ds 2
MAT4_VOUT_PTR     .ds 2

; ============================================
; Dedicated Matrix Zero-Page Workspace
; Shared with ABSOLUTELY NOTHING else.
; ============================================
            * = $40
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

            * = PC_SAVE
            