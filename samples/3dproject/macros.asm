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
;* MOVE16                                   *
;* Move a 16-bit variable                   *
;* \1 Source                                *
;* \2 Destination                           *
;* Destroys A                               *
;*******************************************
        .macro MOVE16
        lda \1
        sta \2
        lda \1 + 1
        sta \2 + 1
        .endm
        
;********************************************
;* MOVE16I                                  *
;* Move a 16-bit value to a variable        *
;* \1 Variable                              *
;* \2 Value                                 *
;* Destroys A                               *
;********************************************
        .macro MOVE16I
        lda #<\2
        sta \1
        lda #>\2
        sta \1 + 1
        .endm

;********************************************
;* BLE16                                    *
;* 16-bit branch if less than or equal      *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination label (if a <= b)         *
;* Destroys A                               *
;********************************************
        .macro BLE16
        lda \1 + 1
        cmp \2 + 1
        bcc \3
        bne @exit
        lda \1
        cmp \2
        bcc \3
        beq \3
@exit:
        .endm
        
;********************************************
;* BLT16                                    *
;* 16-bit branch if less than (a < b)       *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination label                     *
;* Destroys A                               *
;********************************************
        .macro BLT16
        lda \1 + 1
        cmp \2 + 1
        bcc \3
        bne @exit
        lda \1
        cmp \2
        bcc \3
@exit:
        .endm

;********************************************
;* SUB8                                     *
;* Subtract 8-bit variables                 *
;* \1 Variable                              *
;* \2 Variable to subtract                  *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB8
        sec
        lda \1
        sbc \2
        sta \3
        .endm
        
;********************************************
;* ADD16                                    *
;* Add 16-bit variables                     *
;* \1 Variable 1                            *
;* \2 Variable 2                            *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD16
        clc
        lda \1
        adc \2
        sta \3
        lda \1 + 1
        adc \2 + 1
        sta \3 + 1
        .endm

;********************************************
;* ADD16I                                   *
;* Add 16-bit immediate to 16-bit variable  *
;* \1 Variable                              *
;* \2 Value                                 *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD16I
        clc
        lda \1
        adc #<\2
        sta \3
        lda \1 + 1
        adc #>\2
        sta \3 + 1
        .endm


;********************************************
;*                                          *
;*  SWAP16                                  *
;*                                          *
;*  Swap 2 16 bit values                    *
;*                                          *
;*  \1  Variable a     16-bit               *
;*  \2  Variable b     16 bit               *
;*                                          *
;********************************************
            .macro SWAP16
            ldx \1
            ldy \1 + 1
            lda \2
            sta \1
            lda \2 + 1
            sta \1 + 1
            stx \2
            sty \2 + 1
            .endm

;********************************************
;* SUB16                                    *
;* Subtract 16-bit variables                *
;* \1 Variable                              *
;* \2 Variable to subtract                  *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB16
        sec
        lda \1
        sbc \2
        sta \3
        lda \1 + 1
        sbc \2 + 1
        sta \3 + 1
        .endm

;********************************************
;* SUB16I                                   *
;* Subtract 16-bit immediate from variable  *
;* \1 Variable                              *
;* \2 Value to subtract                     *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB16I
        sec
        lda \1
        sbc #<\2
        sta \3
        lda \1 + 1
        sbc #>\2
        sta \3 + 1
        .endm

;********************************************
;* MOVE8                                    *
;* Move an 8-bit variable                   *
;* \1 Source                                *
;* \2 Destination                           *
;* Destroys A                               *
;********************************************
        .macro MOVE8
        lda \1
        sta \2
        .endm

;********************************************
;* MOVE8I                                   *
;* Move an 8-bit value to a variable        *
;* \1 Variable                              *
;* \2 Value                                 *
;* Destroys A                               *
;********************************************
        .macro MOVE8I
        lda #\2
        sta \1
        .endm

;********************************************
;* LSHIFT16                                 *
;* 16-bit left shift                        *
;* \1 Variable                              *
;* \2 Bits to shift                         *
;* Destroys X                               *
;********************************************
        .macro LSHIFT16
        ldx #\2
        beq @LSH16Exit
@LS16Loop:
        asl \1
        rol \1 + 1
        dex
        bne @LS16Loop
@LSH16Exit:
        .endm

;********************************************
;* DEC8                                     *
;* Decrement an 8-bit variable              *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro DEC8
        dec \1
        .endm

;********************************************
;* DEC16                                    *
;* Decrement a 16-bit variable              *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro DEC16
        SUB16I \1, 1, \1
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
;* CALL_CREATE_XFORM_MAT4                   *
;* Build full 4x4 Fix16 TRS transform mat   *
;* \1  tx addr (4-byte Fix16)               *
;* \2  ty addr (4-byte Fix16)               *
;* \3  tz addr (4-byte Fix16)               *
;* \4  rx angle byte addr (0..255)          *
;* \5  ry angle byte addr (0..255)          *
;* \6  rz angle byte addr (0..255)          *
;* \7  sx addr (4-byte Fix16)               *
;* \8  sy addr (4-byte Fix16)               *
;* \9  sz addr (4-byte Fix16)               *
;* \10 Output 64-byte 4x4 Fix16 matrix addr *
;********************************************
        .macro CALL_CREATE_XFORM_MAT4
        ldx #0
@CopyTx
        lda \1,x
        sta XFORM_TX,x
        inx
        cpx #4
        bne @CopyTx

        ldx #0
@CopyTy
        lda \2,x
        sta XFORM_TY,x
        inx
        cpx #4
        bne @CopyTy

        ldx #0
@CopyTz
        lda \3,x
        sta XFORM_TZ,x
        inx
        cpx #4
        bne @CopyTz

        lda \4
        sta XFORM_RX_ANG
        lda \5
        sta XFORM_RY_ANG
        lda \6
        sta XFORM_RZ_ANG

        ldx #0
@CopySx
        lda \7,x
        sta XFORM_SX,x
        inx
        cpx #4
        bne @CopySx

        ldx #0
@CopySy
        lda \8,x
        sta XFORM_SY,x
        inx
        cpx #4
        bne @CopySy

        ldx #0
@CopySz
        lda \9,x
        sta XFORM_SZ,x
        inx
        cpx #4
        bne @CopySz

        lda #<\10
        sta XFORM_OUT_PTR
        lda #>\10
        sta XFORM_OUT_PTR + 1

        jsr CREATE_XFORM_MAT4
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

;********************************************
;* CALL_ROT_X_MAT4                          *
;* Build 4x4 Fix16 X-rotation matrix        *
;* \1 Angle byte address (8-bit, 0..255)    *
;* \2 Output 64-byte 4x4 Fix16 matrix addr  *
;********************************************
        .macro CALL_ROT_X_MAT4
        lda \1
        sta ROT_X_ANGLE

        lda #<\2
        sta ROT_OUT_PTR
        lda #>\2
        sta ROT_OUT_PTR + 1

        jsr ROT_X_MAT4
        .endm

;********************************************
;* CALL_ROT_Y_MAT4                          *
;* Build 4x4 Fix16 Y-rotation matrix        *
;* \1 Angle byte address (8-bit, 0..255)    *
;* \2 Output 64-byte 4x4 Fix16 matrix addr  *
;********************************************
        .macro CALL_ROT_Y_MAT4
        lda \1
        sta ROT_Y_ANGLE

        lda #<\2
        sta ROT_OUT_PTR
        lda #>\2
        sta ROT_OUT_PTR + 1

        jsr ROT_Y_MAT4
        .endm

;********************************************
;* CALL_ROT_Z_MAT4                          *
;* Build 4x4 Fix16 Z-rotation matrix        *
;* \1 Angle byte address (8-bit, 0..255)    *
;* \2 Output 64-byte 4x4 Fix16 matrix addr  *
;********************************************
        .macro CALL_ROT_Z_MAT4
        lda \1
        sta ROT_Z_ANGLE

        lda #<\2
        sta ROT_OUT_PTR
        lda #>\2
        sta ROT_OUT_PTR + 1

        jsr ROT_Z_MAT4
        .endm


;********************************************
;* CALL_ROT_XYZ_MAT4                        *
;* Build combined 4x4 Fix16 XYZ rot matrix  *
;* \1 X angle byte address (0..255)         *
;* \2 Y angle byte address (0..255)         *
;* \3 Z angle byte address (0..255)         *
;* \4 Output 64-byte 4x4 Fix16 matrix addr  *
;********************************************
        .macro CALL_ROT_XYZ_MAT4
        lda \1
        sta ROT_XYZ_AX

        lda \2
        sta ROT_XYZ_AY

        lda \3
        sta ROT_XYZ_AZ

        lda #<\4
        sta ROT_OUT_PTR
        lda #>\4
        sta ROT_OUT_PTR + 1

        jsr ROT_XYZ_MAT4
        .endm

;********************************************
;* CALL_PROJECT_POINT3D                     *
;* Project 3D Fix16 point to 2D screen Fix16*
;* \1 Input Point3D addr (12 bytes: X,Y,Z)  *
;* \2 half_width addr (4-byte Fix16)        *
;* \3 half_height addr (4-byte Fix16)       *
;* \4 fov_distance addr (4-byte Fix16)      *
;* \5 Output Point2D addr (8 bytes: X,Y)    *
;********************************************
        .macro CALL_PROJECT_POINT3D
        lda #<\1
        sta PROJ_IN_PTR
        lda #>\1
        sta PROJ_IN_PTR + 1

        ldx #0
@CopyHalfW
        lda \2,x
        sta PROJ_HALF_W,x
        inx
        cpx #4
        bne @CopyHalfW

        ldx #0
@CopyHalfH
        lda \3,x
        sta PROJ_HALF_H,x
        inx
        cpx #4
        bne @CopyHalfH

        ldx #0
@CopyFov
        lda \4,x
        sta PROJ_FOV,x
        inx
        cpx #4
        bne @CopyFov

        lda #<\5
        sta PROJ_OUT_PTR
        lda #>\5
        sta PROJ_OUT_PTR + 1

        jsr PROJECT_POINT3D
        .endm



.print pop

