; FIX16_MAT4_MUL MAT_A, MAT_B, MAT_C
;
; Calculates:
;     MAT_C = MAT_A * MAT_B
;
; Requirements:
;     MAT_A, MAT_B, MAT_C each point to 64-byte matrices.
;     MAT_C must not overlap either input matrix.
;
; Uses:
;     FIX16_MUL for fixed-point multiplication
;     FIX16_ADD for fixed-point addition
