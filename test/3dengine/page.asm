SETPOS     = 1
NEXTROW    = 2
PRSTRING   = 3

ENDPAGE     = $FF

DisplayPage

@CmdLoop
        jsr @GetNextByte
        lda @Char
        
        ; check for done first
        cmp #ENDPAGE
        beq @Done

        cmp #SETPOS
        bne @Check_NextRow

; SetPos
        jsr @GetNextByte
        lda @Char
        sta @Row
        jsr @GetNextByte
        ldy @Char
        ldx @Row
        ldy @Col
        clc
        jsr PLOT

        jmp @CmdLoop

@Check_NextRow
        cmp #NEXTROW
        bne @Check_PrintString

; NextRow
        inc @Row
        ldx @Row
        ldy #$00
        clc
        jsr PLOT

        jmp @CmdLoop

@Check_PrintString
        cmp #NEXTROW
        bne @Bad_Cmd

; PrintString
        lda TXPTR
        ldy TXPTR + 1
        jsr SAFE_STROUT
@Char_Loop
        jsr GetNextByte
        lda @Char
        bne @Char_Loop
  
        jmp @CmdLoop

@Bad_Cmd
@Done
        rts

GetNextByte
        ldy #0
        lda (TXPTR),y
        sta @Char
        INC16 TXPTR
        rts

PrintChar
        lda @Char
        sta TEMP16
        lda #0
        sta TEMP16 + 1
        jsr PRINT_INT16_HEX
        rts

@Char        .ds 1
@Row         .ds 1

@TempPrint   .ds 10
