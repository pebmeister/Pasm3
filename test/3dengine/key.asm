; ============================================
; COMMODORE 64 KERNAL PETSCII KEYCODE EQUATES
; Returned by KERNAL GETIN ($FFE4) or standard input
; ============================================

; --- Directional & Cursor Keys ---
LEFT_KEY        = $9D       ; Cursor Left
RIGHT_KEY       = $1D       ; Cursor Right
UP_KEY          = $91       ; Cursor Up
DOWN_KEY        = $11       ; Cursor Down

; --- Control & Editing Keys ---
KEY_RETURN      = $0D       ; Return / Enter
KEY_SPACE       = $20       ; Spacebar
KEY_DEL         = $14       ; Delete / Backspace
KEY_INST        = $94       ; Insert
KEY_HOME        = $13       ; Home
KEY_CLR         = $93       ; Clear Screen (Shift + Home)
KEY_STOP        = $03       ; Run / Stop

; --- Function Keys ---
KEY_F1          = $85       ; F1 (Unshifted)
KEY_F3          = $86       ; F3 (Unshifted)
KEY_F5          = $87       ; F5 (Unshifted)
KEY_F7          = $88       ; F7 (Unshifted)
KEY_F2          = $89       ; F2 (Shifted)
KEY_F4          = $8A       ; F4 (Shifted)
KEY_F6          = $8B       ; F6 (Shifted)
KEY_F8          = $8C       ; F8 (Shifted)

; --- Common Alphanumeric Shortcuts ---
KEY_ESC         = $1B       ; Escape (where applicable)
KEY_PLUS        = $2B       ; '+'
KEY_MINUS       = $2D       ; '-'