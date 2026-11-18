TEST_FACE:

            ;------------------------------------
            ; Get face address
            ;------------------------------------

            lda     FACE_INDEX
            asl
            asl
            tay

            ;------------------------------------
            ; Load vertex 0
            ;------------------------------------

            lda     CUBE_FACES,y
            sta     DRAW_VERTEX_INDEX

            asl
            clc
            adc     DRAW_VERTEX_INDEX
            tay

            lda     SCREEN_VERTICES,y
            sta     FACE_X0
            iny
            lda     SCREEN_VERTICES,y
            sta     FACE_X0+1
            iny
            lda     SCREEN_VERTICES,y
            sta     FACE_Y0
            iny
            lda     #0
            sta     FACE_Y0+1

            ;------------------------------------
            ; Load vertex 1
            ;------------------------------------

            lda     FACE_INDEX
            asl
            asl
            tay
            iny

            lda     CUBE_FACES,y
            sta     DRAW_VERTEX_INDEX

            asl
            clc
            adc     DRAW_VERTEX_INDEX
            tay

            lda     SCREEN_VERTICES,y
            sta     FACE_X1
            iny
            lda     SCREEN_VERTICES,y
            sta     FACE_X1+1
            iny
            lda     SCREEN_VERTICES,y
            sta     FACE_Y1
            iny
            lda     #0
            sta     FACE_Y1+1

            ;------------------------------------
            ; Load vertex 2
            ;------------------------------------

            lda     FACE_INDEX
            asl
            asl
            tay
            iny
            iny

            lda     CUBE_FACES,y
            sta     DRAW_VERTEX_INDEX

            asl
            clc
            adc     DRAW_VERTEX_INDEX
            tay

            lda     SCREEN_VERTICES,y
            sta     FACE_X2
            iny
            lda     SCREEN_VERTICES,y
            sta     FACE_X2+1
            iny
            lda     SCREEN_VERTICES,y
            sta     FACE_Y2
            iny
            lda     #0
            sta     FACE_Y2+1

            ;------------------------------------
            ; DX1 = X1 - X0
            ;------------------------------------

            sec
            lda     FACE_X1
            sbc     FACE_X0
            sta     FACE_DX1
            lda     FACE_X1+1
            sbc     FACE_X0+1
            sta     FACE_DX1+1

            ;------------------------------------
            ; DY1 = Y1 - Y0
            ;------------------------------------

            sec
            lda     FACE_Y1
            sbc     FACE_Y0
            sta     FACE_DY1
            lda     FACE_Y1+1
            sbc     FACE_Y0+1
            sta     FACE_DY1+1

            ;------------------------------------
            ; DX2 = X2 - X0
            ;------------------------------------

            sec
            lda     FACE_X2
            sbc     FACE_X0
            sta     FACE_DX2
            lda     FACE_X2+1
            sbc     FACE_X0+1
            sta     FACE_DX2+1

            ;------------------------------------
            ; DY2 = Y2 - Y0
            ;------------------------------------

            sec
            lda     FACE_Y2
            sbc     FACE_Y0
            sta     FACE_DY2
            lda     FACE_Y2+1
            sbc     FACE_Y0+1
            sta     FACE_DY2+1

; Face culling workspace
FACE_INDEX:
            .byte   0
FACE_VERTEX_INDEX:
            .byte   0

FACE_X0:
            .word   0
FACE_Y0:
            .word   0
FACE_X1:
            .word   0
FACE_Y1:
            .word   0
FACE_X2:
            .word   0
FACE_Y2:
            .word   0

FACE_DX1:
            .word   0
FACE_DY1:
            .word   0
FACE_DX2:
            .word   0
FACE_DY2:
            .word   0

FACE_PRODUCT_A:
            .ds     4
FACE_PRODUCT_B:
            .ds     4
FACE_CROSS:
            .ds     4
