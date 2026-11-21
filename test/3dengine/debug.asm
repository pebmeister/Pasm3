            ; ************************************
            ;
            ; DrawInfo
            ;
            ; ************************************
DrawInfo:
            MOVE16I TXPTR, @PG_INFO
            jmp     DisplayPage
@PG_INFO:
            .byte   BRD_C, COLOR_BLUE
            .byte   SCR_C, COLOR_BLUE
            .byte   CLS
            .byte   SETPOS, 0, 0
            .byte   STRING, KEY_WHITE, "   ROT  SCALE     TRANSLATE", 0
            .byte   NEXTROW

            ; X Data 
            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "X", 0
            .byte   TAB, 3
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT8
            .word   ROT_X_ANGLE
            .byte   TAB, 8
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   SCALE_X
            .byte   TAB, 18
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   TRANS_X

            ; Y Data
            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "Y", 0
            .byte   TAB, 3
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT8
            .word   ROT_Y_ANGLE
            .byte   TAB, 8
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   SCALE_Y
            .byte   TAB, 18
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   TRANS_Y

            ; Z Data
            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "Z", 0
            .byte   TAB, 3
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT8
            .word   ROT_Z_ANGLE
            .byte   TAB, 8
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   SCALE_Z
            .byte   TAB, 18
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   TRANS_Z

            ; Misc
            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "ROT    DELTA   ",0
            .byte   TAB, 16
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT8_I, ROT_DELTA

            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "SCALE  DELTA ",0
            .byte   TAB, 16
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   SCALE_INCREMENT

            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "TRANS  DELTA ",0
            .byte   TAB, 16
            .byte   STRING, KEY_YELLOW, 0
            .byte   FIX16
            .word   TRANS_INCREMENT

            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "BITMAPBASE",0
            .byte   TAB, 16
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT16_HEX
            .word   BITMAPBASE

            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "COLORBASE",0
            .byte   TAB, 16
            .byte   STRING, KEY_YELLOW, 0
            .byte   INT16_HEX
            .word   COLORBASE

            .byte   ENDPAGE

DrawDebugInfo:
            MOVE16I TXPTR, @PG_DEBUG
            jmp     DisplayPage

@PG_DEBUG:
            .byte   BRD_C, COLOR_RED
            .byte   SCR_C, COLOR_RED
            .byte   CLS
            .byte   SETPOS, 0, 0
            .byte   STRING, KEY_WHITE, "ORGINAL VERTICES", 0
            .byte   SETPOS, 1, 0
            .byte   STRING, KEY_LT_GRAY, "X        Y        Z        W", 0
            .byte   SETPOS, 3, 0
            .byte   STRING, KEY_YELLOW, 0
            .byte   VRT_PTR_ARRAY
            .word   MODEL_VERTEX_COUNT
            .byte   0, 9, 18, 27
            .word   MODEL_VERTICES_PTR

            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "WORLD VERTICES", 0
            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "X        Y        Z        W", 0
            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_YELLOW, 0
            .byte   VRT_ARRAY
            .word   MODEL_VERTEX_COUNT
            .byte   0, 9, 18, 27
            .word   WORLD_VERTICES

            .byte   ENDPAGE

DrawCullInfo:

            MOVE16I TXPTR, @PG_CULL_DEBUG
            jmp     DisplayPage

            SHOW_FACE_VISABLE = 1
            SHOW_FACE_CROSS_RESULTS = 1
            SHOW_SCREEN_VERTICES = 1

@PG_CULL_DEBUG:
            .byte   BRD_C, COLOR_WHITE
            .byte   SCR_C, COLOR_WHITE
            .byte   CLS

            .ifdef  SHOW_FACE_VISABLE
            .byte   STRING, KEY_RED, "FACE VISABLE", 0

            .byte   NEXTROW
            .byte   STRING, KEY_BLACK, 0

            .byte   INT8
            .word   CUBE_VISIBLE + 0
            .byte   INT8
            .word   CUBE_VISIBLE + 1
            .byte   INT8
            .word   CUBE_VISIBLE + 2
            .byte   INT8
            .word   CUBE_VISIBLE + 3
            .byte   INT8,
            .word   CUBE_VISIBLE + 4
            .byte   INT8
            .word   CUBE_VISIBLE + 5
            .endif

            .ifdef  SHOW_FACE_CROSS_RESULTS
            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_RED, "FACE CROSS RESULTS", 0
            .byte   NEXTROW
            .byte   STRING, KEY_BLACK, 0

            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 0
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 2
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 4
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 6
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 8
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 10
            .byte   NEXTROW

            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 12
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 14
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 16
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 18
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 20
            .byte   SPC
            .byte   INT16_HEX
            .word   FACE_CROSS_RESULTS + 22

            .byte   NEXTROW
            .byte   NEXTROW
            .endif

            .ifdef  SHOW_SCREEN_VERTICES
            .byte   STRING, KEY_RED, "SCREEN VERTICES", 0
            .byte   NEXTROW
            .byte   STRING, KEY_BLACK, 0

            .byte   INT16
            .word   SCREEN_VERTICES + 0
            .byte   SPC
            .byte   INT8
            .word   SCREEN_VERTICES + 2
            .byte   NEXTROW

            .byte   INT16
            .word   SCREEN_VERTICES + 3
            .byte   SPC
            .byte   INT8
            .word   SCREEN_VERTICES + 5
            .byte   NEXTROW

            .byte   INT16
            .word   SCREEN_VERTICES + 6
            .byte   SPC
            .byte   INT8
            .word   SCREEN_VERTICES + 8
            .byte   NEXTROW

            .byte   INT16
            .word   SCREEN_VERTICES + 9
            .byte   SPC
            .byte   INT8
            .word   SCREEN_VERTICES + 11
            .byte   NEXTROW

            .byte   INT16
            .word   SCREEN_VERTICES + 12
            .byte   SPC
            .byte   INT8
            .word   SCREEN_VERTICES + 14
            .byte   NEXTROW

            .byte   INT16
            .word   SCREEN_VERTICES + 15
            .byte   SPC
            .byte   INT8
            .word   SCREEN_VERTICES + 17
            .byte   NEXTROW

            .byte   INT16
            .word   SCREEN_VERTICES + 18
            .byte   SPC
            .byte   INT8
            .word   SCREEN_VERTICES + 20
            .byte   NEXTROW

            .byte   INT16
            .word   SCREEN_VERTICES + 21
            .byte   SPC
            .byte   INT8
            .word   SCREEN_VERTICES + 23
            .byte   NEXTROW

            .endif
            .ifdef  NDC_VERTICES

            .byte   STRING, KEY_RED, "NDC VERTICES", 0
            .byte   NEXTROW
            .byte   STRING, KEY_LT_GRAY, "X        Y        Z        W", 0
            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_BLACK, 0
            .byte   VRT_ARRAY
            .word   MODEL_VERTEX_COUNT
            .byte   0, 9, 18, 27
            .word   NDC_VERTICES
            .endif
            .byte   ENDPAGE

DrawEdgeInfo:
            jsr     BuildModel

            lda     #0
            sta     FACE_INDEX

            jsr     LOAD_FACE_VERTICES
            jsr     FIND_FACE_TOP_BOTTOM
            jsr     FIND_FACE_EDGE_PATHS
            jsr     INIT_FACE_EDGE_WALKERS
            jsr     TEST_EDGE_B_TRANSITION

            MOVE16I TXPTR, @PG_EDGE_INFO
            jmp     DisplayPage

@PG_EDGE_INFO:
            .byte   BRD_C, COLOR_BLUE
            .byte   SCR_C, COLOR_BLUE
            .byte   CLS
            .byte   SETPOS, 0, 0
            .byte   STRING, KEY_WHITE, "FACE VERTEX LIST", 0

            .byte   TAB, 25
            .byte   INT8_HEX
            .word   FACE_VERTEX_LIST + 0
            .byte   SPC
            .byte   INT8_HEX
            .word   FACE_VERTEX_LIST + 1
            .byte   SPC
            .byte   INT8_HEX
            .word   FACE_VERTEX_LIST + 2
            .byte   SPC
            .byte   INT8_HEX
            .word   FACE_VERTEX_LIST + 3

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "FACE VERTEX Y LIST", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   FACE_VERTEX_Y_LIST + 0
            .byte   SPC
            .byte   INT8_HEX
            .word   FACE_VERTEX_Y_LIST + 1
            .byte   SPC
            .byte   INT8_HEX
            .word   FACE_VERTEX_Y_LIST + 2
            .byte   SPC
            .byte   INT8_HEX
            .word   FACE_VERTEX_Y_LIST + 3

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "FACE TOP POSITION", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   FACE_TOP_POSITION

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "FACE BOTTOM POSITION", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   FACE_BOTTOM_POSITION

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "FACE TOP Y", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   FACE_TOP_Y

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "FACE SCAN Y", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   FACE_SCAN_Y

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EDGE A START POSITION", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   EDGE_A_START_POSITION

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EDGE B START POSITION", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   EDGE_B_START_POSITION

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EDGE A X", 0
            .byte   TAB, 25
            .byte   INT16_HEX
            .word   EDGE_A_X + 2

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EDGE B X", 0
            .byte   TAB, 25
            .byte   INT16_HEX
            .word   EDGE_B_X + 2

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EDGE A SLOPE", 0
            .byte   TAB, 25
            .byte   FIX16
            .word   EDGE_A_SLOPE

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EDGE B SLOPE", 0
            .byte   TAB, 25
            .byte   FIX16
            .word   EDGE_B_SLOPE

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EDGE A END POSITION", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   EDGE_A_END_POSITION

            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EDGE B END POSITION", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   EDGE_B_END_POSITION

SHOW_EDGES = 1
.ifdef SHOW_EDGES
            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EDGE X0", 0
            .byte   TAB, 25
            .byte   INT16_HEX
            .word   EDGE_X0
            .byte   NEXTROW

            .byte   STRING, KEY_WHITE, "EDGE Y0", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   EDGE_Y0
            .byte   NEXTROW

            .byte   STRING, KEY_WHITE, "EDGE X1", 0
            .byte   TAB, 25
            .byte   INT16_HEX
            .word   EDGE_X1
            .byte   NEXTROW

            .byte   STRING, KEY_WHITE, "EDGE Y1", 0
            .byte   TAB, 25
            .byte   INT8_HEX
            .word   EDGE_Y1
            .byte   NEXTROW
.endif
            .byte   ENDPAGE
