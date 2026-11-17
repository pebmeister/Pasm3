            ROT_COL = 3
            SCALE_COL = 8
            TRANS_COL = 18
            MISC_COL = 16

            ; ************************************
            ;
            ; DrawInfo
            ;
            ; ************************************
DrawInfo:
            lda     #COLOR_BLUE
            sta     Border
            sta     SCREENC


            ; move pointer to PR_BANNER
            lda     #< @PR_BANNER
            sta     LOC
            lda     #> @PR_BANNER
            sta     LOC + 1

            ; stor Banner location at PR_BANNER
            lda     #< @BANNER
            ldy     #0
            sta     (LOC), y
            INC16   LOC
            lda     #> @BANNER
            sta     (LOC), y 

            lda     #<@PG_PROG
            sta     TXPTR
            lda     #>@PG_PROG
            sta     TXPTR + 1
            jsr     DisplayPage
            
            rts
            

@PG_PROG
            .byte SETROW, 0
            .byte SETCOL, 0
            .byte UPDATEPOS            
            .byte PR_STRING
@PR_BANNER
            .word 0
            .byte ENDPAGE
            
            
            ldx     #0
            ldy     #0
            clc
            jsr     PLOT
            lda     #<@BNR_COLOR
            ldy     #>@BNR_COLOR
            jsr     SAFE_STROUT
            lda     #<@BANNER
            ldy     #>@BANNER
            jsr     SAFE_STROUT

            lda     #2
            sta     @ROW

            ; ************************************
            ;   X
            ; ************************************

            ; label
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT

            lda     #<@LBL_COLOR
            ldy     #>@LBL_COLOR
            jsr     SAFE_STROUT
            lda     #<@X_MSG
            ldy     #>@X_MSG
            jsr     SAFE_STROUT

            ;  Rotation
            ldx     @ROW
            ldy     #ROT_COL
            clc
            jsr     PLOT

            lda     #<@ROT_COLOR
            ldy     #>@ROT_COLOR
            jsr     SAFE_STROUT
            lda     ROT_X_ANGLE
            sta     TEMP16
            lda     #0
            sta     TEMP16 + 1
            jsr     PRINT_INT16

            ; Scale
            ldx     @ROW
            ldy     #SCALE_COL
            clc
            jsr     PLOT

            lda     #<@SCALE_COLOR
            ldy     #>@SCALE_COLOR
            jsr     SAFE_STROUT

            lda     #<SCALE_X
            sta     FIXPTR
            lda     #>SCALE_X
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            ; Translate
            ldx     @ROW
            ldy     #TRANS_COL
            clc
            jsr     PLOT

            lda     #<@TRANS_COLOR
            ldy     #>@TRANS_COLOR
            jsr     SAFE_STROUT
            lda     #<TRANS_X
            sta     FIXPTR
            lda     #>TRANS_X
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            ; ************************************
            ;   Y
            ; ************************************
            inc     @ROW
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT

            lda     #<@LBL_COLOR
            ldy     #>@LBL_COLOR
            jsr     SAFE_STROUT
            lda     #<@Y_MSG
            ldy     #>@Y_MSG
            jsr     SAFE_STROUT

            ;  Rotation
            ldx     @ROW
            ldy     #ROT_COL
            clc
            jsr     PLOT

            lda     #<@ROT_COLOR
            ldy     #>@ROT_COLOR
            jsr     SAFE_STROUT
            lda     ROT_Y_ANGLE
            sta     TEMP16
            lda     #0
            sta     TEMP16 + 1
            jsr     PRINT_INT16

            ; Scale
            ldx     @ROW
            ldy     #SCALE_COL
            clc
            jsr     PLOT

            lda     #<@SCALE_COLOR
            ldy     #>@SCALE_COLOR
            jsr     SAFE_STROUT
            lda     #<SCALE_Y
            sta     FIXPTR
            lda     #>SCALE_Y
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            ; Translate
            ldx     @ROW
            ldy     #TRANS_COL
            clc
            jsr     PLOT

            lda     #<@TRANS_COLOR
            ldy     #>@TRANS_COLOR
            jsr     SAFE_STROUT
            lda     #<TRANS_Y
            sta     FIXPTR
            lda     #>TRANS_Y
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            ; ************************************
            ;   Z
            ; ************************************
            inc     @ROW
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT

            lda     #<@LBL_COLOR
            ldy     #>@LBL_COLOR
            jsr     SAFE_STROUT
            lda     #<@Z_MSG
            ldy     #>@Z_MSG
            jsr     SAFE_STROUT

            ;  Rotation
            ldx     @ROW
            ldy     #ROT_COL
            clc
            jsr     PLOT

            lda     #<@ROT_COLOR
            ldy     #>@ROT_COLOR
            jsr     SAFE_STROUT
            lda     ROT_Z_ANGLE
            sta     TEMP16
            lda     #0
            sta     TEMP16 + 1
            jsr     PRINT_INT16

            ; Scale
            ldx     @ROW
            ldy     #SCALE_COL
            clc
            jsr     PLOT

            lda     #<@SCALE_COLOR
            ldy     #>@SCALE_COLOR
            jsr     SAFE_STROUT
            lda     #<SCALE_Z
            sta     FIXPTR
            lda     #>SCALE_Z
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            ; Translate
            ldx     @ROW
            ldy     #TRANS_COL
            clc
            jsr     PLOT

            lda     #<@TRANS_COLOR
            ldy     #>@TRANS_COLOR
            jsr     SAFE_STROUT
            lda     #<TRANS_Z
            sta     FIXPTR
            lda     #>TRANS_Z
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            ; ************************************
            ;   MISC
            ; ************************************
            inc     @ROW
            inc     @ROW
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT
            lda     #<@LBL_COLOR
            ldy     #>@LBL_COLOR
            jsr     SAFE_STROUT

            lda     #<@ROT_DELTA_MSG
            ldy     #>@ROT_DELTA_MSG
            jsr     SAFE_STROUT

            ldx     @ROW
            ldy     #MISC_COL
            clc
            jsr     PLOT

            lda     #<@ROT_DELTA_COLOR
            ldy     #>@ROT_DELTA_COLOR
            jsr     SAFE_STROUT
            lda     #<ROT_DELTA
            sta     TEMP16
            lda     #0
            sta     TEMP16 + 1
            jsr     PRINT_INT16

            inc     @ROW
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT
            lda     #<@LBL_COLOR
            ldy     #>@LBL_COLOR
            jsr     SAFE_STROUT

            lda     #<@SCALE_DELTA_MSG
            ldy     #>@SCALE_DELTA_MSG
            jsr     SAFE_STROUT

            ldx     @ROW
            ldy     #MISC_COL
            clc
            jsr     PLOT
            lda     #<@SCALE_DELTA_COLOR
            ldy     #>@SCALE_DELTA_COLOR
            jsr     SAFE_STROUT
            lda     #<SCALE_INCREMENT
            sta     FIXPTR
            lda     #>SCALE_INCREMENT
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            inc     @ROW
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT
            lda     #<@LBL_COLOR
            ldy     #>@LBL_COLOR
            jsr     SAFE_STROUT

            lda     #<@TRANS_DELTA_MSG
            ldy     #>@TRANS_DELTA_MSG
            jsr     SAFE_STROUT

            ldx     @ROW
            ldy     #MISC_COL
            clc
            jsr     PLOT
            lda     #<@TRAN_DELTA_COLOR
            ldy     #>@TRAN_DELTA_COLOR
            jsr     SAFE_STROUT
            lda     #<TRANS_INCREMENT
            sta     FIXPTR
            lda     #>TRANS_INCREMENT
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            inc     @ROW
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT
            lda     #<@LBL_COLOR
            ldy     #>@LBL_COLOR
            jsr     SAFE_STROUT

            lda     #<@BITMAP_MSG
            ldy     #>@BITMAP_MSG
            jsr     SAFE_STROUT

            ldx     @ROW
            ldy     #MISC_COL
            clc
            jsr     PLOT
            lda     #<@BITMAP_BASE_COLOR
            ldy     #>@BITMAP_BASE_COLOR
            jsr     SAFE_STROUT
            lda     BITMAPBASE
            sta     TEMP16
            lda     BITMAPBASE + 1
            sta     TEMP16 + 1
            jsr     PRINT_INT16_HEX

            inc     @ROW
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT
            lda     #<@LBL_COLOR
            ldy     #>@LBL_COLOR
            jsr     SAFE_STROUT

            lda     #<@COLOR_MSG
            ldy     #>@COLOR_MSG
            jsr     SAFE_STROUT

            ldx     @ROW
            ldy     #MISC_COL
            clc
            jsr     PLOT
            lda     #<@COLOR_BASE_COLOR
            ldy     #>@COLOR_BASE_COLOR
            jsr     SAFE_STROUT
            lda     COLORBASE
            sta     TEMP16
            lda     COLORBASE + 1
            sta     TEMP16 + 1
            jsr     PRINT_INT16_HEX
            rts

;                               0123456789012345678901234567890123456789
@BANNER:
            .byte   "   ROT  SCALE     TRANSLATE",0
@X_MSG:
            .byte   "X",0
@Y_MSG:
            .byte   "Y",0
@Z_MSG:
            .byte   "Z",0
@ROT_DELTA_MSG:
            .byte   "ROT    DELTA   ",0
@SCALE_DELTA_MSG:
            .byte   "SCALE  DELTA ",0
@TRANS_DELTA_MSG:
            .byte   "TRANS  DELTA ",0
@BITMAP_MSG:
            .byte   "BITMAPBASE",0
@COLOR_MSG:
            .byte   "COLORBASE",0
@BNR_COLOR:
            .byte   KEY_WHITE, 0
@LBL_COLOR:
            .byte   KEY_LT_GRAY, 0
@ROT_COLOR:
            .byte   KEY_YELLOW, 0
@SCALE_COLOR:
            .byte   KEY_YELLOW, 0
@TRANS_COLOR:
            .byte   KEY_YELLOW, 0
@ROT_DELTA_COLOR:
            .byte   KEY_YELLOW, 0
@TRAN_DELTA_COLOR:
            .byte   KEY_YELLOW, 0
@SCALE_DELTA_COLOR:
            .byte   KEY_YELLOW, 0
@BITMAP_BASE_COLOR:
            .byte   KEY_YELLOW, 0
@COLOR_BASE_COLOR:
            .byte   KEY_YELLOW, 0
@ROW:
            .byte   0

DrawDebugInfo:

            lda     #COLOR_RED
            sta     Border
            sta     SCREENC

            lda     MODEL_VERTICES_PTR
            sta     @VERT_PTR
            lda     MODEL_VERTICES_PTR + 1
            sta     @VERT_PTR + 1

            ; Print header at row 0
            ldx     #0                  ; Row
            ldy     #0                  ; Col
            sec
            jsr     PLOT

            lda     #<@DGB_HDR
            ldy     #>@DGB_HDR
            jsr     SAFE_STROUT

            lda     #1                  ; First data row (row 0 is header)
            sta     @ROW
            jsr     @PrintVertex

            lda     #<WORLD_VERTICES
            sta     @VERT_PTR
            lda     #>WORLD_VERTICES
            sta     @VERT_PTR + 1

            inc     @ROW
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT

            lda     #<@WORLD_HDR
            ldy     #>@WORLD_HDR
            jsr     SAFE_STROUT

            lda     MODEL_VERTICES_PTR
            sta     TEMP16
            lda     MODEL_VERTICES_PTR + 1
            sta     TEMP16 + 1
            jsr     PRINT_INT16_HEX

            inc     @ROW
            inc     @ROW
            jsr     @PrintVertex

            rts

@PrintVertex:
            ; Initialize counters
            lda     #0
            sta     @INDEX

@VertLoop:
            ; Have we printed all vertices?
            lda     @INDEX
            cmp     MODEL_VERTEX_COUNT
            bcs     @Done

            ;------------------------------------
            ; X coordinate - column 0
            ;------------------------------------
            ldx     @ROW
            ldy     #0
            clc
            jsr     PLOT

            lda     @VERT_PTR
            sta     FIXPTR
            lda     @VERT_PTR + 1
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            ; Advance pointer to Y (+4)
            clc
            lda     @VERT_PTR
            adc     #4
            sta     @VERT_PTR
            bcc     @NoCarryY
            inc     @VERT_PTR + 1
@NoCarryY:

            ;------------------------------------
            ; Y coordinate - column 13
            ;------------------------------------
            ldx     @ROW
            ldy     #13
            clc
            jsr     PLOT

            lda     @VERT_PTR
            sta     FIXPTR
            lda     @VERT_PTR + 1
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            ; Advance pointer to Z (+4)
            clc
            lda     @VERT_PTR
            adc     #4
            sta     @VERT_PTR
            bcc     @NoCarryZ
            inc     @VERT_PTR + 1
@NoCarryZ:

            ;------------------------------------
            ; Z coordinate - column 26
            ;------------------------------------
            ldx     @ROW
            ldy     #26
            clc
            jsr     PLOT

            lda     @VERT_PTR
            sta     FIXPTR
            lda     @VERT_PTR + 1
            sta     FIXPTR + 1
            jsr     PRINT_FIX16

            ; Advance pointer past W to next vertex (+8)
            clc
            lda     @VERT_PTR
            adc     #8
            sta     @VERT_PTR
            bcc     @NoCarryNext
            inc     @VERT_PTR + 1
@NoCarryNext:

            ; Advance counters
            inc     @INDEX
            inc     @ROW

            jmp     @VertLoop

@Done:
            rts

;--------------------------------------------
; Debug workspace
;--------------------------------------------
@VERT_PTR:
            .ds     2
@INDEX:
            .ds     1
@ROW:
            .ds     1

@WORLD_HDR:
            .byte   KEY_YELLOW, "WORLD VERTICES  ", KEY_WHITE, 0
@DGB_HDR:
            .byte   KEY_WHITE, "X            Y            Z", 0
