; ============================================
; CLAMP_LINE_COORDS
; Clamps X0, X1 to screen range 0-319 ($013F)
; Clamps Y0, Y1 to screen range 0-199 ($C7)
; ============================================
CLAMP_LINE_COORDS:
            ; --- Clamp X0 ---
            lda     X0 + 1
            bmi     @clamp_x0_zero
            beq     @clamp_y0
            cmp     #1
            bne     @clamp_x0_max
            lda     X0
            cmp     #$40
            bcc     @clamp_y0
@clamp_x0_max:
            lda     #<319
            sta     X0
            lda     #>319
            sta     X0 + 1
            jmp     @clamp_y0
@clamp_x0_zero:
            lda     #0
            sta     X0
            sta     X0 + 1

@clamp_y0:
            ; --- Clamp Y0 (unsigned 0-199) ---
            lda     Y0
            cmp     #200
            bcc     @clamp_x1
            lda     #199
            sta     Y0

@clamp_x1:
            ; --- Clamp X1 ---
            lda     X1 + 1
            bmi     @clamp_x1_zero
            beq     @clamp_y1
            cmp     #1
            bne     @clamp_x1_max
            lda     X1
            cmp     #$40
            bcc     @clamp_y1
@clamp_x1_max:
            lda     #<319
            sta     X1
            lda     #>319
            sta     X1 + 1
            jmp     @clamp_y1
@clamp_x1_zero:
            lda     #0
            sta     X1
            sta     X1 + 1

@clamp_y1:
            ; --- Clamp Y1 ---
            lda     Y1
            cmp     #200
            bcc     @clamp_done
            lda     #199
            sta     Y1
            jmp     @clamp_done
@clamp_y1_zero:
            lda     #0
            sta     Y1

@clamp_done:
            rts
