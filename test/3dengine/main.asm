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
                
        jsr Update_Scale

        MOVE8 MY_ROT_X, ROT_X_ANGLE
        MOVE8 MY_ROT_Y, ROT_Y_ANGLE
        MOVE8 MY_ROT_Z, ROT_Z_ANGLE

        jsr ROTATION_X
        MAT4_COPY MAT_B, ROT_X_MATRIX
        jsr ROTATION_Y
        MAT4_COPY MAT_B, ROT_Y_MATRIX
        jsr ROTATION_Z
        MAT4_COPY MAT_B, ROT_Z_MATRIX

        jsr BUILD_ROT_ZY_MATRIX
        jsr BUILD_ROTATION_MATRIX_X

        jsr Update_Translation
        jmp Draw
        
MainLoop:
        jsr GETIN
        beq MainLoop
        
        cmp #$11    ; down        
        beq @Down

        cmp #$91    ; up
        beq @Up
        
        cmp #$9D    ; Left
        beq @Left

        cmp #$1D    ; Right
        beq @Right

        jmp MainLoop
        
@Up
        ADD8I MY_ROT_X, 10, MY_ROT_X
        jsr Update_X_Rotation
        jmp Draw

@Down
        SUB8I MY_ROT_X, 10, MY_ROT_X
        jsr Update_X_Rotation
        jmp Draw
        
@Left
        ADD8I MY_ROT_Y, 10, MY_ROT_Y
        jsr Update_Y_Rotation
        jmp Draw
        
@Right
        SUB8I MY_ROT_Y, 10, MY_ROT_Y
        jsr Update_Y_Rotation
        jmp Draw
        
Draw
        CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
        CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX        

        jsr CreateProjection
        jsr HGRCls
        jsr DRAW_PYRAMID_EDGES
        jmp MainLoop

Update_Scale
        SET_SCALE MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z
        rts
        
Update_X_Rotation
        MOVE8 MY_ROT_X, ROT_X_ANGLE
        jsr ROTATION_X        
        MAT4_COPY MAT_B, ROT_X_MATRIX
        jsr BUILD_ROTATION_MATRIX_X
        rts

Update_Y_Rotation
        MOVE8 MY_ROT_Y, ROT_Y_ANGLE
        jsr ROTATION_Y
        MAT4_COPY MAT_B, ROT_Y_MATRIX
        jsr BUILD_ROT_ZY_MATRIX
        jsr BUILD_ROTATION_MATRIX_X
        rts

Update_Z_Rotation
        MOVE8 MY_ROT_Z, ROT_Z_ANGLE
        jsr ROTATION_Z
        MAT4_COPY MAT_B, ROT_Z_MATRIX
        jsr BUILD_ROT_ZY_MATRIX
        jsr BUILD_ROTATION_MATRIX_X
        rts
        
Update_Translation
        SET_TRANSLATION  MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z
        rts
                
CreateProjection
         
        ; Transform model vertices
        jsr TRANSFORM_MODEL_VERTICES

        ; Perspective projection
        jsr PROJECT_WORLD_VERTICES

        ; Perspective divide
        ; jsr DIVIDE_CLIP_VERTICES
        jsr DIVIDE_CLIP_VERTICES_XY

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
        