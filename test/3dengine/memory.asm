; ====================================================
; memory.asm - Centralized Zero-Page Pointers & Workspace
; ====================================================

; Safe Zero-Page Pointers (Free from ROM/BASIC collision)

; Formatter Workspace Variables
FMT_VAL         .ds 4
FMT_INTOFF      .ds 1
FMT_FRACOFF     .ds 1
FMT_DIG5IDX     .ds 1
FMT_NULLIDX     .ds 1
FMT_SIGNFLG     .ds 1

; Engine Buffers & Constants
FIX_STRING_BUF  .ds 20     
CLS             .byte 147,0

; ====================================================
; Test Data & Constants
; ====================================================
TestMatrixA:
        .word $0000, $0002,  $0000, $0000,  $0000, $0000
        .word $0000, $0000,  $0000, $0002,  $0000, $0000
        .word $0000, $0000,  $0000, $0000,  $0000, $0002

TestVectorB:
        .word $8000, $0001   ; 1.5
        .word $0000, $0002   ; 2.0
        .word $0000, $FFFE   ; -1.0

ResultVectorC:
        .ds 12              ; Space for 3 output 16.16 values


; Add these to memory.asm:
FIX_ZERO        .word $0000, $0000  ; 0.00000 in 16.16
FIX_ONE         .word $0000, $0001  ; 1.00000 in 16.16
FIX_NEG_ONE     .word $0000, $FFFF  ; -1.00000 in 16.16 (or calculated)

; 3x3 Rotation Matrix Buffer (9 entries * 4 bytes = 36 bytes)
RotMatrix       .ds 36
RotAngle        .ds 1

RotMatrixX      .ds 36
RotMatrixY      .ds 36
RotMatrixZ      .ds 36
TempMatrix      .ds 36

AngleX          .ds 1
AngleY          .ds 1
AngleZ          .ds 1

TempCol         .ds 12          ; 3-element vector buffer for column extraction
TempResult      .ds 12          ; 3-element vector buffer for multiplication result
ColOffset       .ds 1           ; Column loop index
SavedMatB       .ds 2           ; Pointer backup
SavedMatC       .ds 2           ; Pointer backup


; params for DisplayResults
; set FIXPTR to point at first vector
NUM_VECS
            .ds 1
VEC_ROWS    
            .ds 10
VEC_COLS
            .ds 10
 
 Vx         .ds 2
 Vy         .ds 2
 Vz         .ds 2
 RotX       .ds 4
 RotY       .ds 4
 RotZ       .ds 4
 
; ====================================================
; 3D Vertex List (6 bytes per vertex: 2 bytes X, Y, Z in 8.8 Fixed-Point)
; $0100 = 1.0,  -$0100 = -1.0 ($FF00)
; ====================================================
CubeVertices:
        ;        X       Y       Z
        .word -$0100, -$0100, -$0100  ; Vertex 0: [-1, -1, -1]
        .word  $0100, -$0100, -$0100  ; Vertex 1: [ 1, -1, -1]
        .word  $0100,  $0100, -$0100  ; Vertex 2: [ 1,  1, -1]
        .word -$0100,  $0100, -$0100  ; Vertex 3: [-1,  1, -1]
        .word -$0100, -$0100,  $0100  ; Vertex 4: [-1, -1,  1]
        .word  $0100, -$0100,  $0100  ; Vertex 5: [ 1, -1,  1]
        .word  $0100,  $0100,  $0100  ; Vertex 6: [ 1,  1,  1]
        .word -$0100,  $0100,  $0100  ; Vertex 7: [-1,  1,  1]
NumVertices = 8

; ====================================================
; Wireframe Edge Index Table
; ====================================================
CubeEdges:
        .byte 0,1,  1,2,  2,3,  3,0  ; Front face
        .byte 4,5,  5,6,  6,7,  7,4  ; Back face
        .byte 0,4,  1,5,  2,6,  3,7  ; Connecting struts
        .byte $FF                        ; End marker

; ====================================================
; Screen Output Buffer (8 vertices * 4 bytes = 32 bytes)
; ====================================================
Screen_Output_Buffer:
                .ds 32          ; [X_lo, X_hi, Y_lo, Y_hi] per vertex
        
TempScreenX     .ds 2
TempScreenY     .ds 2
SavedEdgeY      .ds 2

COLOR           .ds 1


TMP             .ds 1
DY              .ds 2
DX              .ds 2
XS              .ds 2
YS              .ds 2
XCOORD          .ds 2
YCOL            .ds 2
XDIST           .ds 2
K1              .ds 2
K2              .ds 2
_D              .ds 2
_Y              .ds 2
_X              .ds 2
StartX          .ds 2
XD              .ds 2
COUNTER         .ds 2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PAGE ZERO SECTION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SAVE_PC         = *
                * = $50

LOC             .ds 2
COLORPTR        .ds 2
CURLOC          .ds 2

FIXPTR          .ds 2        ; 2 bytes ($FB-$FC)
TEMP_PTR        .ds 2        ; 2 bytes ($FD-$FE)
PTR_A           .ds 2
PTR_B           .ds 2
PTR_C           .ds 2
PTR_MAT_A       .ds 2
PTR_MAT_B       .ds 2
PTR_MAT_C       .ds 2

ROW_INDEX       .ds 1
COL_INDEX       .ds 1

; Shared 16.16 Math & Engine Variables
VAR_A           .ds 4
VAR_B           .ds 4
VAR_C           .ds 4

TEMP16          .ds 2
SCRATCH_FRAC    .ds 2

TEMP_PROD32     .ds 4

MAT_K           .ds 1
MAT_M           .ds 1
MAT_N           .ds 1
ROW             .ds 1
DOT_LEN         .ds 1
DOT_RESULT      .ds 4

X0              .ds 2
Y0              .ds 2
X1              .ds 2
Y1              .ds 2


TempIndex       .ds 1
ProjScreenX     .ds 2
ProjScreenY     .ds 2

                * = SAVE_PC
            