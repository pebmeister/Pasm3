; ====================================================
; DrawWireframeEdges - Renders all edges from CubeEdges
; ====================================================
DrawWireframeEdges:
        ldy #0          ; Index into CubeEdges table
@edge_loop:
        lda CubeEdges,y
        bmi @exit_edges ; $FF marks end of list
        
        ; --- Load Vertex A (Start) into X0, Y0 ---
        tax             ; X = vertex index A
        jsr GetScreenCoords
        lda TempScreenX
        sta X0
        lda TempScreenX+1
        sta X0+1
        lda TempScreenY
        sta Y0          ; (Or store 16-bit Y if your line routine supports it)

        iny
        lda CubeEdges,y
        
        ; --- Load Vertex B (End) into X1, Y1 ---
        tax             ; X = vertex index B
        jsr GetScreenCoords
        lda TempScreenX
        sta X1
        lda TempScreenX+1
        sta X1+1
        lda TempScreenY
        sta Y1

        sty SavedEdgeY  ; Preserve edge list Y index
        ; jsr _Line       ; Call your native line drawer!
        ldy SavedEdgeY  ; Restore edge list Y index

        iny
        jmp @edge_loop
@exit_edges:
        rts

; ====================================================
; Helper: Fetch coordinates from Screen_Output_Buffer
; Input: X = Vertex Index (0 to 7)
; Output: TempScreenX (2 bytes), TempScreenY (1 or 2 bytes)
; ====================================================
GetScreenCoords:
        txa
        asl             ; X * 2
        asl             ; X * 4 (bytes per vertex)
        tay             ; Y = table offset

        lda Screen_Output_Buffer,y
        sta TempScreenX
        iny
        lda Screen_Output_Buffer,y
        sta TempScreenX+1
        iny
        lda Screen_Output_Buffer,y
        sta TempScreenY
        rts