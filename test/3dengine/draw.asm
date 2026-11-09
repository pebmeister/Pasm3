Draw
        CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
        CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX        

        jsr CreateProjection
        jsr HGRCls
        jsr DRAW_PYRAMID_EDGES
        rts

        
Update_X_Rotation
        jsr ROTATION_X        
        jsr BUILD_ROTATION_MATRIX_X
        rts

Update_Y_Rotation
        jsr ROTATION_Y
        jsr BUILD_ROT_ZY_MATRIX
        jsr BUILD_ROTATION_MATRIX_X
        rts

Update_Z_Rotation
        jsr ROTATION_Z
        jsr BUILD_ROT_ZY_MATRIX
        jsr BUILD_ROTATION_MATRIX_X
        rts
        
Update_X_Translation
        jsr BUILD_TRANSLATION_MATRIX_X
        rts

Update_Y_Translation
        jsr BUILD_TRANSLATION_MATRIX_Y
        rts

Update_Z_Translation
        jsr BUILD_TRANSLATION_MATRIX_Z
        rts
                
CreateProjection         
        ; Transform model vertices
        ; jsr TRANSFORM_WORLD_VERTICES
        jsr TRANSFORM_PYRAMID_VERTICES

        ; Perspective projection
        jsr PROJECT_WORLD_VERTICES

        ; Perspective divide
        ; jsr DIVIDE_CLIP_VERTICES
        jsr DIVIDE_CLIP_VERTICES_XY

        ; set to screen
        jsr CONVERT_NDC_TO_SCREEN
        
        rts
 
;********************************************
;* DRAW_PYRAMID_EDGES                       *
;*                                          *
;* Draws all edges in PYRAMID_EDGES         *
;* using SCREEN_VERTICES and _Line.         *
;********************************************

DRAW_PYRAMID_EDGES:

        lda #0
        sta DRAW_EDGE_INDEX

        lda PYRAMID_EDGE_COUNT
        sta DRAW_EDGE_LEFT

@DrawEdge:

        ;------------------------------------
        ; Get first vertex index
        ;------------------------------------

        ldy DRAW_EDGE_INDEX
        lda PYRAMID_EDGES,y
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
        lda PYRAMID_EDGES,y
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
        