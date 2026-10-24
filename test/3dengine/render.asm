

; ====================================================
; DRAW WIREFRAME EDGES (Zero new variables, stack-based)
; ====================================================
DrawWireframeEdges:
        jmp PlotVertexDots
        

        ldy #0                  ; Y = index in CubeEdges table

@Edge_Loop:
        lda CubeEdges,y
        bmi @Edge_Exit          ; $FF marks end of table
        
        tax                     ; X = Vertex A index
        tya
        pha                     ; Save edge table Y index on stack

        ; --- Load Vertex A directly into X0, Y0 ---
        txa
        asl
        asl
        tay
        lda Screen_Output_Buffer,y
        sta X0
        iny
        lda Screen_Output_Buffer,y
        sta X0+1
        iny
        lda Screen_Output_Buffer,y
        sta Y0

        pla                     ; Restore edge table Y index
        tay
        iny                     ; Advance to Vertex B index in table

        lda CubeEdges,y
        tax                     ; X = Vertex B index
        tya
        pha                     ; Save edge table Y index on stack

        ; --- Load Vertex B directly into X1, Y1 ---
        txa
        asl
        asl
        tay
        lda Screen_Output_Buffer,y
        sta X1
        iny
        lda Screen_Output_Buffer,y
        sta X1+1
        iny
        lda Screen_Output_Buffer,y
        sta Y1

        pla                     ; Restore edge table Y index
        tay

        jsr _Line               ; Draw the edge!

        iny                     ; Move to next edge pair
        jmp @Edge_Loop

@Edge_Exit:
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
 
; ====================================================
; TRANSFORM & PROJECT VERTICES (Proper PTR_MAT_B Binding)
; ====================================================
TransformAndProjectVertices:
        ldx #0                  ; X = Vertex index (0 to 7)

@TP_VertexLoop:
        cpx #NumVertices
        bcs @TP_VertexDone

        txa
        pha                     ; Save vertex index on stack

        ; Compute vertex table offset: index * 6 (6 bytes per vertex: X, Y, Z)
        asl                     ; index * 2
        sta TMP                 ; Store index * 2 in TMP
        asl                     ; index * 4
        clc
        adc TMP                 ; (index * 4) + (index * 2) = index * 6
        tay                     ; Y = offset in CubeVertices table

        ; --- Set PTR_MAT_B to point directly to this vertex ---
        tya
        clc
        adc #<CubeVertices
        sta PTR_MAT_B           ; PTR_MAT_B low byte
        lda #>CubeVertices
        adc #0                  ; Add carry to high byte
        sta PTR_MAT_B+1         ; PTR_MAT_B high byte

        ; Rotate 3D vertex -> RotX, RotY, RotZ (reads via PTR_MAT_B)
        jsr RotateVertex

        ; Project 2D screen coordinates -> XCOORD, YCOL
        jsr ProjectToScreen

        ; Restore vertex index from stack
        pla
        tax

        ; Compute output buffer offset: index * 4
        txa
        asl
        asl
        tay                     ; Y = offset in Screen_Output_Buffer

        ; Store XCOORD (2 bytes)
        lda XCOORD
        sta Screen_Output_Buffer,y
        iny
        lda XCOORD+1
        sta Screen_Output_Buffer,y
        iny

        ; Store YCOL (1 byte)
        lda YCOL
        sta Screen_Output_Buffer,y

        ; Next vertex
        inx
        jmp @TP_VertexLoop

@TP_VertexDone:
        rts
        

; ====================================================
; ROTATE VERTEX (Matrix Multiplier or Identity Stub)
; ====================================================
RotateVertex:
        ; If your project uses a specific matrix multiplication routine, 
        ; call it here. Otherwise, pass-through stub for testing:
        MOVE16 Vx, RotX
        MOVE16 Vy, RotY
        MOVE16 Vz, RotZ
        rts


; ====================================================
; PROJECT TO SCREEN (Clean 16-bit 8.8 Fixed-Point Scaling)
; Center: X = 160 ($00A0), Y = 100 ($64)
; ====================================================
ProjectToScreen:
        ; --- X Projection & Scaling (RotX / 4 + 160) ---
        lda RotX
        sta XCOORD
        lda RotX+1
        sta XCOORD+1

        ; Arithmetic shift right by 2 (divides 8.8 fixed-point by 4 for screen scale)
        lda XCOORD+1
        cmp #$80                ; Set carry if negative (sign extension)
        ror XCOORD+1
        ror XCOORD
        lda XCOORD+1
        cmp #$80
        ror XCOORD+1
        ror XCOORD

        ; Add Screen Center X offset (160 = $00A0)
        clc
        lda XCOORD
        adc #<160
        sta XCOORD
        lda XCOORD+1
        adc #>160
        sta XCOORD+1


        ; --- Y Projection & Scaling (RotY / 4 + 100) ---
        lda RotY
        sta YCOL                ; Low byte of Y
        lda RotY+1
        sta TMP                 ; High byte of Y in scratch TMP

        ; Arithmetic shift right by 2 (divides by 4)
        lda TMP
        cmp #$80                ; Set carry if negative
        ror TMP
        ror YCOL
        lda TMP
        cmp #$80
        ror TMP
        ror YCOL

        ; Add Screen Center Y offset (100 = $64) to low byte
        clc
        lda YCOL
        adc #100
        sta YCOL
        rts
        
        
; ====================================================
; PLOT VERTEX DOTS (Zero new variables)
; ====================================================
PlotVertexDots:
        ldx #0                  ; X = Vertex index (0 to 7)

@Dot_Loop:
        cpx #NumVertices
        bcs @Dot_Done

        txa
        pha                     ; Save vertex index on stack

        ; Compute buffer offset: index * 4
        asl
        asl
        tay                     ; Y = offset in Screen_Output_Buffer

        ; Load X (16-bit) into X0
        lda Screen_Output_Buffer,y
        sta X0
        iny
        lda Screen_Output_Buffer,y
        sta X0+1
        iny

        ; Load Y (8-bit) into Y0
        lda Screen_Output_Buffer,y
        sta Y0

        pla
        tax
        stx @SavedIndex         ; Save index across pixel plotter call

        ; Call your native pixel plotting routine 
        jsr _Plot            

        ldx @SavedIndex
        inx
        jmp @Dot_Loop

@Dot_Done:
        rts

@SavedIndex:
        .byte 0