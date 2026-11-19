; ====================================================
; 3D Rotation
; written by Paul Baxter using Pasm3
; https://github.com/pebmeister/Pasm3.git
; ====================================================

            .basic_hdr

            lda     #$36
            sta     $01                 ; Configure C64 memory banking:
            ; LORAM=0, HIRAM=1, CHAREN=1
            ; BASIC ROM disabled, KERNAL and I/O enabled.                       

            jsr     SwitchToHGR         ; Turn on graphics memory

            lda     #COLOR_BLACK
            jsr     _HGRFColor
            lda     #COLOR_YELLOW
            jsr     _HGRBColor
            sta     Border

            jsr     HGRCls
            jsr     ClearColor

            jsr     Reset
            jsr     Load_Cube

            ; jsr Debug

            jsr     Draw

MainLoop:
            jsr     GETIN
            beq     MainLoop
            jsr     ProcessKey
            jsr     Draw
            jmp     MainLoop

            TXT_BANK = 0
            TXT_SCR_RAM = 1
            HGR_BANK = 2
            HGR_SRC_RAM = 0
            HGR_BITMAP_SLOT = 1

            ; ************************************
            ;
            ; SwitchToText
            ;
            ; ************************************
SwitchToText:
            ; $0400–$07E7 Text screen (1000 bytes)
            lda     #TXT_BANK
            jsr     BankSelect

            lda     #TXT_SCR_RAM        ; Screen Ram
            ldx     #VIC_MODE_TEXT
            jsr     SetVICSlots

            jsr     HGROff              ; Turn off bitmap mode ($D011 bit 5 = 0)
            jmp     CLEARSCREEN         ; Clear the text buffer

            ; ************************************
            ;
            ; SwitchToHGR
            ;
            ; ************************************
SwitchToHGR:
            lda     #HGR_BANK
            jsr     BankSelect

            lda     #HGR_SRC_RAM        ; Screen Ram
            ldy     #HGR_BITMAP_SLOT    ; Bitmap
            ldx     #VIC_MODE_BITMAP
            jsr     SetVICSlots

            jsr     HGRInit
            jmp     HGROn
