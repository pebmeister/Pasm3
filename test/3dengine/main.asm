; ====================================================
; 3D Rotation
; written by Paul Baxter using Pasm3
; https://github.com/pebmeister/Pasm3.git
; ====================================================

        .basic_hdr
        lda #$36
        sta $01             ; Configure C64 memory banking:
                            ; LORAM=0, HIRAM=1, CHAREN=1
                            ; BASIC ROM disabled, KERNAL and I/O enabled.                       

        jsr SwitchToHGR     ; Turn on graphics memory
                            
        lda #COLOR_BLACK
        jsr _HGRFColor
        lda #COLOR_YELLOW
        jsr _HGRBColor
        sta Border

        jsr HGRCls
        jsr ClearColor

        jsr Reset
        jsr Load_Cube

        ; jsr Debug

        jsr Draw
        
MainLoop:
        jsr GETIN
        beq MainLoop
        jsr ProcessKey
        jsr Draw
        jmp MainLoop
        