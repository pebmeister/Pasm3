            GETIN   = $F13E
            CHRIN   = $F157
            CHROUT  = $FFD2

            BORDER  = $D020
            SCREENC = $D021

            PLOT    = $E50A
            STROUT  = $AB1E


            .basic_hdr
            
            lda     #$36
            sta     $01                 ; Configure C64 memory banking:
            
            lda     #COLOR_GREEN
            sta     BORDER
            sta     SCREENC

            lda     #1                  ; Do this so it wont already think its text mode
            sta     GrahicsMode    
            jsr     SwitchToText        ; Switch to Text
            
            MOVE16I TXPTR, @PG_START
            jsr     DisplayPage            

            jsr     RunTests

            MOVE16I TXPTR, @PG_RESULTS
            jsr     DisplayPage           
@Done
            jmp     @Done
            
@PG_START:
            .byte   BRD_C, COLOR_BLUE
            .byte   SCR_C, COLOR_BLUE
            .byte   CLS
            .byte   SETPOS, 0, 0
            .byte   STRING, KEY_WHITE, " RUNNING TESTS", 0
            .byte   NEXTROW
            .byte   ENDPAGE

RESULT_COL  = 15

@PG_RESULTS:
            .byte   SETPOS, 0, 0
            .byte   STRING, KEY_WHITE, " TEST RESULTS ", 0
            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_YELLOW, " MAT4MUL", KEY_WHITE, 0
            .byte   TAB, RESULT_COL
            .byte   STRING_VAR
            .word   Mat4MulTestResult

            .byte   NEXTROW
            .byte   STRING, KEY_YELLOW, " DIV", KEY_WHITE, 0
            .byte   TAB, RESULT_COL
            .byte   STRING_VAR
            .word   DivTestResult

            .byte   NEXTROW
            .byte   STRING, KEY_YELLOW, " VEC3MAT4", KEY_WHITE, 0
            .byte   TAB, RESULT_COL
            .byte   STRING_VAR
            .word   Vec3Mat4TestResult


            .byte   ENDPAGE
            
            
            
            
            
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
            lda     GrahicsMode
            bne     @Continue
            rts

@Continue
            lda     #0
            sta     GrahicsMode
            
            lda     Border
            sta     BorderSV
            
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
            lda     GrahicsMode
            beq     @Continue
            rts
@Continue
            lda     #1
            sta     GrahicsMode

            lda     BorderSV
            sta     Border

            lda     #HGR_BANK
            jsr     BankSelect

            lda     #HGR_SRC_RAM        ; Screen Ram
            ldy     #HGR_BITMAP_SLOT    ; Bitmap
            ldx     #VIC_MODE_BITMAP
            jsr     SetVICSlots

            jsr     HGRInit
            jmp     HGROn

BorderSV  
            .ds  1
GrahicsMode
            .ds 1
            
            
            
DisplayVec3Mat4
            MOVE16I TXPTR, @PG_RESULTS
            jsr     DisplayPage    
            rts
@PG_RESULTS
            .byte   BRD_C, COLOR_RED
            .byte   SCR_C, COLOR_RED
            .byte   CLS
            .byte   SETPOS, 0, 0
            .byte   STRING, KEY_WHITE, " VEC3MAT4 ERROR", 0
            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "EXPECTED", 0
            .byte   NEXTROW
            .byte   INT16_HEX_I
            .word   RunVec3Mat4Test@TEST_VEC3_EXP
            .byte   ENDPAGE
            
            
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 0
            .byte   SPC
            .byte   ENDPAGE

            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 1
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 2
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 3

            .byte   NEXTROW
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 4
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 5
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 6
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 7
            .byte   NEXTROW
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 8
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 9
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 10
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_EXP + 11
            .byte   NEXTROW
            .byte   NEXTROW
            .byte   NEXTROW
            .byte   STRING, KEY_WHITE, "ACTUAL", 0
            .byte   NEXTROW
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 0
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 1
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 2
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 3
            .byte   NEXTROW
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 4
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 5
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 6
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 7
            .byte   NEXTROW
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 8
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 9
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 10
            .byte   SPC
            .byte   INT8_HEX
            .word   RunVec3Mat4Test@TEST_VEC3_OUT + 11
            .byte   NEXTROW

            .byte   ENDPAGE


