; ====================================================
; 3D Rotation
; written by Paul Baxter using Pasm3
; https://github.com/pebmeister/Pasm3.git
; ====================================================

        .basic_hdr
        
        jsr CLEARSCREEN
        
        lda #$36
        sta $01             ; Configure C64 memory banking:
                            ; LORAM=0, HIRAM=1, CHAREN=1
                            ; BASIC ROM disabled, KERNAL and I/O enabled.                       
        lda #1
        jsr BankSelect

        lda #8              ; Screen RAM at $6000 (slot 8)
        ldy #0              ; Bitmap at $4000 (slot 0)
        jsr SetHGRLayout
        
        jsr HGRInit

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

        SET_TRANSLATION  MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z

        jsr HGROn
        jsr Draw
        
MainLoop:
        jsr GETIN
        beq MainLoop
        jsr ProcessKey
        jsr Draw
        jmp MainLoop

ProcessKey
        ; =======================================================
        ; Check Set Rotation
        ; =======================================================
        ; ===== Z =====
        cmp #KEY_E          ; Rot_Z_Clock
        bne @Check_Rot_Z_Counter_Clock
        jsr Rot_Z_Clock
        rts
        
@Check_Rot_Z_Counter_Clock
        cmp #KEY_Q          ; Rot_Z_Counter_Clock
        bne @Check_Rot_Y_Clock
        jsr Rot_Z_Counter_Clock
        rts

        ; ===== Y =====
@Check_Rot_Y_Clock
        cmp #KEY_D          ; Rot_Y_Clock
        bne @Check_Rot_Y_Counter_Clock
        jsr Rot_Y_Clock
        rts

@Check_Rot_Y_Counter_Clock
        cmp #KEY_A          ; Rot_Y_Counter_Clock
        bne @Check_Rot_X_Clock
        jsr Rot_Y_Counter_Clock
        rts

        ; ===== X =====
@Check_Rot_X_Clock
        cmp #KEY_W          ; Rot_X_Clock        
        bne @Check_Rot_X_Counter_Clock
        jsr Rot_X_Clock
        rts

@Check_Rot_X_Counter_Clock
        cmp #KEY_S          ; Rot_X_Counter_Clock
        bne @Check_Scale_Z_Inc
        jsr Rot_X_Counter_Clock
        rts
        
        ; =======================================================
        ; Check Set Scale
        ; =======================================================
@Check_Scale_Z_Inc
        ; ===== Z =====
        cmp #KEY_SHIFT_E    ; Scale_Z_Inc
        bne @Check_Scale_Z_Dec
        jsr Scale_Z_Inc
        rts

@Check_Scale_Z_Dec
        cmp #KEY_SHIFT_Q    ; Scale_Z_Dec
        bne @Check_Scale_Y_Inc
        jsr Scale_Z_Dec
        rts

        ; ===== Y =====
@Check_Scale_Y_Inc
        cmp #KEY_SHIFT_D    ; Scale_Y_Inc
        bne @Check_Scale_Y_Dec
        jsr Scale_Y_Inc
        rts

@Check_Scale_Y_Dec
        cmp #KEY_SHIFT_A    ; Scale_Y_Dec
        bne @Check_Scale_X_Inc
        jsr Scale_Y_Dec
        rts

        ; ===== X =====
@Check_Scale_X_Inc
        cmp #KEY_SHIFT_W    ; Scale_X_Inc
        bne @Check_Scale_X_Dec
        jsr Scale_X_Inc
        rts

@Check_Scale_X_Dec
        cmp #KEY_SHIFT_S    ; Scale_X_Dec
        bne @Check_Trans_Z_Inc
        jsr Scale_X_Dec
        rts

        ; =======================================================
        ; Check Set Translation
        ; =======================================================
@Check_Trans_Z_Inc
        ; ===== Z =====
        cmp #KEY_CTRL_E    ; Trans_Z_Inc
        bne @Check_Trans_Z_Dec
        jsr Trans_Z_Inc
        rts

@Check_Trans_Z_Dec
        cmp #KEY_CTRL_Q    ; Trans_Z_Dec
        bne @Check_Trans_Y_Inc
        jsr Trans_Z_Dec
        rts

        ; ===== Y =====
@Check_Trans_Y_Inc
        cmp #KEY_CLR_ENTRY  ; Trans_Y_Inc
        bne @Check_Trans_Y_Dec
        jsr Trans_Y_Inc
        rts

@Check_Trans_Y_Dec
        cmp #KEY_CTRL_A       ; Trans_Y_Dec
        bne @Check_Trans_X_Inc
        jsr Trans_Y_Dec
        rts

        ; ===== X =====
@Check_Trans_X_Inc
        cmp #KEY_CTRL_W    ; Scale_X_Inc
        bne @Check_Trans_X_Dec
        jsr Trans_X_Inc
        rts

@Check_Trans_X_Dec
        cmp #KEY_HOME     ; Scale_X_Dec
        bne @Check_Reset
        jsr Trans_X_Dec
        rts

        ; =======================================================
        ; Reset
        ; =======================================================
@Check_Reset
        cmp #KEY_RETURN
        bne @Done
        jsr Reset
@Done
        rts
        
        ; *************************************************************    
        ; Rot_Z_Clock
        ; *************************************************************            
Rot_Z_Clock
        ADD8I ROT_Z_ANGLE, ROT_DELTA, ROT_Z_ANGLE
        jsr Update_Z_Rotation
        rts
        
        ; *************************************************************    
        ; Rot_Z_Counter_Clock
        ; *************************************************************            
Rot_Z_Counter_Clock
        SUB8I ROT_Z_ANGLE, ROT_DELTA, ROT_Z_ANGLE
        jsr Update_Z_Rotation
        rts

        ; *************************************************************    
        ; Rot_Y_Clock
        ; *************************************************************            
Rot_Y_Clock
        ADD8I ROT_Y_ANGLE, ROT_DELTA, ROT_Y_ANGLE
        jsr Update_Y_Rotation
        rts
        
        ; *************************************************************    
        ; Rot_Y_Counter_Clock
        ; *************************************************************            
Rot_Y_Counter_Clock
        SUB8I ROT_Y_ANGLE, ROT_DELTA, ROT_Y_ANGLE
        jsr Update_Y_Rotation
        rts

        ; *************************************************************    
        ; Rot_X_Clock
        ; *************************************************************            
Rot_X_Clock
        ADD8I ROT_X_ANGLE, ROT_DELTA, ROT_X_ANGLE
        jsr Update_X_Rotation
        rts

        ; *************************************************************    
        ; Rot_X_Counter_Clock
        ; *************************************************************            
Rot_X_Counter_Clock
        SUB8I ROT_X_ANGLE, ROT_DELTA, ROT_X_ANGLE
        jsr Update_X_Rotation
        rts
         
        ; *************************************************************    
        ; Scale_Z_Inc
        ; *************************************************************            
Scale_Z_Inc
        ADD_FIX16 SCALE_Z, SCALE_INCREMENT, SCALE_Z
        jsr BUILD_SCALING_MATRIX_Z
        rts
          
        ; *************************************************************    
        ; Scale_Z_Dec
        ; *************************************************************            
Scale_Z_Dec
        ADD_FIX16 SCALE_Z, SCALE_DECREMENT, SCALE_Z
        jsr BUILD_SCALING_MATRIX_Z
        rts
              
        ; *************************************************************    
        ; Scale_Y_Inc
        ; *************************************************************            
Scale_Y_Inc
        ADD_FIX16 SCALE_Y, SCALE_INCREMENT, SCALE_Y
        jsr BUILD_SCALING_MATRIX_Y
        rts
          
        ; *************************************************************    
        ; Scale_Y_Dec
        ; *************************************************************            
Scale_Y_Dec
        ADD_FIX16 SCALE_Y, SCALE_DECREMENT, SCALE_Y
        jsr BUILD_SCALING_MATRIX_Y
        rts
              
        ; *************************************************************    
        ; Scale_X_Inc
        ; *************************************************************            
Scale_X_Inc
        ADD_FIX16 SCALE_X, SCALE_INCREMENT, SCALE_X
        jsr BUILD_SCALING_MATRIX_X
        rts
          
        ; *************************************************************    
        ; Scale_X_Dec
        ; *************************************************************            
Scale_X_Dec
        ADD_FIX16 SCALE_X, SCALE_DECREMENT, SCALE_X
        jsr BUILD_SCALING_MATRIX_X
        rts

        ; *************************************************************    
        ; Trans_Z_Inc
        ; *************************************************************            
Trans_Z_Inc
        ADD_FIX16 TRANS_Z, TRANS_INCREMENT, TRANS_Z
        jsr BUILD_TRANSLATION_MATRIX_Z
        rts
          
        ; *************************************************************    
        ; Trans_Z_Dec
        ; *************************************************************            
Trans_Z_Dec
        ADD_FIX16 TRANS_Z, TRANS_DECREMENT, TRANS_Z
        jsr BUILD_TRANSLATION_MATRIX_Z
        rts
              
        ; *************************************************************    
        ; Trans_Y_Inc
        ; *************************************************************            
Trans_Y_Inc
        ADD_FIX16 TRANS_Y, TRANS_INCREMENT, TRANS_Y
        jsr BUILD_TRANSLATION_MATRIX_Y
        rts
          
        ; *************************************************************    
        ; Trans_Y_Dec
        ; *************************************************************            
Trans_Y_Dec
        ADD_FIX16 TRANS_Y, TRANS_DECREMENT, TRANS_Y
        jsr BUILD_TRANSLATION_MATRIX_Y
        rts
              
        ; *************************************************************    
        ; Trans_X_Inc
        ; *************************************************************            
Trans_X_Inc
        ADD_FIX16 TRANS_X, TRANS_INCREMENT, TRANS_X
        jsr BUILD_TRANSLATION_MATRIX_X
        rts
          
        ; *************************************************************    
        ; Trans_X_Dec
        ; *************************************************************            
Trans_X_Dec
        ADD_FIX16 TRANS_X, TRANS_DECREMENT, TRANS_X
        jsr BUILD_TRANSLATION_MATRIX_X
        rts
                            
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
