.print push
.print off

;********************************************
;* PUSH16                                   *
;* Push 16-bit value                        *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro PUSH16
        lda \1
        pha
        lda \1 + 1
        pha
        .endm

;********************************************
;* POP16                                    *
;* Pop 16-bit value                         *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro POP16
        pla
        sta \1 + 1
        pla
        sta \1
        .endm

;********************************************
;* INC16                                    *
;* Increment a 16-bit variable              *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro INC16
        inc \1
        bne @exit
        inc \1 + 1
@exit:
        .endm

        
;********************************************
;* MULT16I                                  *
;* 16-bit immediate multiplication          *
;* \1 Immediate value a (16-bit constant)   *
;* \2 Variable b (16-bit variable)          *
;* \3 Destination (32-bit)                  *
;* Destroys A, X, Y                         *
;********************************************

        .macro MULT16I
        PUSH16 \2

        lda #0
        sta \3                      ; Result byte 0
        sta \3 + 1                  ; Result byte 1
        sta \3 + 2                  ; Result byte 2
        ; A must also start at zero!
        ; Do this after clearing the destination.
        lda #0

        ldx #16
@l1:
        lsr \2 + 1
        ror \2
        bcc @l2

        tay
        clc
        lda #<\1
        adc \3 + 2
        sta \3 + 2

        tya
        adc #>\1
@l2:
        ror
        ror \3 + 2
        ror \3 + 1
        ror \3

        dex
        bne @l1

        sta \3 + 3
        POP16 \2
        .endm
        
;********************************************
;* ADD_FIX16
;*
;* /1 = Variable 1
;* /2 = Variable 2
;* /3 = Destination
;*
;* Adds signed 16.16 values using two's
;* complement representation.
;* Destroys A.
;********************************************

        .macro ADD_FIX16
        clc
        lda \1
        adc \2
        sta \3

        lda \1 + 1
        adc \2 + 1
        sta \3 + 1

        lda \1 + 2
        adc \2 + 2
        sta \3 + 2

        lda \1 + 3
        adc \2 + 3
        sta \3 + 3
        .endm
        
;********************************************
;* LOAD_FIX16_PTR                           *
;* Copy 4-byte Fix16 from pointer \1 to \2  *
;* \1 Pointer variable (2 bytes)            *
;* \2 Destination variable (4 bytes)        *
;* Destroys A, Y                            *
;********************************************
        .macro LOAD_FIX16_PTR
        ldy #0
@Loop
        lda (\1),y
        sta \2,y
        iny
        cpy #4
        bne @Loop
        .endm
        
;********************************************
;* STORE_FIX16_PTR                          *
;* Copy 4-byte Fix16 from \1 to pointer \2  *
;* \1 Source variable (4 bytes)             *
;* \2 Destination pointer variable (2 bytes)*
;* Destroys A, Y                            *
;********************************************
        .macro STORE_FIX16_PTR
        ldy #0
@Loop
        lda \1,y
        sta (\2),y
        iny
        cpy #4
        bne @Loop
        .endm
        
        
;********************************************
;* SUB_FIX16                                *
;* Subtract two 16.16 fixed-point variables *
;* \1 Source variable 1 (16.16)             *
;* \2 Source variable 2 to subtract (16.16) *
;* \3 Destination (16.16)                   *
;* Destroys A                               *
;********************************************
        .macro SUB_FIX16
        sec
        lda \1
        sbc \2
        sta \3
        lda \1 + 1
        sbc \2 + 1
        sta \3 + 1
        lda \1 + 2
        sbc \2 + 2
        sta \3 + 2
        lda \1 + 3
        sbc \2 + 3
        sta \3 + 3
        .endm
        
       
;********************************************
;* CALL_FIX16_MUL                           *
;********************************************
        .macro CALL_FIX16_MUL

        lda #<\1
        sta FIX16_A_PTR
        lda #>\1
        sta FIX16_A_PTR+1
        lda #<\2
        sta FIX16_B_PTR
        lda #>\2
        sta FIX16_B_PTR+1

        lda #<\3
        sta FIX16_RESULT_PTR
        lda #>\3
        sta FIX16_RESULT_PTR+1

        jsr FIX16_MUL

        .endm

;********************************************
;* CALL_MAT4_MUL (optional macro wrapper)   *
;* Sets A, B, R pointers and calls MAT4_MUL *
;* \1 Address of Matrix A (64 bytes)        *
;* \2 Address of Matrix B (64 bytes)        *
;* \3 Address of Result R (64 bytes)        *
;********************************************
        .macro CALL_MAT4_MUL
        lda #<\1
        sta MAT_A_PTR
        lda #>\1
        sta MAT_A_PTR + 1

        lda #<\2
        sta MAT_B_PTR
        lda #>\2
        sta MAT_B_PTR + 1

        lda #<\3
        sta MAT_R_PTR
        lda #>\3
        sta MAT_R_PTR + 1

        jsr MAT4_MUL
        .endm

;********************************************
;* CALL_FIX16_DIV                           *
;* Set pointers and call signed 16.16 div   *
;* \1 Dividend address (4 bytes, signed)    *
;* \2 Divisor address (4 bytes, signed)     *
;* \3 Destination address (4 bytes, signed) *
;* \4 19-byte ZP workspace base address      *
;********************************************
        .macro CALL_FIX16_DIV
        lda #<\1
        sta FIX16_DIV_A_PTR
        lda #>\1
        sta FIX16_DIV_A_PTR + 1

        lda #<\2
        sta FIX16_DIV_B_PTR
        lda #>\2
        sta FIX16_DIV_B_PTR + 1

        lda #<\3
        sta FIX16_DIV_RES_PTR
        lda #>\3
        sta FIX16_DIV_RES_PTR + 1

        jsr FIX16_DIV
        .endm

;********************************************
;* CALL_VEC3_MAT4_MUL                       *
;* Set pointers and transform 3D Fix16 vec  *
;* \1 4x4 Fix16 matrix address (64 bytes)   *
;* \2 Input 3D Fix16 vector address (12B)   *
;* \3 Output 3D Fix16 vector address (12B)  *
;********************************************
        .macro CALL_VEC3_MAT4_MUL
        lda #<\1
        sta MAT_A_PTR
        lda #>\1
        sta MAT_A_PTR + 1

        lda #<\2
        sta VEC_IN_PTR
        lda #>\2
        sta VEC_IN_PTR + 1

        lda #<\3
        sta VEC_OUT_PTR
        lda #>\3
        sta VEC_OUT_PTR + 1

        jsr VEC3_MAT4_MUL
        .endm

;********************************************
;* GET_SINE                                 *
;* Lookup 16.16 Sine value from table       *
;* \1 Angle (8-bit index 0-255)             *
;* \2 Destination (32-bit variable)         *
;* Destroys A, Y, FIXPTR, TEMP16            *
;********************************************
            .macro  GET_SINE
            lda     \1
            jsr     LookupSineTable
            ldy     #0
            lda     (FIXPTR),y
            sta     \2
            iny
            lda     (FIXPTR),y
            sta     \2+1
            iny
            lda     (FIXPTR),y
            sta     \2+2
            iny
            lda     (FIXPTR),y
            sta     \2+3
            .endm

;********************************************
;* GET_COSINE                               *
;* Lookup 16.16 Cosine value from table     *
;* (\+64 phase shift for 90° cosine offset) *
;* \1 Angle (8-bit index 0-255)             *
;* \2 Destination (32-bit variable)         *
;* Destroys A, Y, FIXPTR, TEMP16            *
;********************************************
            .macro  GET_COSINE
            lda     \1
            clc
            adc     #64
            jsr     LookupSineTable
            ldy     #0
            lda     (FIXPTR),y
            sta     \2
            iny
            lda     (FIXPTR),y
            sta     \2+1
            iny
            lda     (FIXPTR),y
            sta     \2+2
            iny
            lda     (FIXPTR),y
            sta     \2+3
            .endm        
.print pop
