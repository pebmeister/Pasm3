; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================

        .basic_hdr

        lda #COLOR_WHITE
        jsr _HGRFColor
        lda #COLOR_BLACK
        jsr _HGRBColor

        jsr HGRCls
        jsr HGROn
                
        lda #0
        sta ScrRow
        jsr CLEARSCREEN

        jsr Build_model

MainLoop:
        jsr Build_model
        jsr CreateProjection

        jsr HGRCls
        jsr DRAW_CUBE_EDGES

        jmp MainLoop
        
Build_model
        SET_SCALE        MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z
        SET_ROTATION     MY_ROT_X, MY_ROT_Y, MY_ROT_Z
        SET_TRANSLATION  MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z

        CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
        CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX
        
        rts
        
CreateProjection
         
        ; Transform model vertices
        jsr TRANSFORM_MODEL_VERTICES

        ; Perspective projection
        jsr PROJECT_WORLD_VERTICES

        ; Perspective divide
        jsr DIVIDE_CLIP_VERTICES

        jsr CONVERT_NDC_TO_SCREEN
        
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
