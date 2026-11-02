            .basic_hdr

            .inc "macros.asm"
            .inc "pagezero.asm"
            .inc "basic.asm"
            .inc "kernal.asm"
            jmp Start


PC_SAV      = *
            
    * = 20
            XCOORD      .ds 2
            LOC         .ds 2
            DX          .ds 2
            DY          .ds 2
            XS          .ds 2
            YS          .ds 2
            K1          .ds 2
            K2          .ds 2
            _D          .ds 2
            _Y          .ds 1
            TMP         .ds 2
            YCOL        .ds 2
            COLORPTR    .ds 2
            X0          .ds 2
            X1          .ds 2
            Y0          .ds 1
            Y1          .ds 1
            XDIST       .ds 2
            YDIST       .ds 2
            StartX      .ds 2
            COLOR       .ds 1

            _X          = XCOORD
            COUNTER     = LOC
            CURLOC      = DX
            XD          = YCOL

*= PC_SAV
            .inc "gr.asm"

Start
            jsr HGROn

            lda #COLOR_BLACK
            jsr _HGRBColor
            lda #COLOR_GREEN
            jsr _HGRFColor

            jsr HGRCls
        
            MOVE16I X0, 10       
            MOVE8I  Y0, 10
            MOVE16I X1, 200
            MOVE8I  Y1, 10
            jsr _Line

@end
            jmp @end           
        
