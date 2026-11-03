; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================

        .basic_hdr

        lda #0
        sta BORDER

        jsr TestProjection
        
        lda #COLOR_WHITE
        jsr _HGRFColor
        lda #COLOR_BLACK
        jsr _HGRBColor
        
        jsr HGRCls
        jsr HGROn

        jsr DRAW_CUBE_EDGES
        
@MainWait:
        ;lda #COLOR_GREEN
        ;jsr _HGRfColor
        ;jsr TEST_MANUAL_LINE
        ;jmp @MainWait

TestProjection
        ; Build model matrix
        SET_SCALE        MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z
        SET_ROTATION     MY_ROT_X, MY_ROT_Y, MY_ROT_Z
        SET_TRANSLATION  MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z

        CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
        CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX

        ; Transform model vertices
        jsr TRANSFORM_MODEL_VERTICES

        ; Perspective projection
        jsr PROJECT_WORLD_VERTICES

        ; Perspective divide
        jsr DIVIDE_CLIP_VERTICES

        jsr CONVERT_NDC_TO_SCREEN
        
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
MY_TRANS_Z      .word $0000, $0004   ; 4.0

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

;********************************************
;* DRAW_CUBE_EDGES                         *
;*                                          *
;* Draws all edges in CUBE_EDGES            *
;* using SCREEN_VERTICES and _Line.         *
;********************************************

DRAW_CUBE_EDGES:

        lda #0
        sta DRAW_EDGE_INDEX

        lda CUBE_EDGE_COUNT
        sta DRAW_EDGE_LEFT

@DrawEdge:

        ;------------------------------------
        ; Get first vertex index
        ;------------------------------------

        ldy DRAW_EDGE_INDEX
        lda CUBE_EDGES,y
        sta DRAW_VERTEX_INDEX

        ; Calculate offset = vertex index * 3
        asl
        clc
        adc DRAW_VERTEX_INDEX
        tay

        ; Load X0, Y0
        lda SCREEN_VERTICES,y
        sta X0
        iny
        lda SCREEN_VERTICES,y
        sta X0+1
        iny
        lda SCREEN_VERTICES,y
        sta Y0

        ;------------------------------------
        ; Get second vertex index
        ;------------------------------------

        ldy DRAW_EDGE_INDEX
        iny
        lda CUBE_EDGES,y
        sta DRAW_VERTEX_INDEX

        ; Calculate offset = vertex index * 3
        asl
        clc
        adc DRAW_VERTEX_INDEX
        tay

        ; Load X1, Y1
        lda SCREEN_VERTICES,y
        sta X1
        iny
        lda SCREEN_VERTICES,y
        sta X1+1
        iny
        lda SCREEN_VERTICES,y
        sta Y1

        ;------------------------------------
        ; Draw edge
        ;------------------------------------

        jsr _Line

        ;------------------------------------
        ; Next edge
        ;------------------------------------

        inc DRAW_EDGE_INDEX
        inc DRAW_EDGE_INDEX

        dec DRAW_EDGE_LEFT
        bne @DrawEdge

        rts
        
;Vertex	X	Y
;0	127	132
;1	151	109
;2	144	54
;3	128	89
;4	170	131
;5	205	115
;6	188	71
;7	163	96


