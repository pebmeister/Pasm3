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
       
            rts
            
            
;********************************************
;* SET_EDGE_A_SEGMENT                       *
;*                                          *
;* EDGE_A_POSITION = current vertex         *
;* Finds next vertex going backward.        *
;* Skips vertices with the same Y.          *
;*                                          *
;* Sets:                                    *
;*   EDGE_A_END_POSITION                    *
;*   EDGE_A_X                              *
;*   EDGE_A_SLOPE                          *
;********************************************

SET_EDGE_A_SEGMENT:
            lda FACE_WALK_POSITION
            beq @Wrap

            sec
            sbc #1
            jmp @Check

@Wrap:
            lda #3

@Check:
            sta EDGE_A_END_POSITION

            ; Skip same-Y vertex
            tax
            lda FACE_VERTEX_Y_LIST,x

            ldx FACE_WALK_POSITION
            cmp FACE_VERTEX_Y_LIST,x
            beq SET_EDGE_A_SEGMENT

            ; Load this segment
            lda FACE_WALK_POSITION
            sta EDGE_START_POSITION

            lda EDGE_A_END_POSITION
            sta EDGE_END_POSITION

            jsr LOAD_EDGE_ENDPOINTS
            jsr CALC_EDGE_SLOPE

            ; Start X
            lda EDGE_X0
            sta EDGE_A_X+2
            lda EDGE_X0+1
            sta EDGE_A_X+3

            lda #0
            sta EDGE_A_X
            sta EDGE_A_X+1

            ; Save slope
            lda EDGE_SLOPE
            sta EDGE_A_SLOPE
            lda EDGE_SLOPE+1
            sta EDGE_A_SLOPE+1
            lda EDGE_SLOPE+2
            sta EDGE_A_SLOPE+2
            lda EDGE_SLOPE+3
            sta EDGE_A_SLOPE+3

            rts


;********************************************
;* LOAD_FACE_VERTICES
;*
;* Input:
;*   FACE_INDEX
;*   MODEL_FACES_PTR
;*
;* Output:
;*   FACE_VERTEX_LIST[0..3]
;********************************************

LOAD_FACE_VERTICES:

            lda     FACE_INDEX
            asl
            asl
            sta     DRAW_FACE_OFFSET

            ldx     #0

@LoadLoop:
            ldy     DRAW_FACE_OFFSET
            lda     (MODEL_FACES_PTR),y
            sta     FACE_VERTEX_LIST,x

            sta     FACE_VERTEX_INDEX
            jsr     LoadVertex

            ; Save Y coordinate for top/bottom search
            lda     FACE_VERTEX_Y
            sta     FACE_VERTEX_Y_LIST,x

            inc     DRAW_FACE_OFFSET
            inx
            cpx     #4
            bne     @LoadLoop

            rts

;********************************************
;* FIND_FACE_TOP_BOTTOM
;*
;* Input:
;*   FACE_VERTEX_Y_LIST
;*
;* Output:
;*   FACE_TOP_POSITION
;*   FACE_BOTTOM_POSITION
;********************************************

FIND_FACE_TOP_BOTTOM:

            lda     #0
            sta     FACE_TOP_POSITION
            sta     FACE_BOTTOM_POSITION

            lda     FACE_VERTEX_Y_LIST
            sta     FACE_TOP_Y
            sta     FACE_BOTTOM_Y

            ldx     #1

@FindLoop:
            lda     FACE_VERTEX_Y_LIST,x

            cmp     FACE_TOP_Y
            bcs     @CheckBottom

            sta     FACE_TOP_Y
            stx     FACE_TOP_POSITION

@CheckBottom:
            lda     FACE_VERTEX_Y_LIST,x
            cmp     FACE_BOTTOM_Y
            bcc     @NextVertex

            sta     FACE_BOTTOM_Y
            stx     FACE_BOTTOM_POSITION

@NextVertex:
            inx
            cpx     #4
            bne     @FindLoop

            rts            

;********************************************
;* INIT_FACE_EDGE_WALKERS                   *
;*                                          *
;* Initialize both edge walkers at the      *
;* top vertex of the face.                  *
;********************************************

INIT_FACE_EDGE_WALKERS:

            ; --------------------------------
            ; EDGE A
            ; Walk backward from top
            ; --------------------------------
            lda FACE_TOP_POSITION
            sta EDGE_A_START_POSITION

            ; Previous position, wrapping 0 -> 3
            beq @A_Wrap

            sec
            sbc #1
            jmp @A_SetEnd

@A_Wrap:
            lda #3

@A_SetEnd:
            sta EDGE_A_END_POSITION

            ; Load A segment
            lda EDGE_A_START_POSITION
            sta EDGE_START_POSITION

            lda EDGE_A_END_POSITION
            sta EDGE_END_POSITION

            jsr LOAD_EDGE_ENDPOINTS
            jsr CALC_EDGE_SLOPE

            ; A X = starting vertex X, converted
            ; from integer to 16.16
            lda #0
            sta EDGE_A_X
            sta EDGE_A_X+1

            lda EDGE_X0
            sta EDGE_A_X+2
            lda EDGE_X0+1
            sta EDGE_A_X+3

            ; Save A slope
            lda EDGE_SLOPE
            sta EDGE_A_SLOPE
            lda EDGE_SLOPE+1
            sta EDGE_A_SLOPE+1
            lda EDGE_SLOPE+2
            sta EDGE_A_SLOPE+2
            lda EDGE_SLOPE+3
            sta EDGE_A_SLOPE+3


            ; --------------------------------
            ; EDGE B
            ; Walk forward from top
            ; Skip horizontal top edge
            ; --------------------------------
            lda FACE_TOP_POSITION
            sta EDGE_B_START_POSITION

@B_FindEnd:
            lda EDGE_B_START_POSITION
            cmp #3
            beq @B_Wrap

            clc
            adc #1
            jmp @B_CheckY

@B_Wrap:
            lda #0

@B_CheckY:
            sta EDGE_B_END_POSITION

            tax
            lda FACE_VERTEX_Y_LIST,x

            ldx EDGE_B_START_POSITION
            cmp FACE_VERTEX_Y_LIST,x
            bne @B_LoadSegment

            ; Horizontal edge: move start forward
            lda EDGE_B_END_POSITION
            sta EDGE_B_START_POSITION
            jmp @B_FindEnd

@B_LoadSegment:
            lda EDGE_B_START_POSITION
            sta EDGE_START_POSITION

            lda EDGE_B_END_POSITION
            sta EDGE_END_POSITION

            jsr LOAD_EDGE_ENDPOINTS
            jsr CALC_EDGE_SLOPE

            lda #0
            sta EDGE_B_X
            sta EDGE_B_X+1

            lda EDGE_X0
            sta EDGE_B_X+2
            lda EDGE_X0+1
            sta EDGE_B_X+3

            lda EDGE_SLOPE
            sta EDGE_B_SLOPE
            lda EDGE_SLOPE+1
            sta EDGE_B_SLOPE+1
            lda EDGE_SLOPE+2
            sta EDGE_B_SLOPE+2
            lda EDGE_SLOPE+3
            sta EDGE_B_SLOPE+3
            rts

ADVANCE_EDGE_A:

            ; Current segment has ended.
            ; New start = old end.
            lda EDGE_A_END_POSITION
            sta EDGE_A_START_POSITION

            ; Find previous position.
            beq @Wrap

            sec
            sbc #1
            jmp @SetEnd

@Wrap:
            lda #3

@SetEnd:
            sta EDGE_A_END_POSITION

            ; Load new segment
            lda EDGE_A_START_POSITION
            sta EDGE_START_POSITION

            lda EDGE_A_END_POSITION
            sta EDGE_END_POSITION

            jsr LOAD_EDGE_ENDPOINTS
            jsr CALC_EDGE_SLOPE

            ; Reset A X to new segment start
            lda #0
            sta EDGE_A_X
            sta EDGE_A_X+1

            lda EDGE_X0
            sta EDGE_A_X+2
            lda EDGE_X0+1
            sta EDGE_A_X+3

            ; Save new A slope
            lda EDGE_SLOPE
            sta EDGE_A_SLOPE
            lda EDGE_SLOPE+1
            sta EDGE_A_SLOPE+1
            lda EDGE_SLOPE+2
            sta EDGE_A_SLOPE+2
            lda EDGE_SLOPE+3
            sta EDGE_A_SLOPE+3

            rts

ADVANCE_EDGE_B:

            lda EDGE_B_END_POSITION
            sta EDGE_B_START_POSITION

            cmp #3
            beq @Wrap

            clc
            adc #1
            jmp @SetEnd

@Wrap:
            lda #0

@SetEnd:
            sta EDGE_B_END_POSITION

            ; Load new segment
            lda EDGE_B_START_POSITION
            sta EDGE_START_POSITION

            lda EDGE_B_END_POSITION
            sta EDGE_END_POSITION

            jsr LOAD_EDGE_ENDPOINTS
            jsr CALC_EDGE_SLOPE

            ; Reset B X
            lda #0
            sta EDGE_B_X
            sta EDGE_B_X+1

            lda EDGE_X0
            sta EDGE_B_X+2
            lda EDGE_X0+1
            sta EDGE_B_X+3

            ; Save new B slope
            lda EDGE_SLOPE
            sta EDGE_B_SLOPE
            lda EDGE_SLOPE+1
            sta EDGE_B_SLOPE+1
            lda EDGE_SLOPE+2
            sta EDGE_B_SLOPE+2
            lda EDGE_SLOPE+3
            sta EDGE_B_SLOPE+3

            rts

;********************************************
;* TEST_EDGE_A_TRANSITION                   *
;********************************************
TEST_EDGE_A_TRANSITION

            ; Move A to the endpoint of its current segment
            lda EDGE_A_END_POSITION
            sta EDGE_A_START_POSITION

            ; Find previous position (backward)
            beq @Wrap

            sec
            sbc #1
            jmp @SetEnd

@Wrap:
            lda #3

@SetEnd:
            sta EDGE_A_END_POSITION

            ; Load new segment endpoints
            lda EDGE_A_START_POSITION
            sta EDGE_START_POSITION

            lda EDGE_A_END_POSITION
            sta EDGE_END_POSITION

            jsr LOAD_EDGE_ENDPOINTS
            jsr CALC_EDGE_SLOPE

            ; Initialize A X from new starting vertex
            lda #0
            sta EDGE_A_X
            sta EDGE_A_X+1

            lda EDGE_X0
            sta EDGE_A_X+2
            lda EDGE_X0+1
            sta EDGE_A_X+3

            ; Save new slope
            lda EDGE_SLOPE
            sta EDGE_A_SLOPE
            lda EDGE_SLOPE+1
            sta EDGE_A_SLOPE+1
            lda EDGE_SLOPE+2
            sta EDGE_A_SLOPE+2
            lda EDGE_SLOPE+3
            sta EDGE_A_SLOPE+3

            rts
                        
;********************************************
;* TEST_EDGE_B_TRANSITION                   *
;*                                          *
;* Advance edge B to its next segment       *
;********************************************

TEST_EDGE_B_TRANSITION:

            ; Move B to the endpoint of its current segment
            lda EDGE_B_END_POSITION
            sta EDGE_B_START_POSITION

            ; Find next position (forward)
            cmp #3
            beq @Wrap

            clc
            adc #1
            jmp @SetEnd

@Wrap:
            lda #0

@SetEnd:
            sta EDGE_B_END_POSITION

            ; Load new segment endpoints
            lda EDGE_B_START_POSITION
            sta EDGE_START_POSITION

            lda EDGE_B_END_POSITION
            sta EDGE_END_POSITION

            jsr LOAD_EDGE_ENDPOINTS
            jsr CALC_EDGE_SLOPE

            ; Initialize B X from new starting vertex
            lda #0
            sta EDGE_B_X
            sta EDGE_B_X+1

            lda EDGE_X0
            sta EDGE_B_X+2
            lda EDGE_X0+1
            sta EDGE_B_X+3

            ; Save new slope
            lda EDGE_SLOPE
            sta EDGE_B_SLOPE
            lda EDGE_SLOPE+1
            sta EDGE_B_SLOPE+1
            lda EDGE_SLOPE+2
            sta EDGE_B_SLOPE+2
            lda EDGE_SLOPE+3
            sta EDGE_B_SLOPE+3

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
