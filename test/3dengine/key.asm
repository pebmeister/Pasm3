; ============================================
; COMMODORE 64 KERNAL PETSCII KEYCODE EQUATES
; Returned by KERNAL GETIN ($FFE4) or standard input
; ============================================

; --- Function Keys ---
KEY_F1          = $85       ; F1 (Unshifted)
KEY_F3          = $86       ; F3 (Unshifted)
KEY_F5          = $87       ; F5 (Unshifted)
KEY_F7          = $88       ; F7 (Unshifted)
KEY_F2          = $89       ; F2 (Shifted)
KEY_F4          = $8A       ; F4 (Shifted)
KEY_F6          = $8B       ; F6 (Shifted)
KEY_F8          = $8C       ; F8 (Shifted)

; --- First Row ---
KEY_LEFT_ARROW  = $5F       ; <-

KEY_ONE         = $31       ; '1'
KEY_EXCLAMATION = $21       ; '!'
KEY_BLACK       = $90       ;
KEY_ORANGE      = $81       ;

KEY_TWO         = $32       ; '2'
KEY_QUOTE       = $22       ; '"'
KEY_WHITE       = $05       ;
KEY_BROWN       = $95       ;

KEY_THREE       = $33       ; '3'
KEY_HASH        = $23       ; '#'
KEY_RED         = $1C       ;
KEY_LT_RED      = $96       ;

KEY_FOUR        = $34       ; '4'
KEY_DOLLAR      = $24       ; '$'
KEY_CYAN        = $9F       ;
KEY_DRK_GRAY    = $97       ;

KEY_FIVE        = $35       ; '5'
KEY_PERCENT     = $25       ; '%'
KEY_PURPLE      = $9C       ;
KEY_MED_GRAY    = $98       ;

KEY_SIX         = $36       ; '6'
KEY_AMPERSAND   = $26       ; '&'
KEY_GREEN       = $1E       ;
KEY_LT_GREEN    = $99       ;

KEY_SEVEN       = $37       ; '7'
KEY_APOSTROPHE  = $27       ; '''
KEY_BLUE        = $1F       ;
KEY_LT_BLUE     = $9A       ;

KEY_EIGHT       = $38       ; '8'
KEY_LEFTPAREN   = $28       ; '('
KEY_YELLOW      = $9E       ;
KEY_LT_GRAY     = $9B       ;

KEY_NINE        = $39       ; '9'
KEY_RIGHTPAREN  = $29       ; ')'
KEY_REVERSE_ON  = $12       ;
;KEY_RIGHTPAREN  = $29       ; ')'

KEY_ZERO        = $30       ; '0'
; KEY_ZERO        = $30     ; '0'
KEY_REVERSE_OFF = $92       ;
; KEY_ZERO        = $30     ; '0'

KEY_PLUS        = $2B       ; '+'
KEY_SHIFT_PLUS  = $DB       ;
; KEY_CTRL_PLUS NOTHING     '
KEY_CBM_PLUS    = $A6       ;

KEY_MINUS       = $2D       ; '-'
KEY_SHIFT_MINUS = $DD       ;
; KEY_CTRL_MINUS NOTHING    ;
KEY_CBM_MINUS   = $DC       ;

KEY_POUND       = $5C       ; 
KEY_SHIFT_POUND = $A9       ; 
KEY_CTRL_POUND  = $1C       ;
KEY_CBM_POUND   = $A8       ;

KEY_HOME        = $13       ; Home
KEY_CLR         = $93       ; Clear Screen (Shift + Home)
; KEY_CTRL_HOME  NOTHING    ;
; KEY_CLR         = $93     ; Clear Screen (Shift + Home)

KEY_DEL         = $14       ; Delete / Backspace
KEY_INST        = $94       ; Insert
; KEY_SHIFT_DEL NOTHING     ; 
; KEY_INST        = $94     ; Insert 

; --- Second Row ---
; KEY_CONTROL   NONE
KEY_Q           = $51       ; 'Q'
KEY_SHIFT_Q     = $D1       ;
KEY_CTRL_Q      = $11       ; Cursor Down
KEY_CBM_Q       = $AB       ;

KEY_W           = $57       ; 'W'
KEY_SHIFT_W     = $D7       ;
KEY_CTRL_W      = $17       ;
KEY_CBM_W       = $B3       ;

KEY_E           = $45       ; 'E'
KEY_SHIFT_E     = $C5       ;
KEY_CTRL_E      = $05      ;
KEY_CBM_E       = $B1       ;

KEY_R           = $52       ; 'R'
KEY_SHIFT_R     = $D2       ;
KEY_CTRL_R      = $12       ;
KEY_CBM_R       = $B2       ;

KEY_T           = $54       ; 'T'
KEY_SHIFT_T     = $D4       ;
KEY_CTRL_T      = $14       ;
KEY_CBM_T       = $A3       ;

KEY_Y           = $59       ; 'Y'
KEY_SHIFT_Y     = $D9       ;
KEY_CTRL_Y      = $19       ;
KEY_CBM_Y       = $B7       ;

KEY_U           = $55       ; 'U'
KEY_SHIFT_U     = $D5       ;
KEY_CTRL_U      = $15       ;
KEY_CBM_U       = $B8       ;

KEY_I           = $49       ; 'I'
KEY_SHIFT_I     = $C9       ;
KEY_CTRL_I      = $09     ; TAB
KEY_CBM_I       = $A2       ;

KEY_O           = $4F       ; 'O'
KEY_SHIFT_O     = $CF       ;
KEY_CTRL_TOP    = $0F       ;
KEY_CBM_O       = $B9       ;

KEY_P           = $50       ; 'P'
KEY_SHIFT_P     = $D0       ;
KEY_CTRL        = $10       ;
KEY_CBM_P       = $AF       ;

KEY_AT          = $40       ; '@'
KEY_SHIFT_AT    = $BA       ;
KEY_CTRL_AT     = $00       ; HOW is this possible?
KEY_CBM_AT      = $A4       ;

KEY_STAR        = $2A       ; '*'
KEY_SHIFT_STAR  = $C0       ;
; KEY_CTRL_STAR NOTHING     ;
KEY_CBM_STAR    = $DF       ;

KEY_UP_ARROW    = $5E       ; '^'
KEY_SHIFT_UP_ARROW  = $DE   ;
; KEY_GREEN       = $1E     ;
KEY_CBM_UP_ARROW = $DE      ;

; KEY_RESTORE   NONE

; --- Third Row ---
KEY_STOP        = $03       ; Run / Stop
KEY_RUN         = $83       ; Run
; KEY_CTRL_RUN  NOTHING     ;
; KEY_RUN         = $83     ; Run

; KEY_SHIFT     NONE

KEY_A           = $41       ; 'A'
KEY_SHIFT_A     = $C1       ;
KEY_CTRL_A      = $01       ;
KEY_CBM_A       = $B0       ;

KEY_S           = $53       ; 'S'
KEY_SHIFT_S     = $D3       ;
; KEY_HOME        = $13     ; Home
KEY_CBM_S       = $AE       ;

KEY_D           = $44       ; 'D'
KEY_SHIFT_D     = $C4       ;
KEY_CLR_ENTRY   = $04       ;
KEY_CBM_D       = $AC       ;

KEY_F           = $46       ; 'F'
KEY_SHIFT_F     = $C6       ;
KEY_CTRL_F      = $06       ;
KEY_CBM_F       = $BB       ;

KEY_G           = $47       ; 'G'
KEY_SHIFT_G     = $C7       ;
KEY_CTRL_G      = $07       ;
KEY_CBM_G       = $A5       ;

KEY_H           = $48       ; 'H'
KEY_SHIFT_H     = $C8       ;
KEY_CTRL_H      = $08       ;
KEY_CBM_H       = $B4       ;

KEY_J           = $4A       ; 'J'
KEY_SHIFT_J     = $CA       ;
KEY_CTRL_J      = $0A       ;
KEY_CBM_J       = $B5       ;

KEY_K           = $4B       ; 'K'
KEY_SHIFT_K     = $CB       ;
KEY_CTRL_K      = $0B       ;
KEY_CBM_K       = $A1       ;

KEY_L           = $4C       ; 'L'
KEY_SHIFT_L     = $CC       ;
KEY_CTRL_L      = $0C       ;
KEY_CBM_L       = $B6       ;

KEY_COLON       = $3A       ; ':'
KEY_LEFTBRACKET = $5B       ; '['

KEY_SEMICOLAN   = $3B       ; ';'
KEY_RIGHTBRACKET = $5D      ; ']'
; KEY_RIGHT       = $1D     ; Cursor Right

KEY_EQUAL       = $3D       ; '='
; KEY_BLUE        = $1F     ;

KEY_RETURN      = $0D       ; Return / Enter
KEY_SHIFT_RETURN    = $8D   ;

; --- Fourth Row ---
; KEY_CBM       NONE
; KEY_SHIFT     NONE

KEY_Z           = $5A       ; 'Z'
KEY_SHIFT_Z     = $DA       ;
KEY_CTRL_Z      = $1A       ;
KEY_CBM_Z       = $AD       ;

KEY_X           = $58       ; 'X'
KEY_SHIFT_X     = $D8       ;
KEY_CTRL_X      = $18       ;
KEY_CBM_X       = $BD       ;

KEY_C           = $43       ; 'C'
KEY_SHIFT_C     = $C3       ;
KEY_CTRL_C      = $03       ; Run / Stop
KEY_CBM_C       = $BC       ;

KEY_V           = $56       ; 'V'
KEY_SHIFT_V     = $D6       ;
KEY_CTRL_V      = $16       ;
KEY_CBM_V       = $BE       ;

KEY_B           = $42       ; 'B'
KEY_SHIFT_B     = $C2       ;
KEY_CTRL_B      = $02       ;
KEY_CBM_B       = $BF       ;

KEY_N           = $4E       ; 'N'
KEY_SHIFT_N     = $CE       ;
KEY_CTRL_N      = $0E       ;
KEY_CBM_N       = $AA       ;

KEY_M           = $4D       ; 'M'
KEY_SHIFT_M     = $CD       ;
KEY_CTRL_M      = $0D       ; Return / Enter
KEY_CBM_M       = $A7       ;

KEY_COMMA       = $2C       ; ','
KEY_LESS_THAN   = $3C       ;
; KEY_CTRL_COMMA NOTHING    ;
; KEY_CBM_COMMA = $3C       ;

KEY_PERIOD      = $2E       ; '.'
KEY_GREATER_THAN = $3E      ;
; KEY_CTRL_PERIOD NOTHING   ;
; KEY_CBM_PERIOD = $3E      ;

KEY_SLASH       = $2F       ; '/'
KEY_QUESTION    = $3F       ;
; KEY_CTRL_SLASH NOTHING    ;
; KEY_CBM_SLASH = $3F       ;

; KEY_SHIFT     NONE
KEY_DOWN        = $11      ; Cursor Down
;KEY_UP        = $91       ; Cursor Down

KEY_RIGHT       = $1D       ; Cursor Right
; KEY_LEFT        = $9D       ; Cursor Left

; --- Fifth Row ---
KEY_SPACE       = $20       ; Spacebar
KEY_SHIFT_SPACE       = $A0       ; Spacebar

; --- 128 Top Row ---
KEY_ESC         = $1B       ; Escape (where applicable)
KEY_TAB         = $09       ; TAB
; KEY_ALT       NONE
; KEY_CAPS      NONE
KEY_HELP        = $84       ; HELP
KEY_HELP        = $84       ; HELP
KEY_LINEFEED    = $0A       ; LF
; KEY_40_80     NONE
; KEY_SCR       NONE
KEY_UP          = $91       ; Cursor Up
;KEY_DOWN        = $11       ; Cursor Down
KEY_LEFT        = $9D       ; Cursor Left
;KEY_RIGHT       = $1D       ; Cursor Right
;KEY_F1          = $85       ; F1 (Unshifted)
;KEY_F3          = $86       ; F3 (Unshifted)
;KEY_F5          = $87       ; F5 (Unshifted)
;KEY_F7          = $88       ; F7 (Unshifted)
