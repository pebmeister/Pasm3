
            ; ************************************
            ;
            ; DrawInfo
            ;
            ; ************************************
DrawInfo:
            ROT_COL = 3
            SCALE_COL = 8
            TRANS_COL = 18
            MISC_COL = 16

            lda     #COLOR_BLUE
            sta     Border
            sta     SCREENC

            lda     #<@PG_INFO
            sta     TXPTR
            lda     #>@PG_INFO
            sta     TXPTR + 1
            jsr     DisplayPage
            rts
@PG_INFO:
            .byte   STRING, 147, 0
            .byte   SETPOS, 0, 0
            .byte   STRING, KEY_WHITE, "   ROT  SCALE     TRANSLATE", 0

            ; X Data 
            .byte   SETPOS, 2, 0
            .byte   STRING, KEY_LT_GRAY, "X", 0
            .byte   SETPOS, 2, ROT_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT8
            .word   ROT_X_ANGLE
            .byte   SETPOS, 2, SCALE_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   SCALE_X
            .byte   SETPOS, 2, TRANS_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   TRANS_X

            ; Y Data
            .byte   SETPOS, 3, 0
            .byte   STRING, KEY_LT_GRAY, "Y", 0
            .byte   SETPOS, 3, ROT_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT8
            .word   ROT_Y_ANGLE
            .byte   SETPOS, 3, SCALE_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   SCALE_Y
            .byte   SETPOS, 3, TRANS_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   TRANS_Y

            ; Z Data
            .byte   SETPOS, 4, 0
            .byte   STRING, KEY_LT_GRAY, "Z", 0
            .byte   SETPOS, 4, ROT_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT8
            .word   ROT_Z_ANGLE
            .byte   SETPOS, 4, SCALE_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   SCALE_Z
            .byte   SETPOS, 4, TRANS_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   TRANS_Z

            ; Misc
            .byte   SETPOS, 6, 0
            .byte   STRING, KEY_LT_GRAY, "ROT    DELTA   ",0
            .byte   SETPOS, 6, MISC_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT8_I, ROT_DELTA

            .byte   SETPOS, 7, 0
            .byte   STRING, KEY_LT_GRAY, "SCALE  DELTA ",0
            .byte   SETPOS, 7, MISC_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   SCALE_INCREMENT

            .byte   SETPOS, 8, 0
            .byte   STRING, KEY_LT_GRAY, "TRANS  DELTA ",0
            .byte   SETPOS, 8, MISC_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   TRANS_INCREMENT

            .byte   SETPOS, 10, 0
            .byte   STRING, KEY_LT_GRAY, "BITMAPBASE",0
            .byte   SETPOS, 10, MISC_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT16_HEX
            .word   BITMAPBASE

            .byte   SETPOS, 11, 0
            .byte   STRING, KEY_LT_GRAY, "COLORBASE",0
            .byte   SETPOS, 11, MISC_COL
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT16_HEX
            .word   COLORBASE

            .byte   ENDPAGE

DrawDebugInfo:
            lda     #COLOR_RED
            sta     Border
            sta     SCREENC

            lda     #<@PG_DEBUG
            sta     TXPTR
            lda     #>@PG_DEBUG
            sta     TXPTR + 1
            jsr     DisplayPage
            rts

@PG_DEBUG:
            .byte   STRING, 147, 0
            .byte   SETPOS, 0, 0
            .byte   STRING, KEY_WHITE, "ORGINAL VERTICES", 0
            .byte   SETPOS, 1, 0
            .byte   STRING, KEY_LT_GRAY, "X            Y            Z", 0
            .byte   SETPOS, 3, 0
            .byte   STRING, KEY_YELLOW, 0
            .byte   VRT_PTR_ARRAY
            .word   MODEL_VERTEX_COUNT
            .byte   0, 13, 26
            .word   MODEL_VERTICES_PTR

            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "WORLD VERTICES", 0
            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "X            Y            Z", 0
            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_YELLOW, 0
            .byte   VRT_ARRAY
            .word   MODEL_VERTEX_COUNT
            .byte   0, 13, 26
            .word   WORLD_VERTICES

            .byte   ENDPAGE

DrawCullInfo:
            lda     #COLOR_YELLOW
            sta     Border
            sta     SCREENC

            lda     #<@PG_CULL_DEBUG
            sta     TXPTR
            lda     #>@PG_CULL_DEBUG
            sta     TXPTR + 1
            jsr     DisplayPage
            rts

@PG_CULL_DEBUG:

            .byte   STRING, 147, 0
            .byte   SETPOS, 0, 0
            .byte   STRING, KEY_BLUE, "FACE VISABLE", 0

            .byte   SETPOS, 1, 0
            .byte   STRING, KEY_BLACK, "0) ", 0
            .byte   STRING, KEY_BLUE, 0
            .byte   INT8
            .word CUBE_VISIBLE + 0

 
            .byte   SETPOS, 2, 0
            .byte   STRING, KEY_BLACK, "1) ", 0
            .byte   STRING, KEY_BLUE, 0
            .byte   INT8
            .word   CUBE_VISIBLE + 1
            
            .byte   SETPOS, 3, 0
            .byte   STRING, KEY_BLACK, "2) ", 0
            .byte   STRING, KEY_BLUE, 0
            .byte   INT8
            .word   CUBE_VISIBLE + 2

            .byte   SETPOS, 4, 0
            .byte   STRING, KEY_BLACK, "3) ", 0
            .byte   STRING, KEY_BLUE, 0
            .byte   INT8
            .word   CUBE_VISIBLE + 3

            .byte   SETPOS, 5, 0
            .byte   STRING, KEY_BLACK, "4) ", 0
            .byte   STRING, KEY_BLUE, 0
            .byte   INT8,
            .word   CUBE_VISIBLE + 4

            .byte   SETPOS, 6, 0
            .byte   STRING, KEY_BLACK, "5) ", 0
            .byte   STRING, KEY_BLUE, 0
            .byte   INT8
            .word   CUBE_VISIBLE + 5

            .byte   ENDPAGE
