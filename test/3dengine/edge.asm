;********************************************
;* CALC_EDGE_SLOPE
;*
;* Calculates signed 16.16 DX / DY
;*
;* Input:
;*   EDGE_X0 = starting X (16-bit integer)
;*   EDGE_X1 = ending X   (16-bit integer)
;*   EDGE_Y0 = starting Y (8-bit integer)
;*   EDGE_Y1 = ending Y   (8-bit integer)
;*
;* Output:
;*   EDGE_SLOPE = signed 16.16 slope
;*
;* Endpoints must be ordered top to bottom.
;********************************************

CALC_EDGE_SLOPE:

            ;--------------------------------
            ; DX = X1 - X0
            ;--------------------------------
            sec
            lda     EDGE_X1
            sbc     EDGE_X0
            sta     EDGE_DX
            lda     EDGE_X1+1
            sbc     EDGE_X0+1
            sta     EDGE_DX+1

            ;--------------------------------
            ; DY = Y1 - Y0
            ;--------------------------------
            sec
            lda     EDGE_Y1
            sbc     EDGE_Y0
            sta     EDGE_DY

            ;--------------------------------
            ; Convert DX to signed 16.16
            ;--------------------------------
            lda     #0
            sta     EDGE_DIV_A
            sta     EDGE_DIV_A+1

            lda     EDGE_DX
            sta     EDGE_DIV_A+2
            lda     EDGE_DX+1
            sta     EDGE_DIV_A+3

            ;--------------------------------
            ; Convert DY to positive 16.16
            ;--------------------------------
            lda     #0
            sta     EDGE_DIV_B
            sta     EDGE_DIV_B+1
            sta     EDGE_DIV_B+3

            lda     EDGE_DY
            sta     EDGE_DIV_B+2

            ;--------------------------------
            ; Set division pointers
            ;--------------------------------
            lda     #<EDGE_DIV_A
            sta     FIX16_A_PTR
            lda     #>EDGE_DIV_A
            sta     FIX16_A_PTR+1

            lda     #<EDGE_DIV_B
            sta     FIX16_B_PTR
            lda     #>EDGE_DIV_B
            sta     FIX16_B_PTR+1

            lda     #<EDGE_SLOPE
            sta     FIX16_RESULT_PTR
            lda     #>EDGE_SLOPE
            sta     FIX16_RESULT_PTR+1

            jsr     FIX16_DIV
            rts

;********************************************
;* FIND_FACE_EDGE_PATHS
;********************************************
FIND_FACE_EDGE_PATHS:

            ; --------------------------------
            ; Path A: Walk backwards
            ; --------------------------------

            lda     FACE_TOP_POSITION
            sta     EDGE_A_START_POSITION
            sta     FACE_WALK_POSITION

@PathA:
            dec     FACE_WALK_POSITION

            lda     FACE_WALK_POSITION
            cmp     #$ff
            bne     @PathACheck

            lda     #3
            sta     FACE_WALK_POSITION

@PathACheck:
            ldx     FACE_WALK_POSITION
            lda     FACE_VERTEX_Y_LIST,x
            cmp     FACE_TOP_Y
            beq     @PathA

            lda     FACE_WALK_POSITION
            sta     EDGE_A_END_POSITION

            ; --------------------------------
            ; Path B: Walk forwards
            ; --------------------------------

            lda     FACE_TOP_POSITION
            sta     FACE_WALK_POSITION

@PathB:
            inc     FACE_WALK_POSITION

            lda     FACE_WALK_POSITION
            cmp     #4
            bne     @PathBCheck

            lda     #0
            sta     FACE_WALK_POSITION

@PathBCheck:
            ldx     FACE_WALK_POSITION
            lda     FACE_VERTEX_Y_LIST,x
            cmp     FACE_TOP_Y
            bne     @PathBFound

            ; Still on the horizontal top edge.
            lda     FACE_WALK_POSITION
            sta     EDGE_B_START_POSITION
            jmp     @PathB

@PathBFound:
            lda     FACE_WALK_POSITION
            sta     EDGE_B_END_POSITION

            rts

LOAD_EDGE_ENDPOINTS:
            ; Load starting vertex
            ldx     EDGE_START_POSITION
            lda     FACE_VERTEX_LIST,x
            sta     FACE_VERTEX_INDEX
            jsr     LoadVertex

            lda     FACE_VERTEX_X
            sta     EDGE_X0
            lda     FACE_VERTEX_X+1
            sta     EDGE_X0+1
            lda     FACE_VERTEX_Y
            sta     EDGE_Y0

            ; Load ending vertex
            ldx     EDGE_END_POSITION
            lda     FACE_VERTEX_LIST,x
            sta     FACE_VERTEX_INDEX
            jsr     LoadVertex

            lda     FACE_VERTEX_X
            sta     EDGE_X1
            lda     FACE_VERTEX_X+1
            sta     EDGE_X1+1
            lda     FACE_VERTEX_Y
            sta     EDGE_Y1
        
            jsr     @Debug

            rts
;            rts

@Border_Color   .ds 1
;;;;;;;;;;;;;;;;;;;;;;;
@Debug
            lda     Border
            sta     @Border_Color
            jsr     SwitchToText

            MOVE16I TXPTR, @PG_INFO
            jsr     DisplayPage

@Loop:
            jsr     GETIN
            beq     @Loop

            jsr     SwitchToHGR
            lda     @Border_Color
            sta     Border
            rts

@PG_INFO:
            .byte   BRD_C, COLOR_RED
            .byte   SCR_C, COLOR_RED
            .byte   CLS
            .byte   SETPOS, 0, 0
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
            .byte   ENDPAGE


INIT_FACE_EDGE_WALKERS:

            ; --------------------------------
            ; Initialize edge A
            ; --------------------------------

            lda     EDGE_A_START_POSITION
            sta     EDGE_START_POSITION
            lda     EDGE_A_END_POSITION
            sta     EDGE_END_POSITION

            jsr     LOAD_EDGE_ENDPOINTS
            jsr     CALC_EDGE_SLOPE

            ; Starting X -> 16.16
            lda     #0
            sta     EDGE_A_X
            sta     EDGE_A_X+1
            lda     EDGE_X0
            sta     EDGE_A_X+2
            lda     EDGE_X0+1
            sta     EDGE_A_X+3

            ; Save slope A
            ldx     #0
@CopySlopeA:
            lda     EDGE_SLOPE,x
            sta     EDGE_A_SLOPE,x
            inx
            cpx     #4
            bne     @CopySlopeA

            ; --------------------------------
            ; Initialize edge B
            ; --------------------------------

            lda     EDGE_B_START_POSITION
            sta     EDGE_START_POSITION
            lda     EDGE_B_END_POSITION
            sta     EDGE_END_POSITION

            jsr     LOAD_EDGE_ENDPOINTS
            jsr     CALC_EDGE_SLOPE

            ; Starting X -> 16.16
            lda     #0
            sta     EDGE_B_X
            sta     EDGE_B_X+1
            lda     EDGE_X0
            sta     EDGE_B_X+2
            lda     EDGE_X0+1
            sta     EDGE_B_X+3

            ; Save slope B
            ldx     #0
@CopySlopeB:
            lda     EDGE_SLOPE,x
            sta     EDGE_B_SLOPE,x
            inx
            cpx     #4
            bne     @CopySlopeB

            rts

;********************************************
;* FACE EDGE WALKER WORKSPACE
;********************************************

EDGE_X0:
            .word   0
EDGE_X1:
            .word   0
EDGE_Y0:
            .byte   0
EDGE_Y1:
            .byte   0

EDGE_DX:
            .word   0
EDGE_DY:
            .byte   0

EDGE_DIV_A:
            .ds     4
EDGE_DIV_B:
            .ds     4
EDGE_SLOPE:
            .ds     4

EDGE_A_START_POSITION:
            .byte   0
EDGE_A_END_POSITION:
            .byte   0
EDGE_B_START_POSITION:
            .byte   0
EDGE_B_END_POSITION:
            .byte   0

FACE_WALK_POSITION:
            .byte   0
EDGE_A_X:
            .ds     4
EDGE_B_X:
            .ds     4
EDGE_A_SLOPE:
            .ds     4
EDGE_B_SLOPE:
            .ds     4
EDGE_START_POSITION:
            .byte   0
EDGE_END_POSITION:
            .byte   0
