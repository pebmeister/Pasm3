.print push
.print off

;********************************************
;* PUSH16                                   *
;* Push 16-bit value                        *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro PUSH16
        lda \1
        pha
        lda \1 + 1
        pha
        .endm

;********************************************
;* POP16                                    *
;* Pop 16-bit value                         *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro POP16
        pla
        sta \1 + 1
        pla
        sta \1
        .endm

;********************************************
;* STORE8                                   *
;* Store an 8-bit variable                  *
;* \1 Source                                *
;* \2 Destination                           *
;* Destroys A                               *
;********************************************
        .macro STORE8
        lda \1
        sta \2
        .endm

;********************************************
;* STORE16                                  *
;* Store a 16-bit variable                  *
;* \1 Source 16-bit                         *
;* \2 Destination                           *
;* Destroys A                               *
;********************************************
        .macro STORE16
        lda \1
        sta \2
        lda \1 + 1
        sta \2 + 1
        .endm

;********************************************
;* STORE8I                                  *
;* Store an 8-bit immediate value           *
;* \1 Value                                 *
;* \2 Destination                           *
;* Destroys A                               *
;********************************************
        .macro STORE8I
        lda #\1
        sta \2
        .endm

;********************************************
;* STORE16I                                 *
;* Store a 16-bit immediate value           *
;* \1 16-bit Value                          *
;* \2 Destination                           *
;* Destroys A                               *
;********************************************
        .macro STORE16I
        lda #<\1
        sta \2
        lda #>\1
        sta \2 + 1
        .endm

;********************************************
;* STOREM (Memory Fill / memset)            *
;* Fill memory block with a source byte     *
;* \1 Source Byte / Variable                *
;* \2 Destination Base                      *
;* \3 Length (Must be < 255)                *
;* Destroys A, Y                            *
;********************************************
        .macro STOREM
        ldy #\3 - 1
        lda \1
@l1:
        sta \2,y
        dey
        bpl @l1
        .endm

;********************************************
;* STOREMI (Immediate Memory Fill)          *
;* Fill memory block with an immediate byte *
;* \1 Source numeric value                  *
;* \2 Destination Base                      *
;* \3 Length (Must be < 255)                *
;* Destroys A, Y                            *
;********************************************
        .macro STOREMI
        lda #\1
        ldy #\3 - 1
@l1:
        sta \2,y
        dey
        bpl @l1
        .endm

;********************************************
;* MOVE8                                    *
;* Move an 8-bit variable                   *
;* \1 Source                                *
;* \2 Destination                           *
;* Destroys A                               *
;********************************************
        .macro MOVE8
        lda \1
        sta \2
        .endm

;********************************************
;* MOVE8I                                   *
;* Move an 8-bit value to a variable        *
;* \1 Variable                              *
;* \2 Value                                 *
;* Destroys A                               *
;********************************************
        .macro MOVE8I
        lda #\2
        sta \1
        .endm

;********************************************
;* MOVE16                                   *
;* Move a 16-bit variable                   *
;* \1 Source                                *
;* \2 Destination                           *
;* Destroys A                               *
;********************************************
        .macro MOVE16
        lda \1
        sta \2
        lda \1 + 1
        sta \2 + 1
        .endm

;********************************************
;* MOVE32                                   *
;* Move a 32-bit variable                   *
;* \1 Source                                *
;* \2 Destination                           *
;* Destroys A                               *
;********************************************
        .macro MOVE32
        lda \1
        sta \2
        lda \1 + 1
        sta \2 + 1
        lda \1 + 2
        sta \2 + 2
        lda \1 + 3
        sta \2 + 3
        .endm

;********************************************
;* MOVE16I                                  *
;* Move a 16-bit value to a variable        *
;* \1 Variable                              *
;* \2 Value                                 *
;* Destroys A                               *
;********************************************
        .macro MOVE16I
        lda #<\2
        sta \1
        lda #>\2
        sta \1 + 1
        .endm

;********************************************
;* ADD8                                     *
;* Add 8-bit variables                      *
;* \1 Variable 1                            *
;* \2 Variable 2                            *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD8
        clc
        lda \1
        adc \2
        sta \3
        .endm

;********************************************
;* ADD8I                                    *
;* Add 8-bit immediate to variable          *
;* \1 Variable 1                            *
;* \2 Immediate value                       *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD8I
        clc
        lda \1
        adc #\2
        sta \3
        .endm

;********************************************
;* ADD16                                    *
;* Add 16-bit variables                     *
;* \1 Variable 1                            *
;* \2 Variable 2                            *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD16
        clc
        lda \1
        adc \2
        sta \3
        lda \1 + 1
        adc \2 + 1
        sta \3 + 1
        .endm

;********************************************
;* ADD32                                    *
;* Add 32-bit variables                     *
;* \1 Variable 1                            *
;* \2 Variable 2                            *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD32
        clc
        lda \1
        adc \2
        sta \3
        lda \1 + 1
        adc \2 + 1
        sta \3 + 1
        lda \1 + 2
        adc \2 + 2
        sta \3 + 2
        lda \1 + 3
        adc \2 + 3
        sta \3 + 3
        .endm

;********************************************
;* ADD16I                                   *
;* Add 16-bit immediate to 16-bit variable  *
;* \1 Variable                              *
;* \2 Value                                 *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro ADD16I
        clc
        lda \1
        adc #<\2
        sta \3
        lda \1 + 1
        adc #>\2
        sta \3 + 1
        .endm

;********************************************
;* ADD168                                   *
;* Add 8-bit variable to 16-bit variable    *
;* \1 Variable 1 (16-bit)                   *
;* \2 Variable 2 (8-bit)                    *
;* \3 Destination (16-bit)                  *
;* Destroys A                               *
;********************************************
        .macro ADD168
        clc
        lda \1
        adc \2
        sta \3
        lda \1 + 1
        adc #0
        sta \3 + 1
        .endm

;********************************************
;* INC8                                     *
;* Increment an 8-bit variable              *
;* \1 Variable                              *
;* Destroys A (via inc)                     *
;********************************************
        .macro INC8
        inc \1
        .endm

;********************************************
;* INC16                                    *
;* Increment a 16-bit variable              *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro INC16
        inc \1
        bne @exit
        inc \1 + 1
@exit:
        .endm

;********************************************
;* SUB8                                     *
;* Subtract 8-bit variables                 *
;* \1 Variable                              *
;* \2 Variable to subtract                  *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB8
        sec
        lda \1
        sbc \2
        sta \3
        .endm

;********************************************
;* SUB8I                                    *
;* Subtract 8-bit immediate from variable   *
;* \1 Variable                              *
;* \2 Number to subtract                    *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB8I
        sec
        lda \1
        sbc #\2
        sta \3
        .endm

;********************************************
;* SUB16                                    *
;* Subtract 16-bit variables                *
;* \1 Variable                              *
;* \2 Variable to subtract                  *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB16
        sec
        lda \1
        sbc \2
        sta \3
        lda \1 + 1
        sbc \2 + 1
        sta \3 + 1
        .endm

;********************************************
;* SUB16I                                   *
;* Subtract 16-bit immediate from variable  *
;* \1 Variable                              *
;* \2 Value to subtract                     *
;* \3 Destination                           *
;* Destroys A                               *
;********************************************
        .macro SUB16I
        sec
        lda \1
        sbc #<\2
        sta \3
        lda \1 + 1
        sbc #>\2
        sta \3 + 1
        .endm

;********************************************
;* SUB168                                   *
;* Subtract 8-bit variable from 16-bit      *
;* \1 Variable (16-bit)                     *
;* \2 Variable to subtract (8-bit)          *
;* \3 Destination (16-bit)                  *
;* Destroys A                               *
;********************************************
        .macro SUB168
        sec
        lda \1
        sbc \2
        sta \3
        lda \1 + 1
        sbc #0
        sta \3 + 1
        .endm

;********************************************
;* DEC8                                     *
;* Decrement an 8-bit variable              *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro DEC8
        dec \1
        .endm

;********************************************
;* DEC16                                    *
;* Decrement a 16-bit variable              *
;* \1 Variable                              *
;* Destroys A                               *
;********************************************
        .macro DEC16
        SUB16I \1, 1, \1
        .endm

;********************************************
;* RSHIFT8                                  *
;* 8-bit right shift                        *
;* \1 Variable                              *
;* \2 Bits to shift                         *
;* Destroys X                               *
;********************************************
        .macro RSHIFT8
        ldx #\2
        beq @RSH8Exit
@RSHLoop:
        lsr \1
        dex
        bne @RSHLoop
@RSH8Exit:
        .endm

;********************************************
;* RSHIFT16                                 *
;* 16-bit right shift                       *
;* \1 Variable                              *
;* \2 Bits to shift                         *
;* Destroys X                               *
;********************************************
        .macro RSHIFT16
        ldx #\2
        beq @RSH16Exit
@RSH16Loop:
        lsr \1 + 1
        ror \1
        dex
        bne @RSH16Loop
@RSH16Exit:
        .endm

;********************************************
;* RSHIFT32                                 *
;* 32-bit right shift                       *
;* \1 Variable                              *
;* \2 Bits to shift                         *
;* Destroys X                               *
;********************************************
        .macro RSHIFT32
        ldx #\2
        beq @RSH32Exit
@RSH32Loop:
        lsr \1 + 3
        ror \1 + 2
        ror \1 + 1
        ror \1
        dex
        bne @RSH32Loop
@RSH32Exit:
        .endm

;********************************************
;* LSHIFT8                                  *
;* 8-bit left shift                         *
;* \1 Variable                              *
;* \2 Bits to shift                         *
;* Destroys X                               *
;********************************************
        .macro LSHIFT8
        ldx #\2
        beq @LSH8Exit
@LSH8Loop:
        asl \1
        dex
        bne @LSH8Loop
@LSH8Exit:
        .endm

;********************************************
;* LSHIFT16                                 *
;* 16-bit left shift                        *
;* \1 Variable                              *
;* \2 Bits to shift                         *
;* Destroys X                               *
;********************************************
        .macro LSHIFT16
        ldx #\2
        beq @LSH16Exit
@LS16Loop:
        asl \1
        rol \1 + 1
        dex
        bne @LS16Loop
@LSH16Exit:
        .endm

;********************************************
;* LSHIFT32                                 *
;* 32-bit left shift                        *
;* \1 Variable                              *
;* \2 Bits to shift                         *
;* Destroys X                               *
;********************************************
        .macro LSHIFT32
        ldx #\2
        beq @LSH32Exit
@LSH32Loop:
        asl \1
        rol \1 + 1
        rol \1 + 2
        rol \1 + 3
        dex
        bne @LSH32Loop
@LSH32Exit:
        .endm

;********************************************
;* MULT10                                   *
;* Multiplies 2-byte number by 10           *
;* n * 10 = n * 8 + n * 2                   *
;* \1 Variable                              *
;* Destroys A, X, Y                         *
;********************************************
        .macro MULT10
        asl \1
        rol \1 + 1                  ; Multiply by 2

        ; Save the number * 2
        ldx \1                      ; Save low byte in X
        ldy \1 + 1                  ; Save high byte in Y

        ; Continue shifting for multiply by 4 and 8
        asl \1
        rol \1 + 1                  ; Multiply by 4
        asl \1
        rol \1 + 1                  ; Multiply by 8

        ; Now add up the result: (8x) + (2x)
        clc                         ; Clear carry
        txa                         ; Load low byte of 2x
        adc \1                      ; Add to 8x low byte
        sta \1                      ; Store low byte
        tya                         ; Load high byte of 2x
        adc \1 + 1                  ; Add to 8x high byte
        sta \1 + 1                  ; Store high byte
        .endm

;********************************************
;* MULT40                                   *
;* Multiplies 2-byte number by 40           *
;* n * 40 = (n * 10) * 4                    *
;* \1 Variable                              *
;* Destroys A, X, Y                         *
;********************************************
        .macro MULT40
        MULT10 \1                   ; Multiply by 10 first
        asl \1
        rol \1 + 1                  ; Multiply by 2 -> 20
        asl \1
        rol \1 + 1                  ; Multiply by 2 -> 40
        .endm

;********************************************
;* MULT5                                    *
;* Multiplies 2-byte number by 5            *
;* n * 5 = n * 4 + n                        *
;* \1 Variable                              *
;* Destroys A, X, Y                         *
;********************************************
        .macro MULT5
        ; Save the number
        ldx \1                      ; Save low byte in X
        ldy \1 + 1                  ; Save high byte in Y

        ; Continue shifting for multiply by 4
        LSHIFT16 \1, 2

        ; Now add up the result: (4x) + (1x)
        clc                         ; Clear carry
        txa                         ; Load original low byte (1x)
        adc \1                      ; Add to 4x low byte
        sta \1                      ; Store low byte
        tya                         ; Load original high byte (1x)
        adc \1 + 1                  ; Add to 4x high byte
        sta \1 + 1                  ; Store high byte
        .endm

;********************************************
;* MULT8                                    *
;* 8-bit multiplication                     *
;* \1 Variable a                            *
;* \2 Variable b                            *
;* \3 Destination                           *
;********************************************
        .macro MULT8
        lda #0
        ldx #8
@Loop:
        lsr \2
        bcc @NoAdd
        clc
        adc \1
@NoAdd:
        rol \1
        dex
        bne @Loop
        sta \3
        .endm

;********************************************
;* MULT16                                   *
;* 16-bit multiplication -> 32-bit result   *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination (32-bit)                  *
;********************************************
        .macro MULT16
        PUSH16 \2
        MULT_F_16 \1, \2, \3
        POP16 \2
        .endm

;********************************************
;* MULT_F_16                                *
;* 16-bit multiplication (destroys \2)      *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit, destroyed)        *
;* \3 Destination (32-bit)                  *
;********************************************
        .macro MULT_F_16
        lda #0
        sta \3                      ; Initialize low word / scratch
        sta \3 + 1
        sta \3 + 2                  ; Initialize high accumulation byte to 0

        ldx #16                     ; There are 16 bits in num2
@l1:
        lsr \2 + 1                  ; Get low bit of num2
        ror \2
        bcc @l2                     ; 0 or 1?

        tay                         ; If 1, save high byte accumulator in Y
        clc
        lda \1
        adc \3 + 2
        sta \3 + 2

        tya                         ; Restore accumulator high byte
        adc \1 + 1
@l2:
        ror                         ; "Stairstep" shift across 32-bit result
        ror \3 + 2
        ror \3 + 1
        ror \3

        dex
        bne @l1

        sta \3 + 3                  ; Store final high byte
        .endm

;********************************************
;* MULT16I                                  *
;* 16-bit immediate multiplication          *
;* \1 Immediate value a (16-bit constant)   *
;* \2 Variable b (16-bit variable)          *
;* \3 Destination (32-bit)                  *
;* Destroys A, X, Y                         *
;********************************************

        .macro MULT16I
        PUSH16 \2

        lda #0
        sta \3                      ; Result byte 0
        sta \3 + 1                  ; Result byte 1
        sta \3 + 2                  ; Result byte 2
        ; A must also start at zero!
        ; Do this after clearing the destination.
        lda #0

        ldx #16
@l1:
        lsr \2 + 1
        ror \2
        bcc @l2

        tay
        clc
        lda #<\1
        adc \3 + 2
        sta \3 + 2

        tya
        adc #>\1
@l2:
        ror
        ror \3 + 2
        ror \3 + 1
        ror \3

        dex
        bne @l1

        sta \3 + 3
        POP16 \2
        .endm

;********************************************
;*                                          *
;*  SWAP16                                  *
;*                                          *
;*  Swap 2 16 bit values                    *
;*                                          *
;*  \1  Variable a     16-bit               *
;*  \2  Variable b     16 bit               *
;*                                          *
;********************************************
            .macro SWAP16
            ldx \1
            ldy \1 + 1
            lda \2
            sta \1
            lda \2 + 1
            sta \1 + 1
            stx \2
            sty \2 + 1
            .endm


;********************************************
;* BCD2STR                                  *
;* Converts 1-byte packed BCD to 2-byte string *
;* \1 Source BCD byte                       *
;* \2 Destination string buffer (2 bytes)   *
;* Destroys A, X                            *
;********************************************
        .macro BCD2STR
        lda \1                  ; Load the BCD byte
        tax                     ; Save a copy in X
        lsr                     ; Shift high nibble down to low nibble
        lsr
        lsr
        lsr
        ora #'0'                ; Convert to PETASCII digit
        sta \2                  ; Store tens digit (first string byte)
        txa                     ; Reload original BCD byte
        and #$0F                ; Mask out high nibble (keep low nibble)
        ora #'0'                ; Convert to PETASCII digit
        sta \2 + 1              ; Store ones digit (second string byte)
        .endm

;********************************************
;*                                          *
;* PUSHREG                                  *
;*                                          *
;*  push registers on the stack             *
;*                                          *
;*  destroys a                              *
;*                                          *
;********************************************
        .macro PUSHREGS
        php
        pha
        tya
        pha
        txa
        pha
        .endm

;********************************************
;*                                          *
;* POPREG                                   *
;*                                          *
;*  restore registers on the stack          *
;*                                          *
;*  destroys a,x,y                          *
;*                                          *
;********************************************
        .macro POPREGS
        pla
        tax
        pla
        tay
        pla
        plp
        .endm

;********************************************
;*                                          *
;* PUSHAY                                   *
;*                                          *
;*  push and y on the stack                 *
;*                                          *
;*  destroys a                              *
;*                                          *
;********************************************
        .macro PUSHAY
        pha
        tya
        pha
        .endm

;********************************************
;*                                          *
;* POPAY                                    *
;*                                          *
;*  restore registers on the stack          *
;*                                          *
;*  destroys a,y                            *
;*                                          *
;********************************************
        .macro POPAY
        pla
        tay
        pla
        .endm


;********************************************
;* SQUARE                                   *
;* Calculates 16-bit unsigned integer square*
;* of the signed 16-bit integer in \1.      *
;* Result (0 to 65025) stored in \2.        *
;* Input magnitude must be <= 255.          *
;* Destroys all registers (A, X, Y)         *
;********************************************
        .macro SQUARE
        lda #$00            ; Clear A (immediate mode)
        sta \2              ; Clear square low byte

        lda \1              ; Get number low byte
        ldx \1 + 1          ; Get number high byte
        bpl @NonNeg         ; If positive, don't negate
                            ; Else do two's complement
        eor #$ff            ; Invert low byte
        sec                 ; Set carry for +1
        adc #$00            ; Complete two's complement

@NonNeg:
        pha                 ; Save abs(number) on the stack temporarily
        ldx #$08            ; Set bit count (8 iterations)

@Nextr2Bit:
        asl \2              ; Low byte * 2
        rol \2 + 1          ; High byte * 2 + carry from low
        asl a               ; Shift number bit into carry
        bcc @NoSqAdd        ; Don't add if bit is 0

        tay                 ; Save accumulator state in Y
        clc                 ; Clear carry for addition
        tsx                 ; Get stack pointer
        lda $0101,x         ; Peek at saved abs(number) on stack
        adc \2              ; Add to square low byte
        sta \2              ; Save square low byte
        lda #$00            ; Clear A
        adc \2 + 1          ; Add with carry to square high byte
        sta \2 + 1          ; Save square high byte
        tya                 ; Restore accumulator state from Y

@NoSqAdd:
        dex                 ; Decrement bit count
        bne @Nextr2Bit      ; Loop for next bit

        pla                 ; Clean up abs(number) from stack
        .endm


;********************************************
;* BEQ16                                    *
;* 16-bit branch if equal                   *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination label (if a == b)         *
;* Destroys A                               *
;********************************************
        .macro BEQ16
        lda \1 + 1
        cmp \2 + 1
        bne @exit
        lda \1
        cmp \2
        beq \3
@exit:
        .endm

;********************************************
;* BEQ16I                                   *
;* 16-bit immediate branch if equal         *
;* \1 Variable a (16-bit)                   *
;* \2 Immediate value (16-bit)              *
;* \3 Destination label (if a == b)         *
;* Destroys A                               *
;********************************************
        .macro BEQ16I
        lda \1 + 1
        cmp #>\2
        bne @exit
        lda \1
        cmp #<\2
        beq \3
@exit:
        .endm

;********************************************
;* BNE16                                    *
;* 16-bit branch if not equal               *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination label (if a != b)         *
;* Destroys A                               *
;********************************************
        .macro BNE16
        lda \1 + 1
        cmp \2 + 1
        bne \3
        lda \1
        cmp \2
        bne \3
        .endm

;********************************************
;* BNE16I                                   *
;* 16-bit immediate branch if not equal     *
;* \1 Variable a (16-bit)                   *
;* \2 Immediate value (16-bit)              *
;* \3 Destination label (if a != b)         *
;* Destroys A                               *
;********************************************
        .macro BNE16I
        lda \1 + 1
        cmp #>\2
        bne \3
        lda \1
        cmp #<\2
        bne \3
        .endm

;********************************************
;* BLT16                                    *
;* 16-bit branch if less than (a < b)       *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination label                     *
;* Destroys A                               *
;********************************************
        .macro BLT16
        lda \1 + 1
        cmp \2 + 1
        bcc \3
        bne @exit
        lda \1
        cmp \2
        bcc \3
@exit:
        .endm

;********************************************
;* BLT16I                                   *
;* 16-bit immediate branch if less than     *
;* \1 Variable a (16-bit)                   *
;* \2 Immediate value (16-bit)              *
;* \3 Destination label                     *
;* Destroys A                               *
;********************************************
        .macro BLT16I
        lda \1 + 1
        cmp #>\2
        bcc \3
        bne @exit
        lda \1
        cmp #<\2
        bcc \3
@exit:
        .endm

;********************************************
;* BLE16                                    *
;* 16-bit branch if less than or equal      *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination label (if a <= b)         *
;* Destroys A                               *
;********************************************
        .macro BLE16
        lda \1 + 1
        cmp \2 + 1
        bcc \3
        bne @exit
        lda \1
        cmp \2
        bcc \3
        beq \3
@exit:
        .endm

;********************************************
;* BLE16I                                   *
;* 16-bit immediate branch <=               *
;* \1 Variable a (16-bit)                   *
;* \2 Immediate value (16-bit)              *
;* \3 Destination label (if a <= b)         *
;* Destroys A                               *
;********************************************
        .macro BLE16I
        lda \1 + 1
        cmp #>\2
        bcc \3
        bne @exit
        lda \1
        cmp #<\2
        bcc \3
        beq \3
@exit:
        .endm

;********************************************
;* BGE16                                    *
;* 16-bit branch if greater than or equal   *
;* \1 Variable a (16-bit)                   *
;* \2 Variable b (16-bit)                   *
;* \3 Destination label (if a >= b)         *
;* Destroys A                               *
;********************************************
        .macro BGE16
        lda \1 + 1
        cmp \2 + 1
        beq @bg1
        bcs \3
        bcc @exit
@bg1:
        lda \1
        cmp \2
        bcs \3
@exit:
        .endm

;********************************************
;* BGE16I                                   *
;* 16-bit immediate branch >=               *
;* \1 Variable a (16-bit)                   *
;* \2 Immediate value (16-bit)              *
;* \3 Destination label (if a >= b)         *
;* Destroys A                               *
;********************************************
        .macro BGE16I
        lda \1 + 1
        cmp #>\2
        beq @bg1
        bcs \3
        bcc @exit
@bg1:
        lda \1
        cmp #<\2
        bcs \3
@exit:
        .endm

;********************************************
;*                                          *
;* ADDFIX16                                 *
;*                                          *
;*  add 16 bit fixed point variables        *
;*                                          *
;*  /1  Variable 1                          *
;*  /2  Variable 2                          *
;*  /3  Destination                         *
;*                                          *
;*  destroys a                              *
;*                                          *
;********************************************
        .macro ADDFIX16
        clc
        lda \1 + 2
        adc \2 + 2
        sta \3 + 2
        lda \1 + 3
        adc \2 + 3
        sta \3 + 3
        lda \1
        adc \2
        sta \3
        lda \1 + 1
        adc \2 + 1
        sta \3 + 1
        .endm


;********************************************
;*                                          *
;* ADDFIX16I                                *
;*                                          *
;*  add 16 bit fixed point variables        *
;*                                          *
;*  /1  Variable 1                          *
;*  /2  number                              *
;*  /3  Destination                         *
;*                                          *
;*  destroys a                              *
;*                                          *
;********************************************
        .macro ADDFIX16I
        clc
        lda #\2
        adc \1 + 2
        sta \3 + 2
        lda #0
        adc \1 + 3
        sta \3 + 3
        lda #0
        adc \1
        sta \3
        lda #0
        adc \1 + 1
        sta \3 + 1
        .endm

;********************************************
;*                                          *
;* SUBFIX16                                 *
;*                                          *
;*  subtract 16 bit variables               *
;*                                          *
;*  \1  Variable                            *
;*  \2  Variable to subtract                *
;*  \3  Destination                         *
;*                                          *
;*  destroys a                              *
;*                                          *
;********************************************
        .macro SUBFIX16
        sec
        lda \1 + 2
        sbc \2 + 2
        sta \3 + 2
        lda \1 + 3
        sbc \2 + 3
        sta \3 + 3

        lda \1
        sbc \2
        sta \3
        lda \1 + 1
        sbc \2 + 1
        sta \3 + 1

        .endm

;********************************************
;*                                          *
;*  FMUL                                    *
;*                                          *
;*  16 bit multiplication 32bit result      *
;*  swap hi and low words                   *
;*                                          *
;*  \1  Variable a     16-bit               *
;*  \2  Variable b     16 bit               *
;*  \3  Destination    32 bit               *
;*                                          *
;********************************************
            .macro FMUL
            MULT16 \1, \2, \3
            SWAP16 \3, \3 + 2
            .endm

;********************************************
;* FIX16_ADD                                *
;* Add two 16.16 fixed-point variables      *
;* \1 Variable 1 (16.16)                    *
;* \2 Variable 2 (16.16)                    *
;* \3 Destination (16.16)                   *
;* Destroys A                               *
;********************************************
        .macro FIX16_ADD
        clc
        lda \1
        adc \2
        sta \3
        lda \1 + 1
        adc \2 + 1
        sta \3 + 1
        lda \1 + 2
        adc \2 + 2
        sta \3 + 2
        lda \1 + 3
        adc \2 + 3
        sta \3 + 3
        .endm

;********************************************
;* FIX16_ADDI                               *
;* Add 16-bit integer immediate to 16.16    *
;* \1 Source variable (16.16)               *
;* \2 Immediate integer value (16-bit)      *
;* \3 Destination (16.16)                   *
;* Destroys A                               *
;********************************************
        .macro FIX16_ADDI
        lda \1                      ; Copy fraction low byte as-is
        sta \3
        lda \1 + 1                  ; Copy fraction high byte as-is
        sta \3 + 1
        clc
        lda \1 + 2                  ; Add immediate to integer low byte
        adc #<\2
        sta \3 + 2
        lda \1 + 3                  ; Add immediate to integer high byte
        adc #>\2
        sta \3 + 3
        .endm

  ;********************************************
;* FIX16_SUB                                *
;* Subtract two 16.16 fixed-point variables *
;* \1 Source variable 1 (16.16)             *
;* \2 Source variable 2 to subtract (16.16) *
;* \3 Destination (16.16)                   *
;* Destroys A                               *
;********************************************
        .macro FIX16_SUB
        sec
        lda \1
        sbc \2
        sta \3
        lda \1 + 1
        sbc \2 + 1
        sta \3 + 1
        lda \1 + 2
        sbc \2 + 2
        sta \3 + 2
        lda \1 + 3
        sbc \2 + 3
        sta \3 + 3
        .endm

;********************************************
;* FIX16_SUBI                               *
;* Subtract 16-bit integer immediate from   *
;* 16.16 fixed-point variable               *
;* \1 Source variable (16.16)               *
;* \2 Immediate integer value to subtract   *
;* \3 Destination (16.16)                   *
;* Destroys A                               *
;********************************************
        .macro FIX16_SUBI
        lda \1                      ; Copy fraction low byte as-is
        sta \3
        lda \1 + 1                  ; Copy fraction high byte as-is
        sta \3 + 1
        sec
        lda \1 + 2                  ; Subtract immediate from integer low byte
        sbc #<\2
        sta \3 + 2
        lda \1 + 3                  ; Subtract immediate from integer high byte
        sbc #>\2
        sta \3 + 3
        .endm



;********************************************
;* FIX16_MUL                                *
;* Unsigned 16.16 fixed-point multiplication *
;* \1 = Multiplicand (4 bytes)               *
;* \2 = Multiplier   (4 bytes)               *
;* \3 = Destination  (4 bytes)               *
;* Destroys A, X                             *
;* Preserves original multiplier             *
;********************************************
        .macro FIX16_MUL

        ; Save original multiplier
        lda \2 + 3
        pha
        lda \2 + 2
        pha
        lda \2 + 1
        pha
        lda \2
        pha

        ; Clear upper 32 bits of working product
        lda #0
        sta \3
        sta \3 + 1
        sta \3 + 2
        sta \3 + 3

        ldx #32

@MulLoop:
        ; Test the current least-significant multiplier bit
        lda \2
        lsr
        bcc @NoAdd

        ; Add multiplicand to upper 32 bits
        clc
        lda \3
        adc \1
        sta \3

        lda \3 + 1
        adc \1 + 1
        sta \3 + 1

        lda \3 + 2
        adc \1 + 2
        sta \3 + 2

        lda \3 + 3
        adc \1 + 3
        sta \3 + 3

@NoAdd:
        ; Shift the complete 64-bit working product right
        lsr \3 + 3
        ror \3 + 2
        ror \3 + 1
        ror \3
        ror \2 + 3
        ror \2 + 2
        ror \2 + 1
        ror \2

        dex
        bne @MulLoop

        ; Product is now distributed across \2 and \3.
        ; Result = product >> 16.
        ; Copy high bytes first to avoid overwriting sources.

        lda \3 + 1
        sta \3 + 3
        lda \3
        sta \3 + 2
        lda \2 + 3
        sta \3 + 1
        lda \2 + 2
        sta \3

        ; Restore original multiplier
        pla
        sta \2
        pla
        sta \2 + 1
        pla
        sta \2 + 2
        pla
        sta \2 + 3

        .endm

        
;********************************************
;* FIX16_DIV                                *
;* Unsigned 16.16 division                  *
;*                                          *
;* Usage: FIX16_DIV dividend, divisor, dest *
;*                                          *
;* Calculates: dest = dividend / divisor    *
;* Preserves both input operands             *
;* Division by zero returns zero             *
;*                                          *
;* Destroys A, X, Y                          *
;********************************************

.macro FIX16_DIV

        ; Allocate and initialize local workspace.
        ; Execution jumps over this data at the end.
        jmp @DivCode

@DivNum:
        .ds 4
@Divisor:
        .ds 4
@DivRem:
        .ds 5
@DivQuot:
        .ds 4
@DivBit:
        .ds 1

@DivCode:
        ; Copy dividend and divisor
        lda \1
        sta @DivNum
        lda \1+1
        sta @DivNum+1
        lda \1+2
        sta @DivNum+2
        lda \1+3
        sta @DivNum+3

        lda \2
        sta @Divisor
        lda \2+1
        sta @Divisor+1
        lda \2+2
        sta @Divisor+2
        lda \2+3
        sta @Divisor+3

        ; Initialize remainder and quotient
        lda #0
        sta @DivRem
        sta @DivRem+1
        sta @DivRem+2
        sta @DivRem+3
        sta @DivRem+4
        sta @DivQuot
        sta @DivQuot+1
        sta @DivQuot+2
        sta @DivQuot+3

        ; Division by zero check
        lda @Divisor
        ora @Divisor+1
        ora @Divisor+2
        ora @Divisor+3
        beq @DivZero

        ; Process 48 bits:
        ; 32 dividend bits followed by 16 zero bits.
        ldx #48

@DivLoop:
        ; Shift next dividend bit into carry.
        asl @DivNum
        rol @DivNum+1
        rol @DivNum+2
        rol @DivNum+3

        ; Save incoming bit.
        lda #0
        rol
        sta @DivBit

        ; Remainder = remainder * 2 + incoming bit
        asl @DivRem
        rol @DivRem+1
        rol @DivRem+2
        rol @DivRem+3
        rol @DivRem+4

        lda @DivRem
        ora @DivBit
        sta @DivRem

        ; Shift quotient left.
        asl @DivQuot
        rol @DivQuot+1
        rol @DivQuot+2
        rol @DivQuot+3

        ; If remainder's fifth byte is nonzero,
        ; remainder is greater than divisor.
        lda @DivRem+4
        bne @DivSubtract

        ; Compare remainder with divisor,
        ; most significant byte first.
        lda @DivRem+3
        cmp @Divisor+3
        bcc @DivNext
        bne @DivSubtract

        lda @DivRem+2
        cmp @Divisor+2
        bcc @DivNext
        bne @DivSubtract

        lda @DivRem+1
        cmp @Divisor+1
        bcc @DivNext
        bne @DivSubtract

        lda @DivRem
        cmp @Divisor
        bcc @DivNext

@DivSubtract:
        ; Remainder -= divisor
        sec
        lda @DivRem
        sbc @Divisor
        sta @DivRem
        lda @DivRem+1
        sbc @Divisor+1
        sta @DivRem+1
        lda @DivRem+2
        sbc @Divisor+2
        sta @DivRem+2
        lda @DivRem+3
        sbc @Divisor+3
        sta @DivRem+3
        lda @DivRem+4
        sbc #0
        sta @DivRem+4

        ; Quotient bit = 1
        ; Set the least-significant quotient bit.
        lda @DivQuot
        ora #1
        sta @DivQuot        

@DivNext:
        dex
        bne @DivLoop

        ; Copy quotient to destination
        lda @DivQuot
        sta \3
        lda @DivQuot+1
        sta \3+1
        lda @DivQuot+2
        sta \3+2
        lda @DivQuot+3
        sta \3+3

        jmp @DivDone

@DivZero:
        lda #0
        sta \3
        sta \3+1
        sta \3+2
        sta \3+3

@DivDone:
.endm

.print Pop