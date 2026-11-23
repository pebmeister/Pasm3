
        PC_SAVE = *

        * = 5
        MAT_A_PTR           .ds 2
        MAT_B_PTR           .ds 2
        MAT_R_PTR           .ds 2
        FIX16_WORK_A        .ds 4
        FIX16_WORK_B        .ds 4
        FIX16_WORK_RESULT   .ds 4
        FIX16_SCRATCH       .ds 8                   ; Dedicated extra room for 32-bit shifting
        FIX16_SIGN          .ds 1
        FIX16_A_PTR         .ds 2
        FIX16_B_PTR         .ds 2
        FIX16_RESULT_PTR    .ds 2
        FIXPTR              .ds 2
        FIX16_DIV_A_PTR     .ds 2
        FIX16_DIV_B_PTR     .ds 2
        FIX16_DIV_RES_PTR   .ds 2
        CUR_R_PTR           .ds 2
        CUR_A_PTR           .ds 2
        CUR_B_PTR           .ds 2
        VEC_IN_PTR          .ds 2
        VEC_OUT_PTR         .ds 2        
        CUR_V_PTR           .ds 2
        PROD                .ds 4
        TEMP16              .ds 2
        TMP                 .ds 2
        STR_PTR             .ds 2
            
        * = PC_SAVE

        FIX16_DIV_ZP =  FIX16_WORK_A
 