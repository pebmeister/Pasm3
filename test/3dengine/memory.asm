; ====================================================
; memory.asm - Centralized Zero-Page Pointers & Workspace
; ====================================================

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

MAT_MUL_B:
    .word $0000, $0000

MAT_PRODUCT:
    .word $0000, $0000

MAT_ACCUM:
    .word $0000, $0000    
    
    
;********************************************
;* MATRIX MULTIPLICATION WORKSPACE
;* Place pointers in zero page.
;********************************************
PC_SAVE        = *

               * = $50
FIXPTR         .ds 2
TEMP16         .ds 2

MAT_APTR       .ds 2       ; Current A element pointer
MAT_BPTR       .ds 2       ; Current B element pointer
MAT_CPTR       .ds 2       ; Current C element pointer
MAT_AROW       .ds 2       ; Start of current A row
MAT_BCOL       .ds 2       ; Start of current B column

MAT_ROW        .ds 1       ; Row counter
MAT_COL        .ds 1       ; Column counter
MAT_K          .ds 1       ; Inner-loop counter

; Matrix multiplication arguments
MAT4_A_PTR: .ds 2
MAT4_B_PTR: .ds 2
MAT4_C_PTR: .ds 2

FIX16_A_PTR      .ds 2
FIX16_B_PTR      .ds 2
FIX16_RESULT_PTR .ds 2


            * = PC_SAVE

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
NUM_VECS
                .ds 1
VEC_ROWS    
                .ds 10
VEC_COLS
                .ds 10

; Engine Buffers & Constants
FIX_STRING_BUF  .ds 20     
CLS             .byte 147,0


;********************************************
;* Rotation test variables
;********************************************
ROT_X_ANGLE:
        .byte 32             ; 45
ROT_Y_ANGLE:
        .byte 32             ; 45
ROT_Z_ANGLE:
        .byte 32             ; 45

ROT_SINE:
        .word $0000, $0000

ROT_COSINE:
        .word $0000, $0000

ROT_NEG_SINE:
        .word $0000, $0000
        
        
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
MAT_ROT_X:
        .ds 64

MAT_ROT_XY:
        .ds 64

