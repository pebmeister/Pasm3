
        PC_SAVE = *

        * = 5
        ; Used br gr
        XCOORD              .ds 2
        LOC                 .ds 2
        DX                  .ds 2
        DY                  .ds 2
        XS                  .ds 2
        YS                  .ds 2
        K1                  .ds 2
        K2                  .ds 2
        _D                  .ds 2
        _Y                  .ds 1
        TMP                 .ds 2
        YCOL                .ds 2
        COLORPTR            .ds 2
        X0                  .ds 2
        X1                  .ds 2
        Y0                  .ds 1
        Y1                  .ds 1
        XDIST               .ds 2
        YDIST               .ds 2
        StartX              .ds 2
        COLOR               .ds 1
        _X                  = XCOORD
        COUNTER             = LOC
        CURLOC              = DX
        XD                  = YCOL

        ; 
        MAT_A_PTR           .ds 2
        MAT_B_PTR           .ds 2
        MAT_R_PTR           .ds 2
        FIX16_WORK_A        .ds 4
        FIX16_WORK_B        .ds 4
        FIX16_WORK_RESULT   .ds 4
        FIX16_SCRATCH       .ds 8
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
        STR_PTR             .ds 2
        ROT_OUT_PTR         .ds 2    
        ROT_X_ANGLE         .ds 1
        ROT_Y_ANGLE         .ds 1
        ROT_Z_ANGLE         .ds 1       
        ROT_XYZ_AX          .ds 1
        ROT_XYZ_AY          .ds 1
        ROT_XYZ_AZ          .ds 1
        XFORM_OUT_PTR       .ds 2
        FINAL_PTR           .ds 2
        TXPTR               .ds 2

        FIX16_DIV_ZP        .ds 20
        
        
        
        * = PC_SAVE

 