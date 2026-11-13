;********************************************
;* TRANSFORM_WORLD_VERTICES_VERTICES        *
;*                                          *
;* Input:                                   *
;*   MODEL_MATRIX                           *
;*                                          *
;* Output:                                  *
;*   WORLD_VERTICES                         *
;*                                          *
;* Scratch:                                 *
;*   SCREEN_TEMP_A                          *
;*   SCREEN_TEMP_B                          *
;********************************************

TRANSFORM_WORLD_VERTICES:
        ; Set model matrix pointer
        lda #<MODEL_MATRIX
        sta MAT4_MATRIX_PTR
        lda #>MODEL_MATRIX
        sta MAT4_MATRIX_PTR+1

        ; Initialize source pointer from MODEL_VERTICES_PTR
        lda MODEL_VERTICES_PTR
        sta @MODEL_SRC_PTR
        lda MODEL_VERTICES_PTR+1
        sta @MODEL_SRC_PTR+1

        ; Initialize destination pointer
        lda #<WORLD_VERTICES
        sta @MODEL_DST_PTR
        lda #>WORLD_VERTICES
        sta @MODEL_DST_PTR+1

        ; Loop count based on active model vertex count
        lda MODEL_VERTEX_COUNT
        sta @WORLD_VERTICES_LEFT

@TransformLoop:
        lda @MODEL_SRC_PTR
        sta MAT4_VIN_PTR
        lda @MODEL_SRC_PTR+1
        sta MAT4_VIN_PTR+1

        lda @MODEL_DST_PTR
        sta MAT4_VOUT_PTR
        lda @MODEL_DST_PTR+1
        sta MAT4_VOUT_PTR+1

        jsr MAT3_VECTOR_MUL

        ; Advance source pointer by 16
        clc
        lda @MODEL_SRC_PTR
        adc #16
        sta @MODEL_SRC_PTR
        bcc @SourceReady
        inc @MODEL_SRC_PTR+1
@SourceReady:

        ; Advance destination pointer by 16
        clc
        lda @MODEL_DST_PTR
        adc #16
        sta @MODEL_DST_PTR
        bcc @DestinationReady
        inc @MODEL_DST_PTR+1
@DestinationReady:

        dec @WORLD_VERTICES_LEFT
        bne @TransformLoop
        rts
                
@MODEL_SRC_PTR:
        .word 0

@MODEL_DST_PTR:
        .word 0

@WORLD_VERTICES_LEFT:
        .byte 0
        
        
 