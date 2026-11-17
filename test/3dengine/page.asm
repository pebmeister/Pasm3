SETROW      = 1
SETCOL      = 2
UPDATEPOS   = 3
NEXTROW     = 4
PRSTRING    = 5

ENDPAGE     = $FF

DisplayPage

@CmdLoop
        jsr GetNextByte
        lda Char
        
        ; check for done first
        cmp #ENDPAGE
        beq @Done

        cmp #SETROW
        bne @Check_SetCol

@Check_SetRow
        jsr GetNextByte
        lda Char
        sta Row
        jmp @CmdLoop

@Check_SetCol
        cmp #SETCOL
        bne @Check_UpdatePos

        jsr GetNextByte
        lda Char
        sta Col
        jmp @CmdLoop

@Check_UpdatePos
        cmp #UPDATEPOS
        bne @Check_NextRow

        ldx Row
        ldy Col
        clc
        jsr PLOT
        jmp @CmdLoop

@Check_NextRow
        cmp #NEXTROW
        bne @Check_PrintString

        inc Row
        lda #0
        sta Col
        jmp @CmdLoop

@Check_PrintString
        cmp #PRSTRING
        bne @Bad_Cmd

        jsr GetNextByte
        lda Char
        sta TempPrint
        jsr GetNextByte
        lda Char
        sta TempPrint + 1
        
        lda     TempPrint
        ldy     TempPrint + 1
        jsr     SAFE_STROUT
        jmp @CmdLoop

@Bad_Cmd
@Done
        rts

GetNextByte
        ldy #0
        lda (TXPTR),y
        sta Char
        INC16 TXPTR
        rts

PrintChar
        lda Char
        sta TEMP16
        lda #0
        sta TEMP16 + 1
        jsr PRINT_INT16_HEX
        rts

Char        .ds 1
Row         .ds 1
Col         .ds 1

TempPrint   .ds 10