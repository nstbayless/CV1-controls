IFDEF CHECK_STAIRS_ENABLED
    ; sets varY to -varY if varW is 0 or 3.
    diag_flip:
        LDA varW
        BEQ diag_flip_rts
        CMP #$2
        BEQ diag_flip_rts
    ; perfom flip
    diag_flip_prf_x:
        SEC
        LDA #$0
        SBC varZ
        STA varZ
        LDA #$0
        SBC varX
        STA varX
    diag_flip_rts:
        RTS
        
    ; compress x into varZ masked with 0xfc.
    diag_compress_x:
        LDA varZ
        LSR
        AND #$7c
        STA varZ
        LDA varX
        REPT 7
            ASL
        ENDR
        AND #$80
        ORA varZ
        STA varZ
        RTS
        
    ; return value is in carry bit:
    ; SEC -- varZ < varBL,X or varBL,X not set.
    ; CLC -- varZ >= varBL,X and varBL,X set
    diag_compare_x:
        LDX varW
        LDA varBL,X
        BEQ sec_rts
        AND #$fc ; ignore the two data bits
        CMP varZ ; compare with varZ's (compressed) value.
        RTS
    sec_rts:
        SEC
        RTS
ENDIF