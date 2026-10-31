; ============================================
; RENDER_OBJECT
; Iterates through all vertices of the pyramid,
; transforms them via WORLD_MATRIX, and projects them.
; ============================================
RENDER_OBJECT:
        lda #0
        sta VERTEX_INDEX

VERT_LOOP:
        ; 1. Grab low byte of current vertex address from table
        ldx VERTEX_INDEX
        lda VERTEX_PTR_L,x
        sta CURRENT_VERTEX_PTR

        ; 2. Grab high byte of current vertex address from table
        ldx VERTEX_INDEX
        lda VERTEX_PTR_H,x
        sta CURRENT_VERTEX_PTR+1

        ; 3. Transform vector: TRANSFORMED_VERTEX = WORLD_MATRIX * CURRENT_VERTEX
        ; (Using zero-page indirect pointer for dynamic vertex source)
        lda #<WORLD_MATRIX
        sta MAT4_MATRIX_PTR
        lda #>WORLD_MATRIX
        sta MAT4_MATRIX_PTR+1

        lda CURRENT_VERTEX_PTR
        sta MAT4_VIN_PTR
        lda CURRENT_VERTEX_PTR+1
        sta MAT4_VIN_PTR+1

        lda #<TRANSFORMED_VERTEX
        sta MAT4_VOUT_PTR
        lda #>TRANSFORMED_VERTEX
        sta MAT4_VOUT_PTR+1

        jsr MAT4_VECTOR_MUL

        ; 4. Project 3D camera coordinates to 2D screen coordinates
        jsr PROJECT_VERTEX

        ; 5. Store resulting screen coordinates for edge rendering
        jsr STORE_SCREEN_COORD

        ; 6. Advance to next vertex
        inc VERTEX_INDEX
        lda VERTEX_INDEX
        cmp #NUM_VERTICES
        bne VERT_LOOP

        rts
        
        
; ============================================
; PROJECT_VERTEX
; Projects 3D camera space [X, Y, Z] to 2D screen [X, Y]
; using a reciprocal lookup table for Z division.
; ============================================
PROJECT_VERTEX:
        ; 1. Get high byte of Z integer part for reciprocal table index
        ldy TRANSFORMED_VERTEX + 10
        lda RECIP_TABLE,y
        sta RECIP_VAL

        ; 2. Multiply X by Reciprocal to get projected X
        lda TRANSFORMED_VERTEX
        sta MAT_MUL_A
        lda TRANSFORMED_VERTEX + 1
        sta MAT_MUL_A + 1
        lda TRANSFORMED_VERTEX + 2
        sta MAT_MUL_A + 2
        lda TRANSFORMED_VERTEX + 3
        sta MAT_MUL_A + 3

        lda RECIP_VAL
        sta MAT_MUL_B
        lda #0
        sta MAT_MUL_B + 1
        sta MAT_MUL_B + 2
        sta MAT_MUL_B + 3

        jsr FIX16_MUL

        ; 3. Add screen center offset X (e.g. 160 for C64)
        lda MAT_PRODUCT + 2
        clc
        adc #SCREEN_CENTER_X
        sta PROJ_X

        ; 4. Multiply Y by Reciprocal to get projected Y
        lda TRANSFORMED_VERTEX + 4
        sta MAT_MUL_A
        lda TRANSFORMED_VERTEX + 5
        sta MAT_MUL_A + 1
        lda TRANSFORMED_VERTEX + 6
        sta MAT_MUL_A + 2
        lda TRANSFORMED_VERTEX + 7
        sta MAT_MUL_A + 3

        lda RECIP_VAL
        sta MAT_MUL_B
        lda #0
        sta MAT_MUL_B + 1
        sta MAT_MUL_B + 2
        sta MAT_MUL_B + 3

        jsr FIX16_MUL

        ; 5. Add screen center offset Y (e.g. 100 for C64)
        lda MAT_PRODUCT + 2
        clc
        adc #SCREEN_CENTER_Y
        sta PROJ_Y

        rts


; ============================================
; STORE_SCREEN_COORD
; Stores projected screen coordinates into arrays
; indexed by VERTEX_INDEX for the edge drawer.
; ============================================
STORE_SCREEN_COORD:
        ldx VERTEX_INDEX
        lda PROJ_X
        sta SCREEN_X_LIST,x
        lda PROJ_Y
        sta SCREEN_Y_LIST,x
        rts
        
        
; ============================================
; DRAW_WIREFRAME Routine
; (Writes directly to gr library X0, Y0, X1, Y1)
; ============================================
DRAW_WIREFRAME:
        ldx #0
        stx EDGE_INDEX

DRAW_EDGE_LOOP:
        ; 1. Get start vertex index
        ldx EDGE_INDEX
        lda EDGE_START_LIST,x
        tay

        ; 2. Store start X (16-bit) directly to gr lib X0
        lda SCREEN_X_L,y
        sta X0
        lda SCREEN_X_H,y
        sta X0 + 1

        ; 3. Store start Y (8-bit) directly to gr lib Y0
        lda SCREEN_Y_LIST,y
        sta Y0

        ; 4. Get end vertex index
        ldx EDGE_INDEX
        lda EDGE_END_LIST,x
        tay

        ; 5. Store end X (16-bit) directly to gr lib X1
        lda SCREEN_X_L,y
        sta X1
        lda SCREEN_X_H,y
        sta X1 + 1

        ; 6. Store end Y (8-bit) directly to gr lib Y1
        lda SCREEN_Y_LIST,y
        sta Y1

        ; 7. Call gr library line drawer
        jsr _Line

        ; 8. Advance edge counter and loop
        inc EDGE_INDEX
        ldx EDGE_INDEX
        cpx #NUM_EDGES
        bne DRAW_EDGE_LOOP

        rts
        

