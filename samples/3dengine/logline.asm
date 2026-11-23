BUFSZ   = 512

LogLine
        lda Full
        beq @Continue

@Continue        
        Add16I  LogSize, LogBuffer, LOC
        ldy #0

        ; Log X0
        lda X0
        sta (LOC),y
        INC16 LOC
        lda X0 + 1
        sta (LOC),y
        INC16 LOC
        
        ; Log Y0
        lda Y0
        sta (LOC),y
        INC16 LOC

        ; Log X1
        lda X1
        sta (LOC),y
        INC16 LOC
        lda X1 + 1
        sta (LOC),y
        INC16 LOC

        ; Log Y1
        lda Y1
        sta (LOC),y
        INC16 LOC
        
        INC16 Entries
        ADD16I LogSize, 6, LogSize
        
        BLT16I Entries, BUFSZ / 6, @NotFull
        lda #1
        sta Full
        
@NotFull     
        rts

Full
       .byte 0
Entries
    .word 0
    
LogSize
    .word 0
     
LogBuffer
    .ds BUFSZ
