; https://www.youtube.com/watch?v=KWydVEX0n3g

; ============================================
; C64 VIC-II COLOR EQUATES
; ============================================
COLOR_BLACK       = 0
COLOR_WHITE       = 1
COLOR_RED         = 2
COLOR_CYAN        = 3
COLOR_PURPLE      = 4
COLOR_GREEN       = 5
COLOR_BLUE        = 6
COLOR_YELLOW      = 7
COLOR_ORANGE      = 8
COLOR_BROWN       = 9
COLOR_LIGHT_RED   = 10
COLOR_DARK_GREY   = 11    ; Also known as Grey 1
COLOR_MEDIUM_GREY = 12    ; Also known as Grey 2
COLOR_LIGHT_GREEN = 13
COLOR_LIGHT_BLUE  = 14
COLOR_LIGHT_GREY  = 15    ; Also known as Grey 3

         ; written by Paul Baxter

BITMAPBASE
        .ds 2

COLORBASE
        .ds 2

;********************************************
;*                                          *
;*  BankSelect                              *
;*                                          *
;*  A IN: VIC-II bank number 0-3            *
;*                                          *
;********************************************
BankSelect
        and #%00000011
        eor #%00000011
        sta TMP

        lda $DD00
        and #%11111100
        ora TMP
        sta $DD00
        rts
        
;********************************************
;* SetHGRLayout                             *
;*                                          *
;* Configures VIC-II register $D018         *
;*                                          *
;* IN:                                      *
;*   A reg = Screen RAM slot (0-15)         *
;*           0=$0000, 1=$0400 ... 8=$2000   *
;*   Y reg = Bitmap slot (0 or 1)           *
;*           0=$0000, 1=$2000               *
;*                                          *
;* OUT:                                     *
;*   $D018 programmed with combined value   *
;********************************************
SetHGRLayout:
        ; Shift Screen RAM slot (0-15) into bits 7-4
        asl
        asl
        asl
        asl
        sta TMP             ; Save temporary shifted Screen RAM value

        ; Align Bitmap slot (0 or 1) into bit 3
        tya
        and #%00000001
        asl
        asl
        asl                 ; Shift to bit 3 ($00 or $08)

        ; Combine and store in $D018
        ora TMP
        sta $D018
        rts

;********************************************
;* InitVICPointers                          *
;*                                          *
;* Reads $DD00 and $D018 to calculate the   *
;* 16-bit base addresses for BITMAPBASE     *
;* and COLORBASE.                           *
;********************************************
InitVICPointers:
        ; Clear low bytes (both base addresses are always 1KB/8KB aligned)
        lda #0
        sta BITMAPBASE
        sta COLORBASE

        ; -------------------------------------------
        ; 1. Calculate Bank High Byte ($00, $40, $80, $C0)
        ; -------------------------------------------
        lda $DD00
        and #%00000011          ; Extract bank bits (1,0)
        eor #%00000011          ; Invert (%11->0, %10->1, %01->2, %00->3)
        asl
        asl
        asl
        asl
        asl
        asl                     ; Shift to high byte bits (Bank * $40)
        sta BITMAPBASE + 1
        sta COLORBASE + 1

        ; -------------------------------------------
        ; 2. Calculate BITMAPBASE High Byte
        ; -------------------------------------------
        lda $D018
        and #%00001000          ; Extract Bit 3 (0 = $0000 offset, 1 = $2000 offset)
        asl
        asl                     ; Shift into bit 5 position ($20 offset)
        ora BITMAPBASE + 1
        sta BITMAPBASE + 1

        ; -------------------------------------------
        ; 3. Calculate COLORBASE High Byte
        ; -------------------------------------------
        lda $D018
        and #%11100000          ; Extract Screen RAM bits (7-5)
        lsr
        lsr                     ; Shift bits 7-5 down to bits 5-3 ($00, $04, $08... $38)
        ora COLORBASE + 1
        sta COLORBASE + 1

        rts
        
 HGRInit
        jsr InitVICPointers
        jsr InitBitmapScanlineTables
        jsr PatchHGRCls
        rts

;********************************************
;*                                          *
;*  HGROn                                   *
;*                                          *
;* User should call BankSelect and          *

;*                                          *
;********************************************
HGROn        
        lda $D011
        ora #%00100000
        sta $D011  
        rts

;********************************************
;*                                          *
;*  HGROff                                  *
;*  Restore Standard Text Mode & Bank 0     *
;*                                          *
;********************************************
HGROff
        ; 1. Turn off High-Resolution Bitmap Mode ($D011 bit 5 = 0)
        lda $D011
        and #%11011111
        sta $D011
        rts

;********************************************
;* HGRCls                                   *
;* Clear graphics bitmap (8000 bytes)       *
;*                                          *
;* High bytes of STA addresses are patched  *
;* by PatchHGRCls when the VIC bank changes.*
;********************************************
HGRCls
        ldx #0
        lda #0

@ClrLoop
        sta $4000,x
        sta $4100,x
        sta $4200,x
        sta $4300,x
        sta $4400,x
        sta $4500,x
        sta $4600,x
        sta $4700,x
        sta $4800,x
        sta $4900,x
        sta $4A00,x
        sta $4B00,x
        sta $4C00,x
        sta $4D00,x
        sta $4E00,x
        sta $4F00,x
        sta $5000,x
        sta $5100,x
        sta $5200,x
        sta $5300,x
        sta $5400,x
        sta $5500,x
        sta $5600,x
        sta $5700,x
        sta $5800,x
        sta $5900,x
        sta $5A00,x
        sta $5B00,x
        sta $5C00,x
        sta $5D00,x
        sta $5E00,x
        sta $5F00,x

        inx
        bne @ClrLoop

@ClrLoop2
        sta $5F00,x
        inx
        cpx #8000 - ($0100 * 31)
        bne @ClrLoop2

.ifdef USE_COLOR
        jmp ClearColor
.endif        
        rts

;********************************************
;* PatchHGRCls                              *
;* Patch the bitmap high-byte operands in   *
;* HGRCls for the current BITMAPBASE.       *
;********************************************
PatchHGRCls
        .var PATCH_INDEX = 0
        .var PATCH_VALUE = BITMAPBASE
        .var ADDR = HGRCls@ClrLoop + 1
        .while PATCH_INDEX < 32
            MOVE16 ADDR, TMP
            lda #<PATCH_VALUE
            ldy #0
            sta (TMP),y
            iny
            lda #>PATCH_VALUE
            sta (TMP),y
            PATCH_VALUE = PATCH_VALUE + $100
            ADDR = ADDR + 3
            PATCH_INDEX = PATCH_INDEX + 1
        .wend
        ADDR = HGRCls@ClrLoop2 + 1
        MOVE16 ADDR, TMP
        lda #<PATCH_VALUE
        ldy #0
        sta (TMP),y
        iny
        lda #>PATCH_VALUE
        sta (TMP),y
    
        rts

;********************************************
;* ClearColor                               *
;* Clear color memory (1000 bytes)          *
;* using dynamic COLORBASE pointer          *
;********************************************
ClearColor:
        ; Copy COLORBASE to COLORPTR for indirect clearing
        MOVE16 COLORBASE, COLORPTR
        
        ldx #3              ; 3 full pages (3 * 256 = 768 bytes)
        ldy #0
        lda COLOR           ; Fill with current color attribute
@ColorPages:
        sta (COLORPTR),y
        iny
        bne @ColorPages
        inc COLORPTR + 1    ; Move to next page high byte
        dex
        bne @ColorPages
        
        ; Clear remaining 232 bytes (1000 - 768 = 232)
        ldy #0
@ColorRemainder:
        sta (COLORPTR),y
        iny
        cpy #232
        bne @ColorRemainder
        rts

;********************************************
;*                                          *
;*  HGRBColor                               *
;*     Set HGR Background COLOR             *
;*                                          *
;* ---------------------------------------- *
;*        PAGE ZERO USAGE                   *
;* ---------------------------------------- *
;*  TMP     = UNUSED2 + 2       1 byte      *
;*  COLOR   = CMP0              1 byte      *
;* ---------------------------------------- *
;********************************************
_HGRBColor
        and #$0F
        sta TMP
        lda COLOR
        and #$F0
        ora TMP
        sta COLOR
        rts

;********************************************
;*                                          *
;*  _HGRFColor                              *
;*     Set HGR Forground COLOR              *
;*                                          *
;* ---------------------------------------- *
;*        PAGE ZERO USAGE                   *
;* ---------------------------------------- *
;*  TMP     = 1 byte                        *
;*  COLOR   = 1 byte                        *
;* ---------------------------------------- *
;********************************************
_HGRFColor
        and #$0F
        asl
        asl
        asl
        asl
        sta TMP

        lda COLOR
        and #$0F
        ora TMP
        sta COLOR
        rts

;********************************************
;*                                          *
;*  _Plot                                   *
;*       XCOORD     IN  2 byte x coordinate *
;*       X register IN  y coordinate        *
;*                                          *
;* Plot a single point                      *
;*                                          *
;* ---------------------------------------- *
;*        PAGE ZERO USAGE                   *
;* ---------------------------------------- *
;*  LOC                                     *
;*  COLOR                                   *
;*  YCOL                                    *
;*  COLORPTR                                *
;*  XCOORD                                  *
;* ---------------------------------------- *
;*        CALLS                             *
;* ---------------------------------------- *
;*   CalcPlot                               *
;*   CalcColorByte                          *
;* ---------------------------------------- *
;********************************************
_Plot
        stx YCOL
        MOVE16 XCOORD, COLORPTR

        ; Calc Bitmap location
        jsr CalcPlot
        ldy #0
        lda (LOC),y
        ora MaskStart,x
        sta (LOC),y

.ifdef USE_COLOR
        ; Calc color map location
        jsr CalcColorByte
        lda COLOR
        ldy #0
        sta (COLORPTR),y
.endif
        ;rts

.ifdef USE_COLOR
;********************************************
;*                                          *
;* CalcColorByte                            *
;*                                          *
;* COLORPTR = x location (in pixels)        *
;* YCOL = y location (0-199)                *
;*                                          *
;* OUT:                                     *
;* COLORPTR = Absolute address of color byte*
;*                                          *
;-------------------------------------------*
;*          PAGE ZERO USAGE                 *
;-------------------------------------------*
;* YCOL         = PTR1        2 bytes       *
;* COLORPTR     = TMPDATA     2 bytes       *
;********************************************
CalcColorByte:
        ; YCOL holds the Y coordinate (0-199). Zero out its high byte.
        lda #0
        sta YCOL + 1

        ; Convert X coordinate to character column: COLORPTR = X / 8
        RSHIFT16 COLORPTR, 3

        ; Convert Y coordinate to character row offset: 
        ; row = int(y / 8) * 40
        RSHIFT16 YCOL, 3
        MULT40 YCOL

        ; Add row offset to column offset: COLORPTR = (X / 8) + (row offset)
        ADD16 COLORPTR, YCOL, COLORPTR

        ; Add dynamic COLORBASE pointer to get the final absolute RAM address
        ADD16 COLORPTR, COLORBASE, COLORPTR
        rts
.endif     

;********************************************
;*                                          *
;*  CalcPlot                                *
;*      XCOORD IN  2 byte x coordinate      *
;*      X reg  IN  y coordinate             *
;*                                          *
;*      LOC    OUT  byte of bitmap          *
;*      X reg  OUT  bit of bitmap           *
;*                                          *
;--------------------------------------------*
;*      PAGE ZERO USAGE                     *
;--------------------------------------------*
;*  LOC         = UNUSED2    2 byte         *
;*  XCOORD      = LINNUM     2 bytes        *
;*  TMP         = UNUSED2 + 2  2 bytes      *
;********************************************
CalcPlot:
        ; 1. Fetch scanline base address using Y (in X register)
        lda BITMAP_SCANLINE_LO, x
        sta LOC
        lda BITMAP_SCANLINE_HI, x
        sta LOC + 1

        ; 2. Add horizontal byte offset: (XCOORD & 0xFFF8)
        lda XCOORD
        and #%11111000
        clc
        adc LOC
        sta LOC
        lda XCOORD + 1
        adc LOC + 1
        sta LOC + 1

        ; 3. Calculate bit index: 7 - (XCOORD & 7) [optimized via EOR #7]
        lda XCOORD
        and #%00000111
        eor #%00000111
        tax
        rts
                
; ============================================
; CLAMP_LINE_COORDS
; Clamps X0, X1 to screen range 0-319 ($013F)
; Clamps Y0, Y1 to screen range 0-199 ($C7)
; ============================================
CLAMP_LINE_COORDS
        ; --- Clamp X0 ---
        lda X0 + 1
        bmi @clamp_x0_zero
        beq @clamp_y0
        cmp #1
        bne @clamp_x0_max
        lda X0
        cmp #$40
        bcc @clamp_y0
@clamp_x0_max
        lda #<319
        sta X0
        lda #>319
        sta X0 + 1
        jmp @clamp_y0
@clamp_x0_zero
        lda #0
        sta X0
        sta X0 + 1

@clamp_y0
        ; --- Clamp Y0 (unsigned 0-199) ---
        lda Y0
        cmp #200
        bcc @clamp_x1
        lda #199
        sta Y0

@clamp_x1
        ; --- Clamp X1 ---
        lda X1 + 1
        bmi @clamp_x1_zero
        beq @clamp_y1
        cmp #1
        bne @clamp_x1_max
        lda X1
        cmp #$40
        bcc @clamp_y1
@clamp_x1_max
        lda #<319
        sta X1
        lda #>319
        sta X1 + 1
        jmp @clamp_y1
@clamp_x1_zero
        lda #0
        sta X1
        sta X1 + 1

@clamp_y1
        ; --- Clamp Y1 ---
        lda Y1
        cmp #200
        bcc @clamp_done
        lda #199
        sta Y1
        jmp @clamp_done
@clamp_y1_zero
        lda #0
        sta Y1

@clamp_done
        rts

;********************************************
;*                                          *
;* _Line                                    *
;*                                          *
;*    X0 - start X                          *
;*    Y0 - start Y                          *
;*    X1 - end X                            *
;*    Y1 - end Y                            *
;*                                          *
;*    optimized for horizontal lines        *
;*                                          *
;* ---------------------------------------- *
;*        PAGE ZERO USAGE                   *
;* ---------------------------------------- *
;*  X0                          2 bytes     *
;*  Y0                          1 byte      *
;*  X1                          2 bytes     *
;*  Y1                          1 byte      *
;*  XDIST                       2 bytes     *
;* ---------------------------------------- *
;********************************************
        ; asm entry point
 _Line
        jsr CLAMP_LINE_COORDS
       
        lda Y0
        cmp Y1
        bne NotHorizontal

;---------------------------------------
        BLE16 X0, X1, @X0_Less_Equal
;---------------------------------------
; Swap X0, Y0 and X1, Y1
        SWAP16 X0, X1
        ldx Y0
        ldy Y1
        stx Y1
        sty Y0

;---------------------------------------
;
; At this point X0 MUST be less than X1!!!
;
;---------------------------------------

@X0_Less_Equal
        MOVE16 X0,XCOORD
        SUB16 X1, X0, XDIST

;---------------------------------------
        MOVE16 XCOORD, COLORPTR
        MOVE8 Y0, YCOL
        ldx Y0

        ; Calculate 1st byte and bit of BitMap
        jsr CalcPlot
        MOVE16 LOC, CURLOC

        ; Draw the horizontal Line
        jsr HGRHorizontalLine

        ; Set the Lines color memory
        ; jmp HCPlotLine
        rts
        
;---------------------------------------

NotHorizontal
        MOVE8I DY+1, 0

        ; DX% = abs(x0%-x1%)
        ; set XS to add or substract
        ;
        BLT16 X0, X1, @X1_larger

;-------------------------------------------

        SUB16 X0, X1, DX
        lda #1
        bne @Calc_DY

@X1_larger
        SUB16 X1, X0, DX
        lda #0
@Calc_DY
        sta XS

;-------------------------------------------

        ; DY = abs(y0% - y1%)
        ; set YS to add or subtract
        lda Y0
        cmp Y1
        bcc @Y1_larger

        SUB8 Y0, Y1, DY
        lda #1
        bne @Done_calc

@Y1_larger
        SUB8 Y1, Y0, DY
        lda #0
@Done_calc
        sta YS

;-------------------------------------------

        ; y is 8 bit so if this is not 0 its larger
        lda DX + 1

        ; using reverse logic because branch is > 128
        beq @DX_DY_compare
        jmp @DX_larger

@DX_DY_compare
        lda DX
        cmp DY

        ; using reverse logic because branch is > 128
        bcc @DY_larger
        jmp @DX_larger

@DY_larger
        ; K1 = 2 * DX
        MOVE16 DX, K1
        LSHIFT16 K1, 1

        ; K2%=2*(DX%-DY%)
        SUB16 DX, DY, K2
        LSHIFT16 K2, 1

        ; d%=K1%-DY
        SUB16 K1, DY, _D

;-------------------------------------------

        ; y=y0%
        lda Y0
        sta _Y

        ; x = x0
        MOVE16 X0, _X

;-------------------------------------------
; for y=y0% to y1% step YS%

@Y_loop_start
        lda _Y
        cmp Y1

        bne @Y_loop_continue
        jmp @Exitline

@Y_loop_continue
        ; plot
        ldx _Y
        jsr _Plot

; -------------------------------------------

        ; if d%<0 then y_loop_d0_minus
        lda _D + 1
        bmi @Y_loop_d0_minus

        ; x = x + XS
        lda XS
        beq @Y_loop_X_inc

        DEC16 _X
        jmp  @Y_loop_add_d

@Y_loop_X_inc
        INC16 _X

@Y_loop_add_d
        ; d% = d% + K2%
        ADD16 _D, K2, _D
        jmp @Y_loop_next

; -------------------------------------------

@y_loop_d0_minus
        ; d%=d%+K1%
        ADD16 _D, K1, _D

; -------------------------------------------

@y_loop_next
        ; y = y + YS
        lda YS
        beq @Y_loop_next_inc

        DEC8 _Y
        jmp @Y_loop_start

@Y_loop_next_inc
        inc _Y
        jmp @Y_loop_start

; -------------------------------------------

@DX_larger
        ; K1 = 2 * DY
        MOVE16 DY, K1
        LSHIFT16 K1, 1

        ; K2%=2*(DY%-DX%)
        SUB16 DY, DX, K2
        LSHIFT16 K2, 1

        ; d%=K1%-DX
        SUB16 K1, DX, _D

; -------------------------------------------

        ; y=y0%
        lda Y0
        sta _Y

        ; x = x0
        MOVE16 X0, _X

;-------------------------------------------
; for x=x0% to x1% step XS%

@X_loop_start

        lda _X + 1
        cmp X1 + 1
        bne @X_loop_continue

        lda _X
        cmp X1
        bne @X_loop_continue

        jmp @Exitline

@X_loop_continue
        ; plot
        ldx _Y
        jsr _Plot

; -------------------------------------------

        ; if d%<0 then x_loop_d0_minus
        lda _D + 1
        bmi @X_loop_d0_minus

        ; y = y + YS
        lda YS
        beq @X_loop_Y_inc

        DEC8 _Y
        jmp  @X_loop_add_d

@X_loop_Y_inc
        inc _Y

@X_loop_add_d
        ; d% = d% + K2%
        ADD16 _D, K2, _D
        jmp @X_loop_next

@X_loop_d0_minus
        ; d%=d%+K1%
        ADD16 _D, K1, _D

; -------------------------------------------

@X_loop_next
        ; x = x + XS
        lda XS
        beq @x_loop_next_inc

        DEC16 _X
        jmp @X_loop_start

@X_loop_next_inc
        INC16 _X
        jmp @X_loop_start

; -------------------------------------------

@Exitline
        ldx _Y
        jmp _Plot

.ifdef USE_COLOR
;********************************************
;
;  HCPlotLine
;
; COLORPTR - X start
; XDIST    - X Distance
; YCOL     - Y Location
;
; Plot color memory line
;
;********************************************
HCPlotLine
        ; Save start, distance
        MOVE16 COLORPTR, StartX

        ; get the start byte
        jsr CalcColorByte

        ; check for XDIST > 8
        MOVE16 XDIST, XD
        lda XD + 1
        bne @Continue

        lda XD
        cmp #9
        bcc @LoopExit

@Continue
        INC16 XD

        lda StartX
        and #%00000111
        beq @InitLoop

; -------------------------------------------

        ; subtract 8 - N from XD

        sta TMP

        sec
        lda #8
        sbc TMP
        sta TMP
        SUB168 XD, TMP, XD

        ; set color Memory
        ldy #0
        lda COLOR
        sta (COLORPTR),y
        INC16 COLORPTR

; -------------------------------------------

        ; set y to 0
@InitLoop
        ldy #0
@Loop
        lda XD + 1  ; check that there is more to process
                    ; check high byte first
        bne @LoopContinue
        lda XD      ; check low byte is at least 8 pixels
        cmp #08
        bcc @LoopExit

; -------------------------------------------

@LoopContinue
        ; set color Memory
        lda COLOR
        sta (COLORPTR),y
        INC16 COLORPTR

        ; subtract 8 from distance
        SUB16I XD, 8, XD
        jmp @Loop

; -------------------------------------------

@LoopExit
        ; check for last byte
        lda XD
        beq @Exit

        ; set color Memory
        lda COLOR
        sta (COLORPTR),y
@Exit
        rts
.endif

;********************************************
;
;  HGRHorizontalLine
;
; CURLOC IN POINTER to bitmap byte
; XDIST IN x pixel distance
; X register IN bit in first byte of bitmap
;
;********************************************
HGRHorizontalLine
        ; If there are 8 bits to set then we can use bytes
        ; instead of using bits
        ;
        ; set the first potentially partial byte
        ; set x to number of bits in first byte
        lda XDIST + 1   ; load HI byte
        bne @HFirstByte ; if its not 0 then it > 8 bits
        cpx XDIST       ; see if bit is within distance
        bcc @HFirstByte ; yes so we leave x unmodified

;----------------------------------------------
; special case for < 8 pixels

@StartByte
        ldy #0
        lda (CURLOC),y
        ldy XDIST       ; set y to XDIST
        beq @StartExit
@StartByteLoop
        ora MaskStart,x
        dex
        dey
        bne @StartByteLoop
        sta (CURLOC),y
@StartExit
        rts

;----------------------------------------------

@HFirstByte
        stx  COUNTER    ; save in counter
        lda #0          ; zero out high byte
        sta COUNTER + 1

;----------------------------------------------

        ; subtract COUNTER from distance of first byte
        ; and save in COUNTER
        SUB16 XDIST, COUNTER, COUNTER

;----------------------------------------------

        ; Plot the first byte
        ldy #0
        lda (CURLOC),y
        ora MaskData,x
        sta (CURLOC),y

;----------------------------------------------
; Horizontal Line - Loop
; here we plot bytes instead of bits
;----------------------------------------------

@HLoop1
        ; test that there are at least 8 bits to plot
        lda COUNTER + 1 ; get the high byte
        bne @HLoop_Cont ; if its set there are more than 8 bits left
        lda COUNTER     ; load lo byte
        beq @HLoop1End
        cmp #8          ; compare it to 8
        beq @HLoop1End  ; if it is equal then go to the last byte
        bcs @HLoop_Cont ; continue if > 8
        jmp @HLoop1End  ; less than 8 go to last byte

; -------------------------------------------

@HLoop_Cont             ; add 8 to current pointer
        ADD16I CURLOC, 8, CURLOC
        lda #$FF        ; load a with FF
        sta (CURLOC),y  ; store the byte

                        ; Increment COUNTER by 8
        SUB16I COUNTER, 8, COUNTER
        jmp @HLoop1     ; goto to byte loop

; -------------------------------------------

@HLoop1End
        ldx COUNTER     ; see if there are bits left
        beq @HLoop1EXIT ; if no then exit

;----------------------------------------------
; Horizontal Lines Last Byte
;----------------------------------------------

        ADD16I CURLOC, 8, CURLOC
@HLastByte
        lda (CURLOC),y
        ora MaskDataEnd,x
        sta (CURLOC),y
@HLoop1EXIT
        rts

;----------------------------------------------

MaskStart
        .byte %00000001 ; 0
        .byte %00000010 ; 1
        .byte %00000100 ; 2
        .byte %00001000 ; 3
        .byte %00010000 ; 4
        .byte %00100000 ; 5
        .byte %01000000 ; 6
        .byte %10000000 ; 7

MaskData
        .byte %00000001 ; 0
        .byte %00000011 ; 1
        .byte %00000111 ; 2
        .byte %00001111 ; 3
        .byte %00011111 ; 4
        .byte %00111111 ; 5
        .byte %01111111 ; 6
        .byte %11111111 ; 7

MaskDataEnd
        .byte %00000000
        .byte %10000000 ; 1
        .byte %11000000 ; 2
        .byte %11100000 ; 3
        .byte %11110000 ; 4
        .byte %11111000 ; 5
        .byte %11111100 ; 6
        .byte %11111110 ; 7
        .byte %11111111 ; 8

; ============================================
; BITMAP SCANLINE LOOKUP TABLES (200 bytes each)
; ============================================
BITMAP_SCANLINE_LO:
        .ds 200

BITMAP_SCANLINE_HI:
        .ds 200

;********************************************
;* InitBitmapScanlineTables                 *
;*                                          *
;* Populates BITMAP_SCANLINE_LO and HI      *
;* tables dynamically for Y (0-199)         *
;* using BITMAPBASE and 16-bit macros       *
;********************************************
InitBitmapScanlineTables:
        ldx #0                  ; Y coordinate loop counter (0-199)

@InitLoop:
        stx TMP                 ; Save current Y value

        ; 1. Start with BITMAPBASE
        MOVE16 BITMAPBASE, LOC

        ; 2. Add (Y / 8) * 320 for the character row offset
        txa
        lsr
        lsr
        lsr                     ; A = character row (0-24)
        beq @AddFineY           ; If row 0, skip row addition
        sta TMP + 1             ; Use TMP+1 as row loop counter

@RowLoop:
        ADD16I LOC, 320, LOC
        dec TMP + 1
        bne @RowLoop

@AddFineY:
        ; 3. Add fine vertical offset within the character block (Y & 7)
        lda TMP                 ; Recover Y
        and #%00000111          ; Mask lower 3 bits
        sta TMP + 1             ; Store fine offset in TMP+1 memory

        clc
        lda LOC
        adc TMP + 1             ; Add fine offset to low byte
        sta LOC
        bcc @StoreTables
        inc LOC + 1             ; Handle carry into high byte if needed

@StoreTables:
        ; 4. Save low and high bytes into lookup tables at index Y (in X register)
        ldx TMP                 ; Restore Y index
        lda LOC
        sta BITMAP_SCANLINE_LO, x
        lda LOC + 1
        sta BITMAP_SCANLINE_HI, x

        inx
        cpx #200
        bne @InitLoop
        rts
        