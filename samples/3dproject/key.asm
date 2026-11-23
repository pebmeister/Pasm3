            .print  push
            .print  off

; ============================================
; COMMODORE 64 KERNAL PETSCII KEYCODE EQUATES
; Returned by KERNAL GETIN ($FFE4) or standard input
; ============================================

; --- Function Keys ---
            KEY_F1  = $85               ; F1 (Unshifted)
            KEY_F3  = $86               ; F3 (Unshifted)
            KEY_F5  = $87               ; F5 (Unshifted)
            KEY_F7  = $88               ; F7 (Unshifted)
            KEY_F2  = $89               ; F2 (Shifted)
            KEY_F4  = $8a               ; F4 (Shifted)
            KEY_F6  = $8b               ; F6 (Shifted)
            KEY_F8  = $8c               ; F8 (Shifted)

; --- First Row ---
            KEY_LEFT_ARROW = $5f        ; <-

            KEY_ONE = $31               ; '1'
            KEY_EXCLAMATION = $21       ; '!'
            KEY_BLACK = $90             ;
            KEY_ORANGE = $81            ;

            KEY_TWO = $32               ; '2'
            KEY_QUOTE = $22             ; '"'
            KEY_WHITE = $05             ;
            KEY_BROWN = $95             ;

            KEY_THREE = $33             ; '3'
            KEY_HASH = $23              ; '#'
            KEY_RED = $1c               ;
            KEY_LT_RED = $96            ;

            KEY_FOUR = $34              ; '4'
            KEY_DOLLAR = $24            ; '$'
            KEY_CYAN = $9f              ;
            KEY_DRK_GRAY = $97          ;

            KEY_FIVE = $35              ; '5'
            KEY_PERCENT = $25           ; '%'
            KEY_PURPLE = $9c            ;
            KEY_MED_GRAY = $98          ;

            KEY_SIX = $36               ; '6'
            KEY_AMPERSAND = $26         ; '&'
            KEY_GREEN = $1e             ;
            KEY_LT_GREEN = $99          ;

            KEY_SEVEN = $37             ; '7'
            KEY_APOSTROPHE = $27        ; '''
            KEY_BLUE = $1f              ;
            KEY_LT_BLUE = $9a           ;

            KEY_EIGHT = $38             ; '8'
            KEY_LEFTPAREN = $28         ; '('
            KEY_YELLOW = $9e            ;
            KEY_LT_GRAY = $9b           ;

            KEY_NINE = $39              ; '9'
            KEY_RIGHTPAREN = $29        ; ')'
            KEY_REVERSE_ON = $12        ;
;KEY_RIGHTPAREN  = $29       ; ')'

            KEY_ZERO = $30              ; '0'
; KEY_ZERO        = $30     ; '0'
            KEY_REVERSE_OFF = $92       ;
; KEY_ZERO        = $30     ; '0'

            KEY_PLUS = $2b              ; '+'
            KEY_SHIFT_PLUS = $db        ;
; KEY_CTRL_PLUS NOTHING     '
            KEY_CBM_PLUS = $a6          ;

            KEY_MINUS = $2d             ; '-'
            KEY_SHIFT_MINUS = $dd       ;
; KEY_CTRL_MINUS NOTHING    ;
            KEY_CBM_MINUS = $dc         ;

            KEY_POUND = $5c             ;
            KEY_SHIFT_POUND = $a9       ;
            KEY_CTRL_POUND = $1c        ;
            KEY_CBM_POUND = $a8         ;
            KEY_HOME = $13              ; Home
            KEY_CLR = $93               ; Clear Screen (Shift + Home)
; KEY_CTRL_HOME  NOTHING    ;
; KEY_CLR         = $93     ; Clear Screen (Shift + Home)

            KEY_DEL = $14               ; Delete / Backspace
            KEY_INST = $94              ; Insert
; KEY_SHIFT_DEL NOTHING     ; 
; KEY_INST        = $94     ; Insert 

; --- Second Row ---
; KEY_CONTROL   NONE
            KEY_Q   = $51               ; 'Q'
            KEY_SHIFT_Q = $d1           ;
            KEY_CTRL_Q = $11            ; Cursor Down
            KEY_CBM_Q = $ab             ;

            KEY_W   = $57               ; 'W'
            KEY_SHIFT_W = $d7           ;
            KEY_CTRL_W = $17            ;
            KEY_CBM_W = $b3             ;

            KEY_E   = $45               ; 'E'
            KEY_SHIFT_E = $c5           ;
            KEY_CTRL_E = $05            ;
            KEY_CBM_E = $b1             ;

            KEY_R   = $52               ; 'R'
            KEY_SHIFT_R = $d2           ;
            KEY_CTRL_R = $12            ;
            KEY_CBM_R = $b2             ;

            KEY_T   = $54               ; 'T'
            KEY_SHIFT_T = $d4           ;
            KEY_CTRL_T = $14            ;
            KEY_CBM_T = $a3             ;

            KEY_Y   = $59               ; 'Y'
            KEY_SHIFT_Y = $d9           ;
            KEY_CTRL_Y = $19            ;
            KEY_CBM_Y = $b7             ;

            KEY_U   = $55               ; 'U'
            KEY_SHIFT_U = $d5           ;
            KEY_CTRL_U = $15            ;
            KEY_CBM_U = $b8             ;

            KEY_I   = $49               ; 'I'
            KEY_SHIFT_I = $c9           ;
            KEY_CTRL_I = $09            ; TAB
            KEY_CBM_I = $a2             ;

            KEY_O   = $4f               ; 'O'
            KEY_SHIFT_O = $cf           ;
            KEY_CTRL_TOP = $0f          ;
            KEY_CBM_O = $b9             ;

            KEY_P   = $50               ; 'P'
            KEY_SHIFT_P = $d0           ;
            KEY_CTRL = $10              ;
            KEY_CBM_P = $af             ;

            KEY_AT  = $40               ; '@'
            KEY_SHIFT_AT = $ba          ;
            KEY_CTRL_AT = $00           ; HOW is this possible?
            KEY_CBM_AT = $a4            ;

            KEY_STAR = $2a              ; '*'
            KEY_SHIFT_STAR = $c0        ;
; KEY_CTRL_STAR NOTHING     ;
            KEY_CBM_STAR = $df          ;

            KEY_UP_ARROW = $5e          ; '^'
            KEY_SHIFT_UP_ARROW = $de    ;
; KEY_GREEN       = $1E     ;
            KEY_CBM_UP_ARROW = $de      ;

; KEY_RESTORE   NONE

; --- Third Row ---
            KEY_STOP = $03              ; Run / Stop
            KEY_RUN = $83               ; Run
; KEY_CTRL_RUN  NOTHING     ;
; KEY_RUN         = $83     ; Run

; KEY_SHIFT     NONE

            KEY_A   = $41               ; 'A'
            KEY_SHIFT_A = $c1           ;
            KEY_CTRL_A = $01            ;
            KEY_CBM_A = $b0             ;

            KEY_S   = $53               ; 'S'
            KEY_SHIFT_S = $d3           ;
; KEY_HOME        = $13     ; Home
            KEY_CBM_S = $ae             ;

            KEY_D   = $44               ; 'D'
            KEY_SHIFT_D = $c4           ;
            KEY_CLR_ENTRY = $04         ;
            KEY_CBM_D = $ac             ;

            KEY_F   = $46               ; 'F'
            KEY_SHIFT_F = $c6           ;
            KEY_CTRL_F = $06            ;
            KEY_CBM_F = $bb             ;

            KEY_G   = $47               ; 'G'
            KEY_SHIFT_G = $c7           ;
            KEY_CTRL_G = $07            ;
            KEY_CBM_G = $a5             ;

            KEY_H   = $48               ; 'H'
            KEY_SHIFT_H = $c8           ;
            KEY_CTRL_H = $08            ;
            KEY_CBM_H = $b4             ;

            KEY_J   = $4a               ; 'J'
            KEY_SHIFT_J = $ca           ;
            KEY_CTRL_J = $0a            ;
            KEY_CBM_J = $b5             ;

            KEY_K   = $4b               ; 'K'
            KEY_SHIFT_K = $cb           ;
            KEY_CTRL_K = $0b            ;
            KEY_CBM_K = $a1             ;

            KEY_L   = $4c               ; 'L'
            KEY_SHIFT_L = $cc           ;
            KEY_CTRL_L = $0c            ;
            KEY_CBM_L = $b6             ;

            KEY_COLON = $3a             ; ':'
            KEY_LEFTBRACKET = $5b       ; '['

            KEY_SEMICOLAN = $3b         ; ';'
            KEY_RIGHTBRACKET = $5d      ; ']'
; KEY_RIGHT       = $1D     ; Cursor Right

            KEY_EQUAL = $3d             ; '='
; KEY_BLUE        = $1F     ;

            KEY_RETURN = $0d            ; Return / Enter
            KEY_SHIFT_RETURN = $8d      ;

; --- Fourth Row ---
; KEY_CBM       NONE
; KEY_SHIFT     NONE

            KEY_Z   = $5a               ; 'Z'
            KEY_SHIFT_Z = $da           ;
            KEY_CTRL_Z = $1a            ;
            KEY_CBM_Z = $ad             ;

            KEY_X   = $58               ; 'X'
            KEY_SHIFT_X = $d8           ;
            KEY_CTRL_X = $18            ;
            KEY_CBM_X = $bd             ;

            KEY_C   = $43               ; 'C'
            KEY_SHIFT_C = $c3           ;
            KEY_CTRL_C = $03            ; Run / Stop
            KEY_CBM_C = $bc             ;

            KEY_V   = $56               ; 'V'
            KEY_SHIFT_V = $d6           ;
            KEY_CTRL_V = $16            ;
            KEY_CBM_V = $be             ;

            KEY_B   = $42               ; 'B'
            KEY_SHIFT_B = $c2           ;
            KEY_CTRL_B = $02            ;
            KEY_CBM_B = $bf             ;

            KEY_N   = $4e               ; 'N'
            KEY_SHIFT_N = $ce           ;
            KEY_CTRL_N = $0e            ;
            KEY_CBM_N = $aa             ;

            KEY_M   = $4d               ; 'M'
            KEY_SHIFT_M = $cd           ;
            KEY_CTRL_M = $0d            ; Return / Enter
            KEY_CBM_M = $a7             ;

            KEY_COMMA = $2c             ; ','
            KEY_LESS_THAN = $3c         ;
; KEY_CTRL_COMMA NOTHING    ;
; KEY_CBM_COMMA = $3C       ;

            KEY_PERIOD = $2e            ; '.'
            KEY_GREATER_THAN = $3e      ;
; KEY_CTRL_PERIOD NOTHING   ;
; KEY_CBM_PERIOD = $3E      ;

            KEY_SLASH = $2f             ; '/'
            KEY_QUESTION = $3f          ;
; KEY_CTRL_SLASH NOTHING    ;
; KEY_CBM_SLASH = $3F       ;

; KEY_SHIFT     NONE
            KEY_DOWN = $11              ; Cursor Down
; KEY_UP        = $91        ; Cursor Down

            KEY_RIGHT = $1d             ; Cursor Right
; KEY_LEFT        = $9D     ; Cursor Left

; --- Fifth Row ---
            KEY_SPACE = $20             ; Spacebar
            KEY_SHIFT_SPACE = $a0       ; shift Spacebar

; --- 128 Top Row ---
            KEY_ESC = $1b               ; Escape (where applicable)
            KEY_TAB = $09               ; TAB
; KEY_ALT       NONE
; KEY_CAPS      NONE
            KEY_HELP = $84              ; HELP
            KEY_HELP = $84              ; HELP
            KEY_LINEFEED = $0a          ; LF
; KEY_40_80     NONE
; KEY_SCR       NONE
            KEY_UP  = $91               ; Cursor Up
;KEY_DOWN        = $11       ; Cursor Down
            KEY_LEFT = $9d              ; Cursor Left
;KEY_RIGHT       = $1D       ; Cursor Right
;KEY_F1          = $85       ; F1 (Unshifted)
;KEY_F3          = $86       ; F3 (Unshifted)
;KEY_F5          = $87       ; F5 (Unshifted)
;KEY_F7          = $88       ; F7 (Unshifted)

            .print  pop
