; ====================================================
; Minimal Fixed-Point Print Baseline
; ====================================================

        .basic_hdr

        jsr START

@MainWait:
        ;lda #COLOR_GREEN
        ;jsr _HGRFColor
       ; jsr TEST_MANUAL_LINE
        jmp @MainWait

; ============================================
; C64 3D WIREFRAME PYRAMID - MAIN ENTRY
; ============================================
START:
        ; 1. Initialize color variables and hardware
        lda #0
        sta COLOR

        lda #COLOR_BLACK
        jsr _HGRBColor

        lda #COLOR_WHITE
        jsr _HGRFColor

        jsr HGROn
        jsr HGRCls

MAIN_LOOP:
        ; 2. Animate rotation angles
        inc MY_ROT_X
        inc MY_ROT_Y

        ; 3. Build composed world matrix (TRS)
        jsr BUILD_WORLD_MATRIX

        ; 4. Transform and project all 5 pyramid vertices
        jsr RENDER_OBJECT

        ; 5. Clear screen for the next frame (if needed by your flow)
        ; jsr HGRCls

        jsr APPLY_VIEWPORT_SCALE

        ; 6. Draw all 8 wireframe edges using the verified _Line routine
        jsr DRAW_WIREFRAME
        
        ; 7. Frame sync / loop back
        jmp MAIN_LOOP

; ============================================
; BUILD_WORLD_MATRIX
; Composes the final WORLD_MATRIX from TRS 
; (Translation, Rotation, Scale) components.
; World = Translation * (Rotation * Scale)
; ============================================
BUILD_WORLD_MATRIX:
        ; 1. Set individual TRS component matrices using current variables
        SET_SCALE       MY_SCALE_X, MY_SCALE_Y, MY_SCALE_Z
        SET_ROTATION    MY_ROT_X, MY_ROT_Y, MY_ROT_Z
        SET_TRANSLATION MY_TRANS_X, MY_TRANS_Y, MY_TRANS_Z

        ; 2. Multiply Rotation by Scale: MAT_TEMP = Rotation * Scale
        CALL_MAT4_MUL   ROTATION_MATRIX, SCALING_MATRIX, MAT_TEMP

        ; 3. Multiply Translation by MAT_TEMP: WORLD_MATRIX = Translation * MAT_TEMP
        CALL_MAT4_MUL   TRANSLATION_MATRIX, MAT_TEMP, WORLD_MATRIX

        rts
        
; ============================================
; INITIAL TRS (Transform-Rotate-Scale) VALUES
; ============================================

; Rotation angles (0 to 255 for a full circle)
MY_ROT_X        .byte 32    ; Slight initial tilt so you see the 3D structure immediately
MY_ROT_Y        .byte 64    ; Rotated to show multiple faces
MY_ROT_Z        .byte 0

; Scale: 1.0 (format: .word fractional, integer)
MY_SCALE_X      .word $0000, $0001
MY_SCALE_Y      .word $0000, $0001
MY_SCALE_Z      .word $0000, $0001

; Translation: Center X/Y, push forward on Z (e.g., Z = 2.5)
MY_TRANS_X      .word $0000, $0000   ; X = 0.0 (centered horizontally)
MY_TRANS_Y      .word $0000, $0000   ; Y = 0.0 (centered vertically)
MY_TRANS_Z      .word $8000, $0002   ; Z = 2.5 (pushed away from camera into view)

; ============================================
; DIAGNOSTIC TEST: Draw a single manual line
; ============================================
TEST_MANUAL_LINE:
        MOVE16I X0, 10       
        MOVE8I  Y0, 10
        MOVE16I X1, 300
        MOVE8I  Y1, 10

        ; 3. Call gr library line drawer directly
        jsr _Line

        rts

; ============================================
; APPLY_VIEWPORT_SCALE
; Scales 16.16 fixed-point coordinates by focal length,
; translates to screen center (160, 100), and populates 
; the screen coordinate lookup tables.
; ============================================
; ============================================
; APPLY_VIEWPORT_SCALE
; Scales projected vertex coordinates by focal length,
; translates to screen center (160, 100), and populates 
; the screen coordinate lookup tables.
; ============================================
APPLY_VIEWPORT_SCALE
        ldx #0
@scale_loop
        stx VEC_INDEX

        ; ----------------------------------------
        ; 1. Process X Coordinate for Vertex X
        ; ----------------------------------------
        lda PROJ_X_INT_H,x
        
        ; Apply focal length scale via shifts
        asl a
        asl a
        asl a
        asl a
        
        ; Add Screen Center X offset (160 = $A0)
        clc
        adc #160
        sta SCREEN_X_H_VAL
        
        lda #0
        sta SCREEN_X_L_VAL

        ; Store into X coordinate tables for this vertex
        ldx VEC_INDEX
        lda SCREEN_X_L_VAL
        sta SCREEN_X_L,x
        lda SCREEN_X_H_VAL
        sta SCREEN_X_H,x

        ; ----------------------------------------
        ; 2. Process Y Coordinate for Vertex X
        ; ----------------------------------------
        ldx VEC_INDEX
        lda PROJ_Y_INT_H,x
        
        ; Apply focal length scale via shifts
        asl a
        asl a
        asl a
        asl a
        
        ; Add Screen Center Y offset (100 = $64)
        clc
        adc #100
        sta SCREEN_Y_VAL

        ; Store into Y coordinate table for this vertex
        ldx VEC_INDEX
        lda SCREEN_Y_VAL
        sta SCREEN_Y_LIST,x

        ; ----------------------------------------
        ; 3. Loop Control
        ; ----------------------------------------
        ldx VEC_INDEX
        inx
        cpx #NUM_VERTICES
        bne @scale_loop
        rts

; ============================================
; VIEWPORT SCALING VARIABLES & TABLES
; ============================================
NUM_VERTICES      = 5         ; Total vertices in your pyramid

VEC_INDEX         .ds 1       ; Current vertex loop counter
SCREEN_X_H_VAL    .ds 1       ; Temporary high byte for scaled X
SCREEN_X_L_VAL    .ds 1       ; Temporary low byte for scaled X
SCREEN_Y_VAL      .ds 1       ; Temporary Y coordinate value

; --- Source Arrays (Output from your 3D projection math) ---
PROJ_X_INT_H      .ds 5       ; Integer high byte of projected X per vertex
PROJ_Y_INT_H      .ds 5       ; Integer high byte of projected Y per vertex

; --- Destination Tables (Read by DRAW_WIREFRAME) ---
;SCREEN_X_L        .ds 5       ; Low bytes of final screen X
;SCREEN_X_H        .ds 5       ; High bytes of final screen X
;SCREEN_Y_LIST     .ds 5       ; Final screen Y coordinates