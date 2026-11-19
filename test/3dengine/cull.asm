;********************************************
;* TEST_FACE
;*
;* FACE_INDEX = 0..5
;*
;* Calculates the signed 2D cross product:
;*
;*   CROSS = (X1-X0)*(Y2-Y0)
;*         - (Y1-Y0)*(X2-X0)
;*
;* Sets:
;*   CUBE_VISIBLE[FACE_INDEX]
;*
;* CROSS < 0 = visible (provisional)
;* CROSS >= 0 = back face (provisional)
;*
;********************************************

TEST_FACE

        ; Calculate face table offset
        lda FACE_INDEX
        asl
        asl
        sta FACE_TABLE_OFFSET

         ;------------------------------------
        ; Load vertex 0
        ;------------------------------------
        ldy     FACE_TABLE_OFFSET
        lda     (MODEL_FACES_PTR),y
        sta     FACE_VERTEX_INDEX
        jsr     @LoadVertex
        MOVE16  FACE_VERTEX_X, FACE_X0
        MOVE16  FACE_VERTEX_Y, FACE_Y0

        ;------------------------------------
        ; Load vertex 1
        ;------------------------------------
        inc     FACE_TABLE_OFFSET
        ldy     FACE_TABLE_OFFSET
        lda     (MODEL_FACES_PTR),y
        sta     FACE_VERTEX_INDEX
        jsr     @LoadVertex
        MOVE16  FACE_VERTEX_X, FACE_X1
        MOVE16  FACE_VERTEX_Y, FACE_Y1

        ;------------------------------------
        ; Load vertex 2
        ;------------------------------------
        inc     FACE_TABLE_OFFSET
        ldy     FACE_TABLE_OFFSET
        lda     (MODEL_FACES_PTR),y
        sta     FACE_VERTEX_INDEX
        jsr     @LoadVertex
        MOVE16  FACE_VERTEX_X, FACE_X2
        MOVE16  FACE_VERTEX_Y, FACE_Y2
        
        ;------------------------------------
        ; DX1 = X1 - X0
        ;------------------------------------
        sec
        lda FACE_X1
        sbc FACE_X0
        sta FACE_DX1
        lda FACE_X1+1
        sbc FACE_X0+1
        sta FACE_DX1+1

        ;------------------------------------
        ; DY1 = Y1 - Y0
        ;------------------------------------
        sec
        lda FACE_Y1
        sbc FACE_Y0
        sta FACE_DY1
        lda FACE_Y1+1
        sbc FACE_Y0+1
        sta FACE_DY1+1

        ;------------------------------------
        ; DX2 = X2 - X0
        ;------------------------------------
        sec
        lda FACE_X2
        sbc FACE_X0
        sta FACE_DX2
        lda FACE_X2+1
        sbc FACE_X0+1
        sta FACE_DX2+1

        ;------------------------------------
        ; DY2 = Y2 - Y0
        ;------------------------------------
        sec
        lda FACE_Y2
        sbc FACE_Y0
        sta FACE_DY2
        lda FACE_Y2+1
        sbc FACE_Y0+1
        sta FACE_DY2+1

        ;------------------------------------
        ; PRODUCT_A = DX1 * DY2
        ; PRODUCT_B = DY1 * DX2
        ;------------------------------------
        MULT16 FACE_DX1, FACE_DY2, FACE_PRODUCT_A
        MULT16 FACE_DY1, FACE_DX2, FACE_PRODUCT_B

        ;------------------------------------
        ; CROSS = PRODUCT_A - PRODUCT_B
        ;------------------------------------
        sec
        lda FACE_PRODUCT_A
        sbc FACE_PRODUCT_B
        sta FACE_CROSS
        lda FACE_PRODUCT_A+1
        sbc FACE_PRODUCT_B+1
        sta FACE_CROSS+1
        lda FACE_PRODUCT_A+2
        sbc FACE_PRODUCT_B+2
        sta FACE_CROSS+2
        lda FACE_PRODUCT_A+3
        sbc FACE_PRODUCT_B+3
        sta FACE_CROSS+3

        ;------------------------------------
        ; TEMP FOR DEBUGGING
        ;------------------------------------
        ; Save CROSS for this face
        lda FACE_INDEX
        asl
        asl
        tay

        lda FACE_CROSS
        sta FACE_CROSS_RESULTS,y
        iny
        lda FACE_CROSS+1
        sta FACE_CROSS_RESULTS,y
        iny
        lda FACE_CROSS+2
        sta FACE_CROSS_RESULTS,y
        iny
        lda FACE_CROSS+3
        sta FACE_CROSS_RESULTS,y
        
        ; CROSS > 0 = visible
        lda FACE_CROSS+3
        bmi @Hidden

        ; Zero-area faces are also hidden
        ora FACE_CROSS+2
        ora FACE_CROSS+1
        ora FACE_CROSS
        beq @Hidden

@Visible
        lda #1
        ldy FACE_INDEX
        sta CUBE_VISIBLE,y
        rts

@Hidden
        lda #0
        ldy FACE_INDEX
        sta CUBE_VISIBLE,y
        rts
        
 
        ;------------------------------------
        ; Load screen vertex
        ; Input: FACE_VERTEX_INDEX
        ; Output: FACE_VERTEX_X, FACE_VERTEX_Y
        ;------------------------------------
@LoadVertex
        lda FACE_VERTEX_INDEX
        asl
        clc
        adc FACE_VERTEX_INDEX
        tay

        lda SCREEN_VERTICES,y
        sta FACE_VERTEX_X
        iny
        lda SCREEN_VERTICES,y
        sta FACE_VERTEX_X+1
        iny
        lda SCREEN_VERTICES,y
        sta FACE_VERTEX_Y

        lda #0
        sta FACE_VERTEX_Y+1
        rts
        
 
        
;********************************************
;* Load one screen vertex
;*
;* FACE_VERTEX_INDEX = vertex number
;*
;* Returns:
;*   FACE_VERTEX_X = signed 16-bit X
;*   FACE_VERTEX_Y = signed 16-bit Y
;*
;* SCREEN_VERTICES:
;*   +0 X low
;*   +1 X high
;*   +2 Y
;********************************************

LoadVertex:

        lda FACE_VERTEX_INDEX
        asl
        clc
        adc FACE_VERTEX_INDEX
        tay

        lda SCREEN_VERTICES,y
        sta FACE_VERTEX_X

        iny
        lda SCREEN_VERTICES,y
        sta FACE_VERTEX_X+1

        iny
        lda SCREEN_VERTICES,y
        sta FACE_VERTEX_Y

        lda #0
        sta FACE_VERTEX_Y+1

        rts
        

FACE_INDEX          .byte 0
FACE_VERTEX_INDEX   .byte 0

FACE_VERTEX_X       .word 0
FACE_VERTEX_Y       .word 0

FACE_X0             .word 0
FACE_Y0             .word 0
FACE_X1             .word 0
FACE_Y1             .word 0
FACE_X2             .word 0
FACE_Y2             .word 0

FACE_DX1            .word 0
FACE_DY1            .word 0
FACE_DX2            .word 0
FACE_DY2            .word 0

FACE_PRODUCT_A      .ds 4
FACE_PRODUCT_B      .ds 4
FACE_CROSS          .ds 4
FACE_TABLE_OFFSET   .byte 0
FACE_CROSS_RESULTS  .ds 24
