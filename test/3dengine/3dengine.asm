
; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================
        .basic_hdr
       
        jsr CLEARSCREEN
        
        lda #0
        sta ROW
        
        jsr new_test
 
@wait
        jmp @wait
        
new_test
        lda #1                  ; 1 vector/matrix to display
        sta NUM_VECS
        
        lda #4                  ; 3 rows in the result vector
        ldx #0
@set_res_rows_gen:
        sta VEC_ROWS, x
        inx
        cpx #1                  ; For our 1 vector
        bne @set_res_rows_gen

        lda #4                  ; 1 column for the vector
        sta VEC_COLS

        ; Point FIXPTR at our output buffer
        lda #<MAT_A
        sta FIXPTR
        lda #>MAT_A
        sta FIXPTR+1

        ; Print the transformed vector to the screen
        jsr DisplayResults
        rts

