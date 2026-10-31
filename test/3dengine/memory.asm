; ====================================================
; memory.asm - Centralized Zero-Page Pointers & Workspace
; ====================================================

PLOT    = $E50A
CHROUT  = $FFD2

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
        


SCALING_MATRIX      .ds 64 
TRANSLATION_MATRIX  .ds 64
ROT_X_MATRIX        .ds 64
ROT_Y_MATRIX        .ds 64
ROT_Z_MATRIX        .ds 64
ROTATION_MATRIX     .ds 64

WORLD_MATRIX        .ds 64
MAT_TEMP            .ds 64

SCREEN_CENTER_X    = 160
SCREEN_CENTER_Y    = 100

PROJ_X             .ds 1
PROJ_Y             .ds 1
RECIP_VAL          .ds 1

SCREEN_X_LIST      .ds 5   ; 5 bytes for 5 pyramid vertices
SCREEN_Y_LIST      .ds 5
RECIP_TABLE        .ds 256 ; 256-byte reciprocal lookup table ($1/Z$)

ROT_TEMP_MATRIX:
        .ds 64
        
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
        
SCALE_X:
        .ds 4
SCALE_Y:
        .ds 4
SCALE_Z:
        .ds 4
TRANS_X:
        .ds 4
TRANS_Y:
        .ds 4
TRANS_Z:
        .ds 4
        
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

CURRENT_VERTEX_PTR .ds 2

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
            VEC_ROW         .ds 1
            VEC_K           .ds 1
            VEC_MPTR        .ds 2
            VEC_VPTR        .ds 2
            MAT4_VIN_PTR    .ds 2
            MAT4_VOUT_PTR   .ds 2
            MAT4_MATRIX_PTR  .ds 2
    
            X0              .ds 2
            X1              .ds 2
            Y0              .ds 1
            Y1              .ds 1
            
; ============================================
; RENDER_OBJECT Variables & Buffers
; ============================================

; --- Loop Control & Pointers (Zero Page / Fast Access) ---
VERTEX_INDEX          .ds 1   ; Loop counter tracking current vertex index (0 to N-1)

; ============================================
; SCREEN COORDINATE STORAGE BUFFERS (5 Vertices)
; ============================================

SCREEN_X_L         .ds 5   ; Low bytes of projected X coordinates (0 to 255)
SCREEN_X_H         .ds 5   ; High bytes of projected X coordinates (0 or 1 for 320px width)


            * = PC_SAVE
            ; Display configuration
DISPLAY_ROWS:       .byte 4
DISPLAY_COLS:       .byte 1
DISPLAY_VECTORS:    .byte 1

;********************************************
;* INTERMEDIATE MATRICES
;********************************************

ROT_SCALE_MATRIX:
        .ds 64

MODEL_MATRIX:
        .ds 64
        
; --- Data Buffers & Lookups (Standard RAM) ---
TRANSFORMED_VERTEX    .ds 16  ; Temporary working buffer holding [x, y, z, w] in 16.16 fixed-point (4 bytes each)

; ============================================
; PYRAMID 3D MODEL DATA (5 Vertices, 8 Edges)
; ============================================

NUM_VERTICES = 5
NUM_EDGES = 8
EDGE_INDEX .ds 1

; Each vertex consists of X, Y, Z, W (4 bytes each = 16 bytes per vertex)
; 16.16 Fixed Point: .word fractional_part, integer_part

VERTEX_0: ; Apex (X=0, Y=1, Z=0)
        .word $0000, $0000     ; X = 0.0
        .word $0000, $0001     ; Y = 1.0
        .word $0000, $0000     ; Z = 0.0
        .word $0000, $0001     ; W = 1.0

VERTEX_1: ; Base Front-Left (X=-1, Y=-1, Z=-1)
        .word $0000, $FFFF     ; X = -1.0 (Two's complement)
        .word $0000, $FFFF     ; Y = -1.0
        .word $0000, $FFFF     ; Z = -1.0
        .word $0000, $0001     ; W = 1.0

VERTEX_2: ; Base Front-Right (X=1, Y=-1, Z=-1)
        .word $0000, $0001     ; X = 1.0
        .word $0000, $FFFF     ; Y = -1.0
        .word $0000, $FFFF     ; Z = -1.0
        .word $0000, $0001     ; W = 1.0

VERTEX_3: ; Base Back-Right (X=1, Y=-1, Z=1)
        .word $0000, $0001     ; X = 1.0
        .word $0000, $FFFF     ; Y = -1.0
        .word $0000, $0001     ; Z = 1.0
        .word $0000, $0001     ; W = 1.0

VERTEX_4: ; Base Back-Left (X=-1, Y=-1, Z=1)
        .word $0000, $FFFF     ; X = -1.0
        .word $0000, $FFFF     ; Y = -1.0
        .word $0000, $0001     ; Z = 1.0
        .word $0000, $0001     ; W = 1.0


; ============================================
; VERTEX POINTER TABLES (For fast index lookup)
; ============================================

VERTEX_PTR_L:
        .byte <VERTEX_0
        .byte <VERTEX_1
        .byte <VERTEX_2
        .byte <VERTEX_3
        .byte <VERTEX_4

VERTEX_PTR_H:
        .byte >VERTEX_0
        .byte >VERTEX_1
        .byte >VERTEX_2
        .byte >VERTEX_3
        .byte >VERTEX_4

; ============================================
; EDGE LIST (Connecting vertex pairs for lines)
; ============================================

EDGE_START_LIST:
        .byte 0, 0, 0, 0       ; Apex connections to 4 base corners
        .byte 1, 2, 3, 4       ; Base perimeter connections

EDGE_END_LIST:
        .byte 1, 2, 3, 4       ; Apex connections target vertices
        .byte 2, 3, 4, 1       ; Base perimeter target vertices