; ====================================================
; LookupSineTable
; ====================================================
; Input:  A = 8-bit angle index (0-255)
; Output: FIXPTR points directly to the 4-byte 16.16 value in SineTable
; Uses:   TEMP16 (2 bytes in ZP), FIXPTR ($FB-$FC)
; ====================================================
LookupSineTable:
        sta TEMP16        ; Store low byte of index
        lda #0
        sta TEMP16+1      ; TEMP16 now holds 16-bit index (0-255)
        
        ; Multiply index by 4 (since each fixed-point entry is 4 bytes)
        asl TEMP16
        rol TEMP16+1
        asl TEMP16
        rol TEMP16+1      ; TEMP16 now holds index * 4 (0-1020)
        
        ; Add base address of SineTable
        clc
        lda TEMP16
        adc #<SineTable
        sta FIXPTR
        lda TEMP16+1
        adc #>SineTable
        sta FIXPTR+1
        
        rts