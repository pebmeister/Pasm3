Draw
        CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
        CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX        

        jsr CreateProjection
        jsr HGRCls
        jmp DRAW_MESH_EDGES
        
Update_X_Rotation
        jsr ROTATION_X        
        jmp BUILD_ROTATION_MATRIX_X

Update_Y_Rotation
        jsr ROTATION_Y
        jsr BUILD_ROT_ZY_MATRIX
        jmp BUILD_ROTATION_MATRIX_X

Update_Z_Rotation
        jsr ROTATION_Z
        jsr BUILD_ROT_ZY_MATRIX
        jmp BUILD_ROTATION_MATRIX_X
        rts
        
Update_X_Translation
        jmp BUILD_TRANSLATION_MATRIX_X

Update_Y_Translation
        jmp BUILD_TRANSLATION_MATRIX_Y

Update_Z_Translation
        jmp BUILD_TRANSLATION_MATRIX_Z
                

CreateProjection
        ; Transform model vertices
        jsr TRANSFORM_WORLD_VERTICES
        
        ; Perspective projection
        jsr PROJECT_WORLD_VERTICES

        ; Perspective divide
        ; jsr DIVIDE_CLIP_VERTICES
        jsr DIVIDE_CLIP_VERTICES_XY

        ; set to screen
        jmp CONVERT_NDC_TO_SCREEN
        
 
; ============================================
; DRAW_MESH_EDGES
; Draws all edges using generic variables:
; - MODEL_EDGES_PTR: points to edge index table
; - MODEL_VERTICES_PTR (or SCREEN_VERTICES): points to screen vertices
; - MODEL_NUM_EDGES: total number of edges to draw
; ============================================
DRAW_MESH_EDGES:
        lda MODEL_NUM_EDGES
        sta DRAW_EDGE_LEFT
        lda #0
        sta DRAW_EDGE_INDEX

@DrawEdge:
        ; ------------------------------------
        ; Get first vertex index from MODEL_EDGES_PTR
        ; ------------------------------------
        ldy DRAW_EDGE_INDEX
        lda (MODEL_EDGES_PTR),y
        sta DRAW_VERTEX_INDEX

        ; Calculate offset = vertex index * 3 (3 bytes per vertex: X_lo, X_hi, Y)
        asl
        clc
        adc DRAW_VERTEX_INDEX
        tay

        ; Load X0, Y0 from SCREEN_VERTICES using Y offset
        lda (VERTICES_PTR),y
        sta X0
        iny
        lda (VERTICES_PTR),y
        sta X0+1
        iny
        lda (VERTICES_PTR),y
        sta Y0

        ; ------------------------------------
        ; Get second vertex index from MODEL_EDGES_PTR
        ; ------------------------------------
        ldy DRAW_EDGE_INDEX
        iny
        lda (MODEL_EDGES_PTR),y
        sta DRAW_VERTEX_INDEX

        ; Calculate offset = vertex index * 3
        asl
        clc
        adc DRAW_VERTEX_INDEX
        tay

        ; Load X1, Y1 from SCREEN_VERTICES using Y offset
        lda (VERTICES_PTR),y
        sta X1
        iny
        lda (VERTICES_PTR),y
        sta X1+1
        iny
        lda (VERTICES_PTR),y
        sta Y1

        ; ------------------------------------
        ; Draw edge via line routine
        ; ------------------------------------
        jsr _Line

        ; ------------------------------------
        ; Next edge
        ; ------------------------------------
        inc DRAW_EDGE_INDEX
        inc DRAW_EDGE_INDEX

        dec DRAW_EDGE_LEFT
        bne @DrawEdge

        rts