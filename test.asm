; ==============================================================================
; PASM3 Comprehensive Test File
; ==============================================================================

    .macro Testm
    nop
    lda #\1
    sta \2
    .endm
    
    
; 1. Symbol Definitions (EQU) and formatting parsing
SCREEN_RAM = $0400         ; Hex assignment
BORDER_COL = $D020
SYS_COLOR  = 14            ; Decimal assignment
BIT_MASK   = %00001111     ; Binary assignment

; 2. PC Assignment (Org)
* = $C000

; 3. Standard Instructions & Immediate/Absolute Modes
START:
	bcc POINTERS + $1000

    sei                    ; Implied mode (testing lowercase)
    lda #SYS_COLOR         ; Immediate mode with symbol
    sta BORDER_COL         ; Absolute mode with symbol
    
    ; 4. Unary Prefix Expressions (< for Low Byte, > for High Byte)
    lda #<MESSAGE          ; Forward reference + Unary Low Byte
    ldx #>MESSAGE          ; Forward reference + Unary High Byte

    ldy #$00               ; Immediate mode with Hex

; 5. Labels & Relative Branching
LOOP:
    lda MESSAGE,y          ; Absolute, Y-indexed
    beq DONE               ; Relative branch (Forward reference)
    sta SCREEN_RAM,y       ; Absolute, Y-indexed
    iny                    ; Implied
    bne LOOP               ; Relative branch (Backward reference)
	bcc DONE
	beq LOOP-255		   ; out of range
	
DONE:
    cli                    
    rts                    

; 6. Data Directives & Binary Math Expressions
MESSAGE:
    ; .byte testing multiple comma-separated expressions
    .byte 72, 69, 76, 76, 79, 32, 87, 79, 82, 76, 68  ; "HELLO WORLD"
    .byte 0                                           ; Null terminator

POINTERS:
    ; .word testing binary arithmetic and precedence
    .word SCREEN_RAM + $1000 
    .word (SCREEN_RAM * 2) & $FFFF

    testm 50, Loop

	
