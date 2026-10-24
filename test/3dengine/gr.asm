; ====================================================
; BANK 1 GRAPHICS CONFIGURATION
; ====================================================
BITMAPBASE  = $4000
COLORBASE   = $6000

;********************************************
;*                                          *
;*  HGROn                                   *
;*  Enter High-Res Bitmap Mode in Bank 1    *
;*                                          *
;********************************************
HGROn
        ; 1. Set VIC Bank to Bank 1 ($4000-$7FFF) via CIA 2 ($DD00)
        ; Bits 1,0 = %10 (Inverted address lines A15=0, A14=1)
        lda $DD00
        and #%11111000      
        ora #%00000010      
        sta $DD00

        ; 2. Set Screen RAM to $6000 (bits 7-4 = %1000 -> offset $2000)
        ; and Bitmap to $4000 (bit 3 = 0 -> offset $0000)
        ; Combined $D018 value: %10000000 ($80)
        lda #%10000000
        sta $D018

        ; 3. Turn on High-Resolution Bitmap Mode ($D011 bit 5 = 1)
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

        ; 2. Restore default text screen ($0400) and character ROM pointers ($D018 = $14)
        lda #$14
        sta $D018

        ; 3. Restore VIC Bank to Bank 0 ($0000-$3FFF) via CIA 2 ($DD00)
        ; Bits 1,0 = %11
        lda $DD00
        ora #%00000011
        sta $DD00
        rts
        
;********************************************
;*                                          *
;*  HGRCLS                                  *
;*                                          *
;*  Clear graphics bitmap and colors        *
;*                                          *
;* ---------------------------------------- *
;*        CALLS                             *
;* ---------------------------------------- *
;*  ClearColor                              *
;* ---------------------------------------- *
;********************************************
HGRCls
        ldx #0
        lda #0
@_ClrLoop
        sta BITMAPBASE + ($0100 * 0),x
        sta BITMAPBASE + ($0100 * 1),x
        sta BITMAPBASE + ($0100 * 2),x
        sta BITMAPBASE + ($0100 * 3),x
        sta BITMAPBASE + ($0100 * 4),x
        sta BITMAPBASE + ($0100 * 5),x
        sta BITMAPBASE + ($0100 * 6),x
        sta BITMAPBASE + ($0100 * 7),x
        sta BITMAPBASE + ($0100 * 8),x
        sta BITMAPBASE + ($0100 * 9),x
        sta BITMAPBASE + ($0100 * 10),x
        sta BITMAPBASE + ($0100 * 11),x
        sta BITMAPBASE + ($0100 * 12),x
        sta BITMAPBASE + ($0100 * 13),x
        sta BITMAPBASE + ($0100 * 14),x
        sta BITMAPBASE + ($0100 * 15),x
        sta BITMAPBASE + ($0100 * 16),x
        sta BITMAPBASE + ($0100 * 17),x
        sta BITMAPBASE + ($0100 * 18),x
        sta BITMAPBASE + ($0100 * 19),x
        sta BITMAPBASE + ($0100 * 20),x
        sta BITMAPBASE + ($0100 * 21),x
        sta BITMAPBASE + ($0100 * 22),x
        sta BITMAPBASE + ($0100 * 23),x
        sta BITMAPBASE + ($0100 * 24),x
        sta BITMAPBASE + ($0100 * 25),x
        sta BITMAPBASE + ($0100 * 26),x
        sta BITMAPBASE + ($0100 * 27),x
        sta BITMAPBASE + ($0100 * 28),x
        sta BITMAPBASE + ($0100 * 29),x
        sta BITMAPBASE + ($0100 * 30),x
        inx
        bne @_ClrLoop
@_ClrLoop2
        sta BITMAPBASE + ($0100 * 31),x
        inx
        cpx #8000 -($0100 * 31)
        bne @_ClrLoop2

        jmp ClearColor

;********************************************
;*                                          *
;*  _HGRBColor                              *
;*     Set HGR Background COLOR             *
;*                                          *
;*       A     IN  color for background     *
;* ---------------------------------------- *
;*        PAGE ZERO USAGE                   *
;* ---------------------------------------- *
;*  TMP     = 1 byte                        *
;*  COLOR   = 1 byte                        *
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
;*  HGRFColor                               *
;*     Set HGR Forground COLOR              *
;*                                          *
;*       A     IN  color for foreground     *
;* ---------------------------------------- *
;*        PAGE ZERO USAGE                   *
;* ---------------------------------------- *
;*  TMP     1 byte                          *
;* ---------------------------------------- *
;*        VAR USAGE                         *
;* ---------------------------------------- *
;*  COLOR   1 byte                          *
;* ---------------------------------------- *
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
;*  ClearColor                              *
;*     clear Color memory                   *
;*                                          *
;* ---------------------------------------- *
;*        VAR USAGE                         *
;* ---------------------------------------- *
;*  COLOR   1 byte                          *
;* ---------------------------------------- *
;********************************************
ClearColor
        lda COLOR
        ldx #0
@Clear3
        sta COLORBASE + ($0100 * 0),x
        sta COLORBASE + ($0100 * 1),x
        sta COLORBASE + ($0100 * 2),x
        inx
        bne @Clear3
@Clear4
        sta COLORBASE + ($0100 * 3),x
        inx
        cpx #1000-3*255
        bne @Clear4
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
;*  LOC         = UNUSED2                   *
;*  COLOR       = CMP0                      *
;*  YCOL        = PTR1                      *
;*  COLORPTR    = TMPDATA                   *
;*  XCOORD      = LINNUM                    *
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

        ; Calc color map location
        jsr CalcColorByte
        lda COLOR
        ldy #0
        sta (COLORPTR),y
        rts

;********************************************
;*                                          *
;* CalcColorByte                            *
;*                                          *
;* COLORPTR = x location                    *
;* YCOL = y location                        *
;*                                          *
;* ---------------------------------------- *
;*        PAGE ZERO USAGE                   *
;* ---------------------------------------- *
;*  YCOL        2 bytes                     *
;*  COLORPTR    2 bytes                     *
;* ---------------------------------------- *
;********************************************
CalcColorByte
        ; YCOL + 0 has y value
        ; zero out high byte
        lda #0
        sta YCOL + 1
        RSHIFT16 COLORPTR, 3  ; COLORPTR = x / 8
        RSHIFT16 YCOL, 3      ; ycol int(y/8)*40
        MULT40 YCOL

        ; COLORPTR = COLORPTR + ycol
        ADD16 COLORPTR, YCOL, COLORPTR

        ; COLORPTR = COLORPTR + COLORBASE
        ADD16I COLORPTR, COLORBASE, COLORPTR
        rts

;********************************************
;*                                          *
;*  CalcPlot                                *
;*      XCOORD IN  2 byte x coordinate      *
;*      X reg  IN  y coordinate             *
;*                                          *
;*      LOC    OUT  byte of bitmap          *
;*      X reg  OUT  bit of bitmap           *
;*                                          *
;* ---------------------------------------- *
;*        PAGE ZERO USAGE                   *
;* ---------------------------------------- *
;*  LOC         2 byte                      *
;*  XCOORD      2 bytes                     *
;*  TMP         2 bytes                     *
;********************************************
CalcPlot
; 320*int(y/8)=32*[8*int(y/8)] + 8*[8*int(y/8)]
        lda #0
        sta LOC
        txa             ; X register has Y coordinate
        lsr
        lsr
        lsr
        sta LOC + 1     ; high-byte of 32*8*int(y/8)

;-------------------------------------------------

        lsr
        ror LOC
        lsr
        ror LOC         ; low byte of 8*[8*int(y/8)]

;-------------------------------------------------

        adc LOC + 1
        adc #>BITMAPBASE
        sta LOC+1       ; high byte of memory=BITMAPBASE + 320*int(y/8)

;-------------------------------------------------

        lda XCOORD
        and #%11111000  ; 8*int(x/8)
        adc LOC
        sta LOC         ; set address memory block of bytes

;-----------------------------------------------

        lda XCOORD + 1
        adc LOC + 1
        sta LOC + 1

;-----------------------------------------------

        txa
        and #%00000111 ; int(y/7), byte offset inside bLOCk
        tay

;-----------------------------------------------

        lda XCOORD
        and #%00000111 ; int(x/7), bit inside byte
        tax

;-----------------------------------------------

        ; add y to LOC
        sty TMP
        lda #0
        sta TMP + 1
        ADD16 TMP, LOC, LOC

;-----------------------------------------------

        ; given: x (0 - 7)
        ; x = 7 - x
        MOVE8I TMP, 7
        stx TMP + 1
        SUB8 TMP, TMP + 1, TMP
        ldx TMP
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
;*  X0           = FORPNT     2 bytes       *
;*  Y0           = PRTY       1 byte        *
;*  X1           = OPPTR      2 bytes       *
;*  Y1           = MSGFLG     1 byte        *
;*  XDIST        = INDEX      2 bytes       *
;* ---------------------------------------- *
;********************************************
        ; asm entry point
        _Line = *
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
CalcPlotHLine
        MOVE16 XCOORD, COLORPTR
        MOVE8 Y0, YCOL
        ldx Y0

        ; Calculate 1st byte and bit of BitMap
        jsr CalcPlot
        MOVE16 LOC, CURLOC

        ; Draw the horizontal Line
        jsr HGRHorizontalLine

        ; Set the Lines color memory
        jmp HCPlotLine

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


RangeCheckXY
        cpx # 200
        bcs RangeError

        lda XCOORD + 1
        beq @Exit
        cmp #2
        bcs RangeError


        lda XCOORD
        cmp # 320 - 256
        bcs RangeError
@Exit
        rts
RangeError
        ldx # ILLEGALQUANITY
        jmp ERROR

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

