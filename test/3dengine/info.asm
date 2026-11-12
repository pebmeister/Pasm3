ROT_COL         = 3
SCALE_COL       = 8
TRANS_COL       = 18
MISC_COL        = 16

BITMAP_SAVE   .ds 2
COLOR_SAVE    .ds 2

SwitchToText:
            lda #$00            ; Select VIC Bank 0 ($0000-$3FFF)
            jsr BankSelect

            lda #$15            ; Screen RAM at $0400 (bits 7-4 = 1) 
                                ; Charset ROM at $1000 (bits 3-1 = 2)
            sta $D018

            jsr HGROff          ; Turn off bitmap mode ($D011 bit 5 = 0)
            jmp CLEARSCREEN     ; Clear the text buffer
         
SwitchToHGR
            lda #$02
            jsr BankSelect

            lda #$00            ; Screen Ram
            ldy #$01            ; Bitmap
            jsr SetVICSlots

            jsr HGRInit
            jsr HGROn
            
            lda BITMAPBASE
            sta BITMAP_SAVE
            lda BITMAPBASE + 1
            sta BITMAP_SAVE + 1
            
            lda COLORBASE
            sta COLOR_SAVE
            lda COLORBASE + 1
            sta COLOR_SAVE + 1
 
DrawInfo        
            lda #COLOR_BLUE
            sta SCREENC
            sta Border

            ldx #0
            ldy #0
            clc
            jsr PLOT
            lda #<@BNR_COLOR
            ldy #>@BNR_COLOR
            jsr SAFE_STROUT
            lda #<@BANNER
            ldy #>@BANNER
            jsr SAFE_STROUT

            lda #2
            sta @ROW

            ; ************************************
            ;   X
            ; ************************************

            ; label
            ldx @ROW
            ldy #0
            clc
            jsr PLOT
            
            lda #<@LBL_COLOR
            ldy #>@LBL_COLOR
            jsr SAFE_STROUT
            lda #<@X_MSG
            ldy #>@X_MSG
            jsr SAFE_STROUT
            
            ;  Rotation
            ldx @ROW
            ldy #ROT_COL
            clc
            jsr PLOT
            
            lda #<@ROT_COLOR
            ldy #>@ROT_COLOR
            jsr SAFE_STROUT
            lda ROT_X_ANGLE
            sta TEMP16
            lda #0
            sta TEMP16 + 1
            jsr PRINT_INT16
                   
            ; Scale
            ldx @ROW
            ldy #SCALE_COL
            clc
            jsr PLOT
                        
            lda #<@SCALE_COLOR
            ldy #>@SCALE_COLOR
            jsr SAFE_STROUT
            lda #<SCALE_X
            sta FIXPTR
            lda #>SCALE_X
            sta FIXPTR + 1
            jsr PRINT_FIX16
           
            ; Translate
            ldx @ROW
            ldy #TRANS_COL
            clc
            jsr PLOT
            
            lda #<@TRANS_COLOR
            ldy #>@TRANS_COLOR
            jsr SAFE_STROUT
            lda #<TRANS_X
            sta FIXPTR
            lda #>TRANS_X
            sta FIXPTR + 1
            jsr PRINT_FIX16

            ; ************************************
            ;   Y
            ; ************************************
            inc @ROW
            ldx @ROW
            ldy #0
            clc
            jsr PLOT

            lda #<@LBL_COLOR
            ldy #>@LBL_COLOR
            jsr SAFE_STROUT
            lda #<@Y_MSG
            ldy #>@Y_MSG
            jsr SAFE_STROUT
            
            ;  Rotation
            ldx @ROW
            ldy #ROT_COL
            clc
            jsr PLOT
            
            lda #<@ROT_COLOR
            ldy #>@ROT_COLOR
            jsr SAFE_STROUT
            lda ROT_Y_ANGLE
            sta TEMP16
            lda #0
            sta TEMP16 + 1
            jsr PRINT_INT16
                   
            ; Scale
            ldx @ROW
            ldy #SCALE_COL
            clc
            jsr PLOT
            
            lda #<@SCALE_COLOR
            ldy #>@SCALE_COLOR
            jsr SAFE_STROUT
            lda #<SCALE_Y
            sta FIXPTR
            lda #>SCALE_Y
            sta FIXPTR + 1
            jsr PRINT_FIX16
           
            ; Translate
            ldx @ROW
            ldy #TRANS_COL
            clc
            jsr PLOT
            
            lda #<@TRANS_COLOR
            ldy #>@TRANS_COLOR
            jsr SAFE_STROUT
            lda #<TRANS_Y
            sta FIXPTR
            lda #>TRANS_Y
            sta FIXPTR + 1
            jsr PRINT_FIX16

            ; ************************************
            ;   Z
            ; ************************************
            inc @ROW
            ldx @ROW
            ldy #0
            clc
            jsr PLOT
            
            lda #<@LBL_COLOR
            ldy #>@LBL_COLOR
            jsr SAFE_STROUT
            lda #<@Z_MSG
            ldy #>@Z_MSG
            jsr SAFE_STROUT
            
            ;  Rotation
            ldx @ROW
            ldy #ROT_COL
            clc
            jsr PLOT
            
            lda #<@ROT_COLOR
            ldy #>@ROT_COLOR
            jsr SAFE_STROUT
            lda ROT_Z_ANGLE
            sta TEMP16
            lda #0
            sta TEMP16 + 1
            jsr PRINT_INT16
                   
            ; Scale
            ldx @ROW
            ldy #SCALE_COL
            clc
            jsr PLOT
            
            lda #<@SCALE_COLOR
            ldy #>@SCALE_COLOR
            jsr SAFE_STROUT
            lda #<SCALE_Z
            sta FIXPTR
            lda #>SCALE_Z
            sta FIXPTR + 1
            jsr PRINT_FIX16
           
            ; Translate
            ldx @ROW
            ldy #TRANS_COL
            clc            
            jsr PLOT
            
            lda #<@TRANS_COLOR
            ldy #>@TRANS_COLOR
            jsr SAFE_STROUT
            lda #<TRANS_Z
            sta FIXPTR
            lda #>TRANS_Z
            sta FIXPTR + 1
            jsr PRINT_FIX16

            ; ************************************
            ;   MISC
            ; ************************************
            inc @ROW
            inc @ROW
            ldx @ROW
            ldy #0
            clc
            jsr PLOT
            lda #<@LBL_COLOR
            ldy #>@LBL_COLOR
            jsr SAFE_STROUT
            
            lda #<@ROT_DELTA_MSG
            ldy #>@ROT_DELTA_MSG
            jsr SAFE_STROUT

            ldx @ROW
            ldy #MISC_COL
            clc
            jsr PLOT
 
            lda #<@ROT_DELTA_COLOR
            ldy #>@ROT_DELTA_COLOR
            jsr SAFE_STROUT
            lda #<ROT_DELTA
            sta TEMP16
            lda #0
            sta TEMP16 + 1
            jsr PRINT_INT16

            inc @ROW
            ldx @ROW
            ldy #0
            clc
            jsr PLOT
            lda #<@LBL_COLOR
            ldy #>@LBL_COLOR
            jsr SAFE_STROUT
            
            lda #<@SCALE_DELTA_MSG
            ldy #>@SCALE_DELTA_MSG
            jsr SAFE_STROUT

            ldx @ROW
            ldy #MISC_COL
            clc
            jsr PLOT
            lda #<@SCALE_DELTA_COLOR
            ldy #>@SCALE_DELTA_COLOR
            jsr SAFE_STROUT
            lda #<SCALE_INCREMENT
            sta FIXPTR
            lda #>SCALE_INCREMENT
            sta FIXPTR + 1
            jsr PRINT_FIX16


            inc @ROW
            ldx @ROW
            ldy #0
            clc
            jsr PLOT
            lda #<@LBL_COLOR
            ldy #>@LBL_COLOR
            jsr SAFE_STROUT
            
            lda #<@TRANS_DELTA_MSG
            ldy #>@TRANS_DELTA_MSG
            jsr SAFE_STROUT

            ldx @ROW
            ldy #MISC_COL
            clc
            jsr PLOT
            lda #<@TRAN_DELTA_COLOR
            ldy #>@TRAN_DELTA_COLOR
            jsr SAFE_STROUT
            lda #<TRANS_INCREMENT
            sta FIXPTR
            lda #>TRANS_INCREMENT
            sta FIXPTR + 1
            jsr PRINT_FIX16

            inc @ROW
            ldx @ROW
            ldy #0
            clc
            jsr PLOT
            lda #<@LBL_COLOR
            ldy #>@LBL_COLOR
            jsr SAFE_STROUT
            
            lda #<@BITMAP_MSG
            ldy #>@BITMAP_MSG
            jsr SAFE_STROUT

            ldx @ROW
            ldy #MISC_COL
            clc
            jsr PLOT
            lda #<@BITMAP_BASE_COLOR
            ldy #>@BITMAP_BASE_COLOR
            jsr SAFE_STROUT
            lda BITMAP_SAVE
            sta TEMP16
            lda BITMAP_SAVE + 1
            sta TEMP16 + 1
            jsr PRINT_INT16_HEX

            inc @ROW
            ldx @ROW
            ldy #0
            clc
            jsr PLOT
            lda #<@LBL_COLOR
            ldy #>@LBL_COLOR
            jsr SAFE_STROUT
            
            lda #<@COLOR_MSG
            ldy #>@COLOR_MSG
            jsr SAFE_STROUT

            ldx @ROW
            ldy #MISC_COL
            clc
            jsr PLOT
            lda #<@COLOR_BASE_COLOR
            ldy #>@COLOR_BASE_COLOR
            jsr SAFE_STROUT
            lda COLOR_SAVE
            sta TEMP16
            lda COLOR_SAVE + 1
            sta TEMP16 + 1
            jsr PRINT_INT16_HEX
            rts

;                               0123456789012345678901234567890123456789
@BANNER                 .byte   "   ROT  SCALE     TRANSLATE",0
@X_MSG                  .byte "X",0
@Y_MSG                  .byte "Y",0
@Z_MSG                  .byte "Z",0
@ROT_DELTA_MSG          .byte "ROT    DELTA   ",0
@SCALE_DELTA_MSG        .byte "SCALE  DELTA ",0
@TRANS_DELTA_MSG        .byte "TRANS  DELTA ",0
@BITMAP_MSG             .byte "BITMAP BASE",0
@COLOR_MSG              .byte "COLOR  BASE",0
@BNR_COLOR              .byte KEY_WHITE, 0
@LBL_COLOR              .byte KEY_LT_GRAY, 0
@ROT_COLOR              .byte KEY_YELLOW, 0
@SCALE_COLOR            .byte KEY_YELLOW, 0
@TRANS_COLOR            .byte KEY_YELLOW, 0
@ROT_DELTA_COLOR        .byte KEY_YELLOW, 0
@TRAN_DELTA_COLOR       .byte KEY_YELLOW, 0
@SCALE_DELTA_COLOR      .byte KEY_YELLOW, 0
@BITMAP_BASE_COLOR      .byte KEY_YELLOW, 0
@COLOR_BASE_COLOR       .byte KEY_YELLOW, 0
@ROW                    .byte 0
