; written by Paul Baxter using Pasm3
Draw:
            CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
            CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX

            jsr     CreateProjection
            jsr     HGRCls

            lda     CUR_MODEL
            cmp     #2
            bne     @Draw_Mesh
            
            jsr     TestFaces            
            jsr     DRAW_MESH_CULL_EDGES
            rts
@Draw_Mesh            
            jsr     DRAW_MESH_EDGES
            rts

Update_X_Rotation:
            jsr     ROTATION_X
            jmp     BUILD_ROTATION_MATRIX_X

Update_Y_Rotation:
            jsr     ROTATION_Y
            jsr     BUILD_ROT_ZY_MATRIX
            jmp     BUILD_ROTATION_MATRIX_X

Update_Z_Rotation:
            jsr     ROTATION_Z
            jsr     BUILD_ROT_ZY_MATRIX
            jmp     BUILD_ROTATION_MATRIX_X
            rts

Update_X_Translation:
            jmp     BUILD_TRANSLATION_MATRIX_X

Update_Y_Translation:
            jmp     BUILD_TRANSLATION_MATRIX_Y

Update_Z_Translation:
            jmp     BUILD_TRANSLATION_MATRIX_Z

CreateProjection:
            ; Transform model vertices
            lda     CUR_MODEL
            cmp     #1
            beq     @Pyramid
            cmp     #2
            beq     @Cube

            jsr     TRANSFORM_WORLD_VERTICES
            jmp     @Done_Transform
@Cube:
            jsr     TRANSFORM_CUBE_VERTICES
            jmp     @Done_Transform
@Pyramid:
            jsr     TRANSFORM_PYRAMID_VERTICES
            ; jmp @Done_Transform

@Done_Transform:
            
            ; Perspective projection
            jsr     PROJECT_WORLD_VERTICES

            ; Perspective divide
            jsr     DIVIDE_CLIP_VERTICES
            ; jsr DIVIDE_CLIP_VERTICES_XY

            ; set to screen
            jsr     CONVERT_NDC_TO_SCREEN
            
            
            
            rts

; ============================================
; DRAW_MESH_CULL_EDGES
; Draws edges belonging to at least one
; visible face.
; ============================================
DRAW_MESH_CULL_EDGES:
            lda     MODEL_NUM_EDGES
            sta     DRAW_EDGE_LEFT
            lda     #0
            sta     DRAW_EDGE_INDEX

@DrawEdge:
            ; --------------------------------
            ; Check adjacent face visibility
            ; --------------------------------
            ldy     DRAW_EDGE_INDEX

            lda     (MODEL_EDGE_FACES_PTR),y
            tax
            lda     CUBE_VISIBLE,x
            bne     @VisibleEdge

            iny
            lda     (MODEL_EDGE_FACES_PTR),y
            tax
            lda     CUBE_VISIBLE,x
            beq     @NextEdge

@VisibleEdge:
            ; --------------------------------
            ; Get first vertex index
            ; --------------------------------
            ldy     DRAW_EDGE_INDEX
            lda     (MODEL_EDGES_PTR),y
            sta     DRAW_VERTEX_INDEX

            asl
            clc
            adc     DRAW_VERTEX_INDEX
            tay

            lda     SCREEN_VERTICES,y
            sta     X0
            iny
            lda     SCREEN_VERTICES,y
            sta     X0+1
            iny
            lda     SCREEN_VERTICES,y
            sta     Y0

            ; --------------------------------
            ; Get second vertex index
            ; --------------------------------
            ldy     DRAW_EDGE_INDEX
            iny
            lda     (MODEL_EDGES_PTR),y
            sta     DRAW_VERTEX_INDEX

            asl
            clc
            adc     DRAW_VERTEX_INDEX
            tay

            lda     SCREEN_VERTICES,y
            sta     X1
            iny
            lda     SCREEN_VERTICES,y
            sta     X1+1
            iny
            lda     SCREEN_VERTICES,y
            sta     Y1

            jsr     CLAMP_LINE_COORDS
            jsr     _Line

@NextEdge:
            inc     DRAW_EDGE_INDEX
            inc     DRAW_EDGE_INDEX

            dec     DRAW_EDGE_LEFT
            bne     @DrawEdge

            rts
            
; ============================================
; DRAW_MESH_EDGES
; Draws all edges using generic variables:
; - MODEL_EDGES_PTR: points to edge index table
; - MODEL_NUM_EDGES: total number of edges to draw
; ============================================
DRAW_MESH_EDGES:
            lda     MODEL_NUM_EDGES
            sta     DRAW_EDGE_LEFT
            lda     #0
            sta     DRAW_EDGE_INDEX

@DrawEdge:
            ; ------------------------------------
            ; Get first vertex index from MODEL_EDGES_PTR
            ; ------------------------------------
            ldy     DRAW_EDGE_INDEX
            lda     (MODEL_EDGES_PTR),y
            sta     DRAW_VERTEX_INDEX

            ; Calculate offset = vertex index * 3 (3 bytes per vertex: X_lo, X_hi, Y)
            asl
            clc
            adc     DRAW_VERTEX_INDEX
            tay

            ; Load X0, Y0 from SCREEN_VERTICES using Y offset
            lda     SCREEN_VERTICES,y
            sta     X0
            iny
            lda     SCREEN_VERTICES,y
            sta     X0+1
            iny
            lda     SCREEN_VERTICES,y
            sta     Y0

            ; ------------------------------------
            ; Get second vertex index from MODEL_EDGES_PTR
            ; ------------------------------------
            ldy     DRAW_EDGE_INDEX
            iny
            lda     (MODEL_EDGES_PTR),y
            sta     DRAW_VERTEX_INDEX

            ; Calculate offset = vertex index * 3
            asl
            clc
            adc     DRAW_VERTEX_INDEX
            tay

            ; Load X1, Y1 from SCREEN_VERTICES using Y offset
            lda     SCREEN_VERTICES,y
            sta     X1
            iny
            lda     SCREEN_VERTICES,y
            sta     X1+1
            iny
            lda     SCREEN_VERTICES,y
            sta     Y1

            jsr     CLAMP_LINE_COORDS

            ; ------------------------------------
            ; Draw edge via line routine
            ; ------------------------------------
            jsr     _Line

            ; ------------------------------------
            ; Next edge
            ; ------------------------------------
            inc     DRAW_EDGE_INDEX
            inc     DRAW_EDGE_INDEX

            dec     DRAW_EDGE_LEFT
            bne     @DrawEdge

            rts

TestFaces:        
        lda #0
        sta FACE_INDEX

@FaceLoop        
        jsr TEST_FACE

        inc FACE_INDEX
        lda FACE_INDEX
        cmp #6
        bne @FaceLoop
@exit
        ; stop here for testing
        rts
        

; ============================================
; CLAMP_LINE_COORDS
; Clamps X0, X1 to screen range 0-319 ($013F)
; Clamps Y0, Y1 to screen range 0-199 ($C7)
; ============================================
CLAMP_LINE_COORDS:
            ; --- Clamp X0 ---
            lda     X0 + 1
            bmi     @clamp_x0_zero
            beq     @clamp_y0
            cmp     #1
            bne     @clamp_x0_max
            lda     X0
            cmp     #$40
            bcc     @clamp_y0
@clamp_x0_max:
            lda     #<319
            sta     X0
            lda     #>319
            sta     X0 + 1
            jmp     @clamp_y0
@clamp_x0_zero:
            lda     #0
            sta     X0
            sta     X0 + 1

@clamp_y0:
            ; --- Clamp Y0 (unsigned 0-199) ---
            lda     Y0
            cmp     #200
            bcc     @clamp_x1
            lda     #199
            sta     Y0

@clamp_x1:
            ; --- Clamp X1 ---
            lda     X1 + 1
            bmi     @clamp_x1_zero
            beq     @clamp_y1
            cmp     #1
            bne     @clamp_x1_max
            lda     X1
            cmp     #$40
            bcc     @clamp_y1
@clamp_x1_max:
            lda     #<319
            sta     X1
            lda     #>319
            sta     X1 + 1
            jmp     @clamp_y1
@clamp_x1_zero:
            lda     #0
            sta     X1
            sta     X1 + 1

@clamp_y1:
            ; --- Clamp Y1 ---
            lda     Y1
            cmp     #200
            bcc     @clamp_done
            lda     #199
            sta     Y1
            jmp     @clamp_done
@clamp_y1_zero:
            lda     #0
            sta     Y1

@clamp_done:
            rts
