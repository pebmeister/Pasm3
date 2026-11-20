            SETPOS  = 1
            NEXTROW = 2
            STRING  = 3
            INT8    = 4
            INT8_HEX = 5
            INT16   = 6
            FIX16   = 7
            INT8_I  = 8
            INT16_HEX = 9
            VRT_ARRAY = 10
            VRT_PTR_ARRAY = 11
            BRD_C   = 12
            SCR_C   = 13
            TAB     = 14
            SPC     = 15
            CLS     = 16

            ENDPAGE = $ff

DisplayPage:
@CmdLoop:
            jsr     @GetNextByte
            lda     @Char

            ; check for done first
            cmp     #ENDPAGE
            bne     @Cmd_Continue

            jmp     @Done

@Cmd_Continue:
            cmp     #SETPOS
            bne     @Check_NextRow

; SetPos
            jsr     @GetNextByte
            lda     @Char
            sta     @Row

            jsr     @GetNextByte
            ldy     @Char
            ldx     @Row
            clc
            jsr     PLOT

            jmp     @CmdLoop

@Check_NextRow:
            cmp     #NEXTROW
            bne     @Check_String

; NextRow
            inc     @Row
            ldx     @Row
            ldy     #$00
            clc
            jsr     PLOT

            jmp     @CmdLoop

@Check_String:
            cmp     #STRING
            bne     @Check_Int8

; Print String
            lda     TXPTR
            ldy     TXPTR + 1
            jsr     SAFE_STROUT

            ; advance TXPTR past terminating null
@Char_Loop:
            jsr     @GetNextByte
            lda     @Char
            bne     @Char_Loop

            jmp     @CmdLoop

@Check_Int8:
            cmp     #INT8
            bne     @Check_Int8Hex

; Print Int8
            jsr     @GetByteFromPtr
            lda     @Byte
            sta     TEMP16
            lda     #0
            sta     TEMP16 + 1
            jsr     PRINT_INT16

            jmp     @CmdLoop

@Check_Int8Hex:
            cmp     #INT8_HEX
            bne     @Check_Int16

; Print Int8_Hex
            jsr     @GetByteFromPtr
            lda     @Byte
            sta     TMP
            jsr     PRINT8_HEX

            jmp     @CmdLoop

@Check_Int16:
            cmp     #INT16
            bne     @Check_Fix16

; Print Int16
            jsr     @GetWordFromPtr
            MOVE16  @Word, TEMP16
            jsr     PRINT_INT16

            jmp     @CmdLoop

@Check_Fix16:
            cmp     #FIX16
            bne     @Check_Int8_I

; Print Fix16
            jsr     @GetPtr
            MOVE16  @Ptr, FIXPTR
            jsr     PRINT_FIX16

            jmp     @CmdLoop

@Check_Int8_I:
            cmp     #INT8_I
            bne     @Check_Int16_Hex

; Print Int8 immediate (not a var)
            jsr     @GetNextByte
            lda     @Char
            sta     TEMP16
            lda     #0
            sta     TEMP16 + 1
            jsr     PRINT_INT16

            jmp     @CmdLoop

@Check_Int16_Hex:
            cmp     #INT16_HEX
            bne     @Check_VRT_Array

; Print Int16_Hex
            jsr     @GetWordFromPtr
            MOVE16  @Word, TEMP16
            jsr     PRINT_INT16_HEX

            jmp     @CmdLoop

@Check_VRT_Array:
            cmp     #VRT_ARRAY
            beq     @Print_Vert_Array
            jmp     @Check_Ptr_VRT_Array

@Print_Vert_Array:
            jsr     @Get_Vert_Params

            ; get the Vert ptr
            jsr     @GetPtr
            MOVE16  @Ptr, @VERT_PTR

@PrintVertex:
            ; Initialize counters
            lda     #0
            sta     @INDEX

@VertLoop:
            ; Have we printed all vertices?
            lda     @INDEX
            cmp     @VertCount
            bcc     @Vert_Continue
            jmp     @Vert_Done

@Vert_Continue:
            ;------------------------------------
            ; X coordinate - column VertCol_0
            ;------------------------------------
            ldx     @Row
            ldy     @VertCol_0
            clc
            jsr     PLOT

            MOVE16  @VERT_PTR, FIXPTR
            jsr     PRINT_FIX16

            ADD16I  @VERT_PTR, 4, @VERT_PTR

            ;------------------------------------
            ; Y coordinate - VertCol_1
            ;------------------------------------
            ldx     @Row
            ldy     @VertCol_1
            clc
            jsr     PLOT

            MOVE16  @VERT_PTR, FIXPTR
            jsr     PRINT_FIX16

            ADD16I  @VERT_PTR, 4, @VERT_PTR

            ;------------------------------------
            ; Z coordinate - VertCol_2
            ;------------------------------------
            ldx     @Row
            ldy     @VertCol_2
            clc
            jsr     PLOT

            MOVE16  @VERT_PTR, FIXPTR
            jsr     PRINT_FIX16

            ADD16I  @VERT_PTR, 4, @VERT_PTR

            ;------------------------------------
            ; W coordinate - VertCol_3
            ;------------------------------------
            ldx     @Row
            ldy     @VertCol_3
            clc
            jsr     PLOT

            MOVE16  @VERT_PTR, FIXPTR
            jsr     PRINT_FIX16

            ADD16I  @VERT_PTR, 4, @VERT_PTR

            ; Advance counters
            inc     @INDEX
            inc     @Row

            jmp     @VertLoop

@Vert_Done:
            jmp     @CmdLoop

@Check_Ptr_VRT_Array:
            cmp     #VRT_PTR_ARRAY
            beq     @Print_Vert_Ptr_Array
            jmp     @Check_BrdC

@Print_Vert_Ptr_Array:
            jsr     @Get_Vert_Params

            ; get the Vert ptr
            jsr     @GetPtr
            MOVE16  @Ptr, LOC

            ldy     #0
            lda     (LOC),y
            sta     @VERT_PTR
            INC16   LOC
            lda     (LOC),y
            sta     @VERT_PTR + 1

            jmp     @PrintVertex

@Check_BrdC:
            cmp     #BRD_C
            beq     @Print_BrdC
            jmp     @Check_SrcC

@Print_BrdC:
            jsr     @GetNextByte
            lda     @Char
            sta     Border

            jmp     @CmdLoop

@Check_SrcC:
            cmp     #SCR_C
            beq     @Print_SrcC
            jmp     @Check_Tab

@Print_SrcC:
            jsr     @GetNextByte
            lda     @Char
            sta     SCREENC

            jmp     @CmdLoop
@Check_Tab:
            cmp     #TAB
            bne     @Check_Spc
            jmp     @Print_Tab

@Print_Tab:
            jsr     @GetNextByte
            ldy     @Char
            ldx     @Row
            clc
            jsr     PLOT

            jmp     @CmdLoop

@Check_Spc:
            cmp     #SPC
            bne     @Check_Cls
            jmp     @Print_Spc

@Print_Spc:
            jsr     PRINT_SP

            jmp     @CmdLoop

@Check_Cls:
            cmp     #CLS
            bne     @Bad_Cmd
            jmp     @Print_Cls

@Print_Cls:
            jsr     CLEARSCREEN
            ldy     #0
            ldx     #0
            stx     @Row
            clc
            jsr     PLOT

            jmp     @CmdLoop

@Bad_Cmd:
@Done:
            rts

@GetNextByte:
            ldy     #0
            lda     (TXPTR),y
            sta     @Char
            INC16   TXPTR
            rts

@GetPtr:
            jsr     @GetNextByte
            lda     @Char
            sta     @Ptr
            jsr     @GetNextByte
            lda     @Char
            sta     @Ptr + 1
            rts

@GetByteFromPtr:
            jsr     @GetPtr
            lda     @Ptr
            sta     LOC
            lda     @Ptr + 1
            sta     LOC + 1

            ldy     #0
            lda     (LOC),y
            sta     @Byte
            rts

@GetWordFromPtr:
            jsr     @GetPtr
            lda     @Ptr
            sta     LOC
            lda     @Ptr + 1
            sta     LOC + 1

            ldy     #0
            lda     (LOC),y
            sta     @Word
            INC16   LOC
            lda     (LOC),y
            sta     @Word + 1
            rts

@Get_Vert_Params:
            ; get the count
            jsr     @GetByteFromPtr
            lda     @Byte
            sta     @VertCount

            ; column for x
            jsr     @GetNextByte
            lda     @Char
            sta     @VertCol_0

            ; column for y
            jsr     @GetNextByte
            lda     @Char
            sta     @VertCol_1

            ; column for z
            jsr     @GetNextByte
            lda     @Char
            sta     @VertCol_2

            ; column for w
            jsr     @GetNextByte
            lda     @Char
            sta     @VertCol_3
            rts

@Char:
            .ds     1
@Word:
            .ds     2
@Ptr:
            .ds     2
@Byte:
            .ds     1
@Row:
            .ds     1
@VertCount:
            .ds     1
@VertCol_0:
            .ds     1
@VertCol_1:
            .ds     1
@VertCol_2:
            .ds     1
@VertCol_3:
            .ds     1
@VERT_PTR:
            .ds     2
@INDEX:
            .ds     1
