; written by Paul Baxter with ChatGPT AI using Pasm3

            RENDER_WIREFRAME = 0
            RENDER_CULLED = 1
            RENDER_FILLED = 2

            
RENDER_MODE:
            .byte   RENDER_WIREFRAME

Draw:
            jsr     BuildModel
            jsr     DRAW_MESH
@Exit
            rts

DRAW_MESH:
            lda     RENDER_MODE
            beq     @Wireframe

            cmp     #RENDER_CULLED
            beq     @Culled

            ; ---------------- Filled rendering ----------------
            jsr     TestFaces
            jsr     HGRCls
            jsr     DRAW_MESH_FACES
            jsr     DRAW_MESH_CULL_EDGES
            rts

@Culled:
            ; ---------------- Culled rendering ----------------                       

            jsr     TestFaces
            jsr     HGRCls
            jsr     DRAW_MESH_CULL_EDGES
            rts

@Wireframe:
            ; -------------- WireFrame  rendering --------------
            jsr     HGRCls
            jsr     DRAW_MESH_EDGES
            rts

; ============================================
; CreateProjection
; ============================================
CreateProjection:
            ; Transform model vertices
            lda     CUR_MODEL
            cmp     #MODEL_PYRAMID
            beq     @Pyramid
            cmp     #MODEL_CUBE
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
            lda     #0
            sta     FACE_INDEX

@FaceLoop:
            jsr     TEST_FACE

            inc     FACE_INDEX
            lda     FACE_INDEX
            cmp     #6
            bne     @FaceLoop
@exit:
            rts

; ============================================
; DRAW_MESH_FACES
;
; Process visible faces.
; Draw first scanline only (initial test).
;
; ============================================

DRAW_MESH_FACES:
            lda     #0
            sta     DRAW_FACE_INDEX

@FaceLoop:
            ; --------------------------------
            ; Skip hidden face
            ; --------------------------------
            ldx     DRAW_FACE_INDEX
            lda     CUBE_VISIBLE,x
            bne     @Continue
            jmp     @NextFace

@Continue:
            ; --------------------------------
            ; Set current face index
            ; --------------------------------
            lda     DRAW_FACE_INDEX
            sta     FACE_INDEX

            ; --------------------------------
            ; Load face vertices
            ; --------------------------------
            jsr     LOAD_FACE_VERTICES

            ; --------------------------------
            ; Find top and bottom vertices
            ; --------------------------------
            jsr     FIND_FACE_TOP_BOTTOM

            ; --------------------------------
            ; Initialize edge walkers
            ; --------------------------------
            jsr     INIT_FACE_EDGE_WALKERS

            ; --------------------------------
            ; Initialize scanline Y
            ; --------------------------------
            ldx     FACE_TOP_POSITION
            lda     FACE_VERTEX_Y_LIST,x
            sta     FACE_SCAN_Y

            ; --------------------------------
            ; Set horizontal line X coordinates
            ; Use integer portion of 16.16 X
            ; --------------------------------
            lda     EDGE_A_X+2
            sta     X0
            lda     EDGE_A_X+3
            sta     X0+1

            lda     EDGE_B_X+2
            sta     X1
            lda     EDGE_B_X+3
            sta     X1+1

            ; --------------------------------
            ; Set horizontal line Y coordinates
            ; --------------------------------
            lda     FACE_SCAN_Y
            sta     Y0
            sta     Y1

            lda     #0
            sta     Y0+1
            sta     Y1+1

            ; --------------------------------
            ; Draw horizontal span
            ; --------------------------------
@Break:
            jsr     CLAMP_LINE_COORDS
            jsr     _Line

@NextFace:
            inc     DRAW_FACE_INDEX
            lda     DRAW_FACE_INDEX
            cmp     #6
            beq     @Exit
            jmp     @FaceLoop

@Exit:
            rts

; ============================================
; DRAW_MESH_FACE_OUTLINES
;
; Draw outlines of visible faces.
;
; For now:
;   6 faces
;   4 vertices per face
;
; Uses:
;   MODEL_FACES_PTR
;   CUBE_VISIBLE
;   SCREEN_VERTICES
;   CLAMP_LINE_COORDS
;   _Line
; ============================================
DRAW_MESH_FACE_OUTLINES:
            lda     #0
            sta     DRAW_FACE_INDEX

@FaceLoop:
            ; --------------------------------
            ; Skip hidden face
            ; --------------------------------
            ldx     DRAW_FACE_INDEX
            lda     CUBE_VISIBLE,x
            bne     @Continue
            jmp     @NextFace
@Continue:
            ; --------------------------------
            ; Face offset = face * 4
            ; --------------------------------
            lda     DRAW_FACE_INDEX
            asl
            asl
            sta     DRAW_FACE_OFFSET

            ; --------------------------------
            ; Load vertex 0
            ; --------------------------------
            ldy     DRAW_FACE_OFFSET
            lda     (MODEL_FACES_PTR),y
            sta     DRAW_FACE_VERTEX

            lda     DRAW_FACE_VERTEX
            sta     FACE_VERTEX_INDEX
            jsr     LoadVertex

            MOVE16  FACE_VERTEX_X, X0
            MOVE16  FACE_VERTEX_Y, Y0

            ; Save vertex 0 as the closing point
            MOVE16  FACE_VERTEX_X, DRAW_FACE_X0
            MOVE16  FACE_VERTEX_Y, DRAW_FACE_Y0

            ; --------------------------------
            ; Draw vertices 0->1, 1->2, 2->3
            ; --------------------------------
            lda     #3
            sta     DRAW_FACE_LEFT

@EdgeLoop:
            inc     DRAW_FACE_OFFSET
            ldy     DRAW_FACE_OFFSET

            lda     (MODEL_FACES_PTR),y
            sta     FACE_VERTEX_INDEX
            jsr     LoadVertex

            MOVE16  FACE_VERTEX_X, X1
            MOVE16  FACE_VERTEX_Y, Y1

            jsr     CLAMP_LINE_COORDS
            jsr     _Line

            ; Current vertex becomes next X0/Y0
            MOVE16  FACE_VERTEX_X, X0
            MOVE16  FACE_VERTEX_Y, Y0

            dec     DRAW_FACE_LEFT
            bne     @EdgeLoop

            ; --------------------------------
            ; Close face: vertex 3 -> vertex 0
            ; --------------------------------
            MOVE16  DRAW_FACE_X0, X1
            MOVE16  DRAW_FACE_Y0, Y1

            jsr     CLAMP_LINE_COORDS
            jsr     _Line

@NextFace:
            inc     DRAW_FACE_INDEX
            lda     DRAW_FACE_INDEX
            cmp     #6
            beq     @Exit
            jmp     @FaceLoop
@Exit:
            rts


BuildModel
            CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
            CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX

            jsr     CreateProjection   
            rts


DRAW_FACE_INDEX:
            .byte   0
DRAW_FACE_OFFSET:
            .byte   0
DRAW_FACE_LEFT:
            .byte   0
DRAW_FACE_VERTEX:
            .byte   0
DRAW_FACE_X0:
            .word   0
DRAW_FACE_Y0:
            .word   0

FACE_VERTEX_Y_LIST:
            .ds     4
FACE_VERTEX_LIST:
            .ds     4
FACE_TOP_POSITION:
            .byte   0
FACE_BOTTOM_POSITION:
            .byte   0
FACE_TOP_Y:
            .byte   0
FACE_BOTTOM_Y:
            .byte   0
FACE_SCAN_Y:
            .byte   0
