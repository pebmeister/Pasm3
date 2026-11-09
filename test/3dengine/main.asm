; ====================================================
; 3D Rotation
; written by Paul Baxter using Pasm3
; https://github.com/pebmeister/Pasm3.git
; ====================================================

        .basic_hdr

        lda #COLOR_WHITE
        jsr _HGRFColor
        lda #COLOR_BLACK
        jsr _HGRBColor

        jsr HGRCls
                                
        SET_SCALE MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z

        MOVE8 MY_ROT_Z, ROT_Z_ANGLE
        MOVE8 MY_ROT_Y, ROT_Y_ANGLE
        MOVE8 MY_ROT_X, ROT_X_ANGLE

        jsr ROTATION_Z
        jsr ROTATION_Y
        jsr ROTATION_X

        jsr BUILD_ROT_ZY_MATRIX
        jsr BUILD_ROTATION_MATRIX_X

        jsr Update_Translation

        jsr HGROn
        jmp Draw
        
MainLoop:
        jsr GETIN
        beq MainLoop
        
        ; =======================================================
        ; Set Rotation
        ; =======================================================

        ; ===== Z =====
        cmp #KEY_E          ; Rot_Z_Clock
        beq @Rot_Z_Clock

        cmp #KEY_Q          ; Rot_Z_Counter_Clock
        beq @Rot_Z_Counter_Clock

        ; ===== Y =====
        cmp #KEY_D          ; Rot_Y_Clock
        beq @Rot_Y_Clock

        cmp #KEY_A          ; Rot_Y_Counter_Clock
        beq @Rot_Y_Counter_Clock

        ; ===== X =====
        cmp #KEY_W          ; Rot_X_Clock        
        beq @Rot_X_Clock

        cmp #KEY_S          ; Rot_X_Counter_Clock
        beq @Rot_X_Counter_Clock
        
        ; =======================================================
        ; Set Scale
        ; =======================================================

        ; ===== Z =====
        cmp #KEY_SHIFT_E    ; Scale_Z_Inc
        bne @Check_Scale_Z_Dec
        jmp @Scale_Z_Inc

@Check_Scale_Z_Dec
        cmp #KEY_SHIFT_Q    ; Scale_Z_Dec
        bne @Check_Scale_Y_Inc
        jmp @Scale_Z_Dec

        ; ===== Y =====
@Check_Scale_Y_Inc
        cmp #KEY_SHIFT_D    ; Scale_Y_Inc
        bne @Check_Scale_Y_Dec
        jmp @Scale_Y_Inc

@Check_Scale_Y_Dec
        cmp #KEY_SHIFT_A    ; Scale_Y_Dec
        bne @Check_Scale_X_Inc
        jmp @Scale_Y_Dec

        ; ===== X =====
@Check_Scale_X_Inc
        cmp #KEY_SHIFT_W    ; Scale_X_Inc
        bne @Check_Scale_X_Dec
        jmp @Scale_X_Inc

@Check_Scale_X_Dec
        cmp #KEY_SHIFT_S    ; Scale_X_Dec
        bne @Check_Reset
        jmp @Scale_X_Dec

        ; =======================================================
        ; Reset
        ; =======================================================
@Check_Reset
        cmp #KEY_RETURN
        bne MainLoop
        jmp @Reset
        
@Rot_Z_Clock
        ADD8I ROT_Z_ANGLE, ROT_DELTA, ROT_Z_ANGLE
        jsr Update_Z_Rotation
        jmp Draw
        
@Rot_Z_Counter_Clock
        SUB8I ROT_Z_ANGLE, ROT_DELTA, ROT_Z_ANGLE
        jsr Update_Z_Rotation
        jmp Draw

@Rot_Y_Clock
        ADD8I ROT_Y_ANGLE, ROT_DELTA, ROT_Y_ANGLE
        jsr Update_Y_Rotation
        jmp Draw
        
@Rot_Y_Counter_Clock
        SUB8I ROT_Y_ANGLE, ROT_DELTA, ROT_Y_ANGLE
        jsr Update_Y_Rotation
        jmp Draw

@Rot_X_Clock
        ADD8I ROT_X_ANGLE, ROT_DELTA, ROT_X_ANGLE
        jsr Update_X_Rotation
        jmp Draw

@Rot_X_Counter_Clock
        SUB8I ROT_X_ANGLE, ROT_DELTA, ROT_X_ANGLE
        jsr Update_X_Rotation
        jmp Draw
          
@Scale_Z_Inc
        ADD_FIX16 SCALE_Z, SCALE_INCREMENT, SCALE_Z
        jsr BUILD_SCALING_MATRIX_Z
        jmp Draw
          
@Scale_Z_Dec
        ADD_FIX16 SCALE_Z, SCALE_DECREMENT, SCALE_Z
        jsr BUILD_SCALING_MATRIX_Z
        jmp Draw
              
@Scale_Y_Inc
        ADD_FIX16 SCALE_Y, SCALE_INCREMENT, SCALE_Y
        jsr BUILD_SCALING_MATRIX_Y
        jmp Draw
          
@Scale_Y_Dec
        ADD_FIX16 SCALE_Y, SCALE_DECREMENT, SCALE_Y
        jsr BUILD_SCALING_MATRIX_Y
        jmp Draw
              
@Scale_X_Inc
        ADD_FIX16 SCALE_X, SCALE_INCREMENT, SCALE_X
        jsr BUILD_SCALING_MATRIX_X
        jmp Draw
          
@Scale_X_Dec
        ADD_FIX16 SCALE_X, SCALE_DECREMENT, SCALE_X
        jsr BUILD_SCALING_MATRIX_X
        jmp Draw
              
@Reset
        MOVE8 MY_ROT_Z, ROT_Z_ANGLE
        MOVE8 MY_ROT_Y, ROT_Y_ANGLE
        MOVE8 MY_ROT_X, ROT_X_ANGLE

        jsr ROTATION_Z
        jsr ROTATION_Y
        jsr ROTATION_X

        jsr BUILD_ROT_ZY_MATRIX
        jsr BUILD_ROTATION_MATRIX_X

        SET_SCALE MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z

        jsr Update_Translation
        jmp Draw
        
Draw
        CALL_MAT4_MUL ROTATION_MATRIX, SCALING_MATRIX, ROT_SCALE_MATRIX
        CALL_MAT4_MUL TRANSLATION_MATRIX, ROT_SCALE_MATRIX, MODEL_MATRIX        

        jsr CreateProjection
        jsr HGRCls
        jsr DRAW_PYRAMID_EDGES
        jmp MainLoop

        
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
        
Update_Translation
        SET_TRANSLATION  MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z
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
        