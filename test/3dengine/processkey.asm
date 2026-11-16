ProcessKey:
        ; =======================================================
        ; Check Set Rotation
        ; =======================================================
        ; ===== Z =====
        cmp #KEY_E          ; Rot_Z_Clock
        bne @Check_Rot_Z_Counter_Clock
        jmp Rot_Z_Clock
        
@Check_Rot_Z_Counter_Clock
        cmp #KEY_Q          ; Rot_Z_Counter_Clock
        bne @Check_Rot_Y_Clock
        jmp Rot_Z_Counter_Clock

        ; ===== Y =====
@Check_Rot_Y_Clock
        cmp #KEY_D          ; Rot_Y_Clock
        bne @Check_Rot_Y_Counter_Clock
        jmp Rot_Y_Clock

@Check_Rot_Y_Counter_Clock
        cmp #KEY_A          ; Rot_Y_Counter_Clock
        bne @Check_Rot_X_Clock
        jmp Rot_Y_Counter_Clock

        ; ===== X =====
@Check_Rot_X_Clock
        cmp #KEY_W          ; Rot_X_Clock        
        bne @Check_Rot_X_Counter_Clock
        jmp Rot_X_Clock

@Check_Rot_X_Counter_Clock
        cmp #KEY_S          ; Rot_X_Counter_Clock
        bne @Check_Scale_Z_Inc
        jmp Rot_X_Counter_Clock
        
        ; =======================================================
        ; Check Set Scale
        ; =======================================================
@Check_Scale_Z_Inc
        ; ===== Z =====
        cmp #KEY_SHIFT_E    ; Scale_Z_Inc
        bne @Check_Scale_Z_Dec
        jmp Scale_Z_Inc

@Check_Scale_Z_Dec
        cmp #KEY_SHIFT_Q    ; Scale_Z_Dec
        bne @Check_Scale_Y_Inc
        jmp Scale_Z_Dec

        ; ===== Y =====
@Check_Scale_Y_Inc
        cmp #KEY_SHIFT_D    ; Scale_Y_Inc
        bne @Check_Scale_Y_Dec
        jmp Scale_Y_Inc

@Check_Scale_Y_Dec
        cmp #KEY_SHIFT_A    ; Scale_Y_Dec
        bne @Check_Scale_X_Inc
        jmp Scale_Y_Dec

        ; ===== X =====
@Check_Scale_X_Inc
        cmp #KEY_SHIFT_W    ; Scale_X_Inc
        bne @Check_Scale_X_Dec
        jmp Scale_X_Inc

@Check_Scale_X_Dec
        cmp #KEY_SHIFT_S    ; Scale_X_Dec
        bne @Check_Trans_Z_Inc
        jmp Scale_X_Dec

        ; =======================================================
        ; Check Set Translation
        ; =======================================================
@Check_Trans_Z_Inc
        ; ===== Z =====
        cmp #KEY_CTRL_E    ; Trans_Z_Inc
        bne @Check_Trans_Z_Dec
        jmp Trans_Z_Inc

@Check_Trans_Z_Dec
        cmp #KEY_CTRL_Q    ; Trans_Z_Dec
        bne @Check_Trans_Y_Inc
        jmp Trans_Z_Dec

        ; ===== Y =====
@Check_Trans_Y_Inc
        cmp #KEY_CLR_ENTRY  ; Trans_Y_Inc
        bne @Check_Trans_Y_Dec
        jmp Trans_Y_Inc

@Check_Trans_Y_Dec
        cmp #KEY_CTRL_A       ; Trans_Y_Dec
        bne @Check_Trans_X_Inc
        jmp Trans_Y_Dec

        ; ===== X =====
@Check_Trans_X_Inc
        cmp #KEY_CTRL_W    ; Trans_X_Inc
        bne @Check_Trans_X_Dec
        jmp Trans_X_Inc

@Check_Trans_X_Dec
        cmp #KEY_HOME     ; Trans_X_Dec
        bne @Check_Load_Pyramid
        jmp Trans_X_Dec

        ; =======================================================
        ; Check Change Model
        ; =======================================================
@Check_Load_Pyramid
        cmp #KEY_P        ; Load_Pyramid
        bne @Check_Load_Cube
        jmp Load_Pyramid

@Check_Load_Cube
        cmp #KEY_C        ; Load_Cube
        bne @Check_Info
        jmp Load_Cube

        ; =======================================================
        ; Info
        ; =======================================================
@Check_Info
        cmp #KEY_I
        bne @Check_Debug
        jmp Info

        ; =======================================================
        ; Info
        ; =======================================================
@Check_Debug
        cmp #KEY_SHIFT_I
        bne @Check_Reset
        jmp Debug

        ; =======================================================
        ; Reset
        ; =======================================================
@Check_Reset
        cmp #KEY_RETURN
        bne @Done
        jmp Reset
@Done
        rts
        
        ; *************************************************************    
        ; Rot_Z_Clock
        ; *************************************************************            
Rot_Z_Clock
        ADD8I ROT_Z_ANGLE, ROT_DELTA, ROT_Z_ANGLE
        jmp Update_Z_Rotation
        
        ; *************************************************************    
        ; Rot_Z_Counter_Clock
        ; *************************************************************            
Rot_Z_Counter_Clock
        SUB8I ROT_Z_ANGLE, ROT_DELTA, ROT_Z_ANGLE
        jmp Update_Z_Rotation

        ; *************************************************************    
        ; Rot_Y_Clock
        ; *************************************************************            
Rot_Y_Clock
        ADD8I ROT_Y_ANGLE, ROT_DELTA, ROT_Y_ANGLE
        jmp Update_Y_Rotation
        
        ; *************************************************************    
        ; Rot_Y_Counter_Clock
        ; *************************************************************            
Rot_Y_Counter_Clock
        SUB8I ROT_Y_ANGLE, ROT_DELTA, ROT_Y_ANGLE
        jmp Update_Y_Rotation

        ; *************************************************************    
        ; Rot_X_Clock
        ; *************************************************************            
Rot_X_Clock
        ADD8I ROT_X_ANGLE, ROT_DELTA, ROT_X_ANGLE
        jmp Update_X_Rotation

        ; *************************************************************    
        ; Rot_X_Counter_Clock
        ; *************************************************************            
Rot_X_Counter_Clock
        SUB8I ROT_X_ANGLE, ROT_DELTA, ROT_X_ANGLE
        jmp Update_X_Rotation
         
        ; *************************************************************    
        ; Scale_Z_Inc
        ; *************************************************************            
Scale_Z_Inc
        ADD_FIX16 SCALE_Z, SCALE_INCREMENT, SCALE_Z
        jmp BUILD_SCALING_MATRIX_Z
          
        ; *************************************************************    
        ; Scale_Z_Dec
        ; *************************************************************            
Scale_Z_Dec
        ADD_FIX16 SCALE_Z, SCALE_DECREMENT, SCALE_Z
        jmp BUILD_SCALING_MATRIX_Z
              
        ; *************************************************************    
        ; Scale_Y_Inc
        ; *************************************************************            
Scale_Y_Inc
        ADD_FIX16 SCALE_Y, SCALE_INCREMENT, SCALE_Y
        jmp BUILD_SCALING_MATRIX_Y
          
        ; *************************************************************    
        ; Scale_Y_Dec
        ; *************************************************************            
Scale_Y_Dec
        ADD_FIX16 SCALE_Y, SCALE_DECREMENT, SCALE_Y
        jmp BUILD_SCALING_MATRIX_Y
              
        ; *************************************************************    
        ; Scale_X_Inc
        ; *************************************************************            
Scale_X_Inc
        ADD_FIX16 SCALE_X, SCALE_INCREMENT, SCALE_X
        jmp BUILD_SCALING_MATRIX_X
          
        ; *************************************************************    
        ; Scale_X_Dec
        ; *************************************************************            
Scale_X_Dec
        ADD_FIX16 SCALE_X, SCALE_DECREMENT, SCALE_X
        jmp BUILD_SCALING_MATRIX_X

        ; *************************************************************    
        ; Trans_Z_Inc
        ; *************************************************************            
Trans_Z_Inc
        ADD_FIX16 TRANS_Z, TRANS_INCREMENT, TRANS_Z
        jmp BUILD_TRANSLATION_MATRIX_Z
          
        ; *************************************************************    
        ; Trans_Z_Dec
        ; *************************************************************            
Trans_Z_Dec
        ADD_FIX16 TRANS_Z, TRANS_DECREMENT, TRANS_Z
        jmp BUILD_TRANSLATION_MATRIX_Z
              
        ; *************************************************************    
        ; Trans_Y_Inc
        ; *************************************************************            
Trans_Y_Inc
        ADD_FIX16 TRANS_Y, TRANS_INCREMENT, TRANS_Y
        jmp BUILD_TRANSLATION_MATRIX_Y
          
        ; *************************************************************    
        ; Trans_Y_Dec
        ; *************************************************************            
Trans_Y_Dec
        ADD_FIX16 TRANS_Y, TRANS_DECREMENT, TRANS_Y
        jmp BUILD_TRANSLATION_MATRIX_Y
              
        ; *************************************************************    
        ; Trans_X_Inc
        ; *************************************************************            
Trans_X_Inc
        ADD_FIX16 TRANS_X, TRANS_INCREMENT, TRANS_X
        jmp BUILD_TRANSLATION_MATRIX_X
          
        ; *************************************************************    
        ; Trans_X_Dec
        ; *************************************************************            
Trans_X_Dec
        ADD_FIX16 TRANS_X, TRANS_DECREMENT, TRANS_X
        jmp BUILD_TRANSLATION_MATRIX_X
                            

        ; *************************************************************    
        ; Reset
        ; *************************************************************            
Reset
        MOVE8 MY_ROT_Z, ROT_Z_ANGLE
        MOVE8 MY_ROT_Y, ROT_Y_ANGLE
        MOVE8 MY_ROT_X, ROT_X_ANGLE

        jsr ROTATION_Z
        jsr ROTATION_Y
        jsr ROTATION_X

        jsr BUILD_ROT_ZY_MATRIX
        jsr BUILD_ROTATION_MATRIX_X

        SET_SCALE MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z
        SET_TRANSLATION MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z
        rts 


        ; *************************************************************    
        ; Debug
        ; *************************************************************            
Debug
        lda Border
        sta Info@Border_Color
        jsr SwitchToText
        jsr DrawDebugInfo
        jmp Info@Loop

        ; *************************************************************    
        ; Info
        ; *************************************************************            
Info
        lda Border
        sta @Border_Color
        jsr SwitchToText
        jsr DrawInfo
@Loop
        jsr GETIN
        beq @Loop

        
        jsr SwitchToHGR
        lda @Border_Color
        sta Border
        rts

@Border_Color
        .ds 1
        
        ; *************************************************************    
        ; Load_Pyramid
        ; *************************************************************            
Load_Pyramid
        lda #<__PYRAMID_VERTICES
        sta MODEL_VERTICES_PTR
        lda #>__PYRAMID_VERTICES
        sta MODEL_VERTICES_PTR + 1
        lda #<__PYRAMID_EDGES
        sta MODEL_EDGES_PTR
        lda #>__PYRAMID_EDGES
        sta MODEL_EDGES_PTR + 1
        lda __PYRAMID_VERTEX_COUNT
        sta MODEL_VERTEX_COUNT              
        lda __PYRAMID_EDGE_COUNT
        sta MODEL_NUM_EDGES
        lda #1
        sta CUR_MODEL
        rts

        ; *************************************************************    
        ; Load_Cube
        ; *************************************************************            
Load_Cube
        lda #<__CUBE_VERTICES
        sta MODEL_VERTICES_PTR
        lda #>__CUBE_VERTICES
        sta MODEL_VERTICES_PTR + 1
        lda #<__CUBE_EDGES
        sta MODEL_EDGES_PTR
        lda #>__CUBE_EDGES
        sta MODEL_EDGES_PTR + 1
        lda __CUBE_VERTEX_COUNT
        sta MODEL_VERTEX_COUNT              
        lda __CUBE_EDGE_COUNT
        sta MODEL_NUM_EDGES
        lda #2
        sta CUR_MODEL
        rts
