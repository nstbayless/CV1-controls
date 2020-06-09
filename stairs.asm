IFDEF CHECK_STAIRS_ENABLED

    ; can latch onto stairs above this;
    ; actually, this has to be exactly 8 as currently written.
    epsilon=#$8

    ; pass through stairs when rising.
    LDA player_vspeed_direction
    BEQ jmp_to_air_standard

    IFDEF CATCH_STAIRS
        ; fall through if holding down
        LDA button_down
        AND #$04
        BNE jmp_to_air_standard
    ENDIF
    
    IFDEF LATCH_STAIRS
        ; fall through unless holding up
        LDA button_down
        AND #$08
        BEQ jmp_to_air_standard
    ENDIF
    
    IFDEF STAIR_STACK_VARIABLES
        ; put variables on stack back into memory
        LDA $4
        PHA
        LDA $5
        PHA
        LDA $6
        PHA
    ENDIF
    
    ; zero store.
    LDA #$0
    STA varBL
    STA varBR
    STA varTR
    STA varTL

    ; 
    IFNDEF load_stair_data
        LDA current_stage
        ASL
        TAX
        LDA stage_stairs_base,X
        STA varE
        LDA stage_stairs_base+1,X
        STA varE+1
    ENDIF
    
    LDY #$FE
    stair_loop_begin:
        INY
    stair_loop_begin_yinc:
        INY
        IFDEF load_stair_data
            ; retrieves stair data
            ; low byte in A
            JSR load_stair_data
        ELSE
            ; load stair data low-byte
            LDA (varE),Y
        ENDIF
        BNE check_substage
        JMP stair_loop_end
    
    check_substage:
        TAX
        ; check substage matches
        LSR
        LSR
        AND #$01
        CMP current_substage
        BNE stair_loop_begin
        ; store direction of stair
        TXA
        AND #$03
        STA varW
        
        ; stair directions
        STAIR_BL=0
        STAIR_BR=1
        STAIR_TR=2
        STAIR_TL=3
        
    stair_loop_calc_y:
        ; store y value of stair 
        TXA
        AND #$f0
        STA varY
        
    stair_loop_calc_dy:
        ; calculate y difference (player_y - y)
        SEC
        LDA player_y
        SBC varY
        STA varY
        LDA #$0
        SBC #$0
        STA varYY
        
    stair_loop_calc_x:
        
        ; store x value of stair
        INY
        IFDEF load_stair_data
            ; load stair data high-byte
            JSR load_stair_data
        ELSE
            ; load stair data high-byte
            LDA (varE),Y
        ENDIF
        
        TAX ; high byte of stair
        
        ; calculate x (low byte)
        AND #$f8
        STA varZ
        
        ; add 8 for direction 2. (not sure why CV does this...)
        LDA varW
        CMP #$2
        BNE +
        
        ; direction 2 ------------
            LDA #$7
            ; SEC ; SEC already guaranteed
            ADC varZ
            STA varZ
            
            ; x (high byte)
            TXA ; high byte of stair
            ADC #$0
            TAX
        
      + TXA ; high byte of stair (+8 if direction 2)
        AND #$7
        STA varX
        
    stair_loop_calc_dx:
        ; x - player_x
        LDA varZ
        SEC
        SBC player_x
        STA varZ
        LDA varX
        SBC player_x+1
        STA varX
        
        ; flip x depending on diagonal
        JSR diag_flip
        
        ; varZ,varX is now player_x - x, (or x-player_x if flipped).
        
    stair_loop_calc_dydx:
        ; dy-dx
        SEC
        LDA varY
        SBC varZ
        STA varOD
        ; varOD now stores dy-dx (low byte)
        
    stair_loop_check_dydx:
        ; check that 0 <= dy-dx < 0x100
        ; (check high byte)
        LDA varYY
        SBC varX
        BNE stair_loop_begin_yinc
        
        ; check that dy-dx < epsilon
        LDA varOD
        CMP #epsilon ; epsilon; come back to this later.
        BCS stair_loop_begin_yinc ;  y-x >= epsilon
        
        ; ~~ check for other intercepting stairs ~~
        ; flip dx to match stair's direction
        
    stair_loop_check_intercepts:
        ; flip dx?
        LDX varW
        DEX
        DEX
        BEQ stair_catch_skip_flipx 
        DEX
        BEQ stair_catch_skip_flipx
        JSR diag_flip_prf_x
        stair_catch_skip_flipx:
        
        ; dx positive or negative?
        LDX varX
        BMI stair_negx
        
        ; what to do depends on positive vs negative.
        
        ; positive: we can potentially land on this stair.
        stair_posx:
        JSR diag_compress_x
        JSR diag_compare_x
        BCC jmp_stair_loop_begin_yinc
        
        store_xpos_set:
        ; store x position in varBL,X
        ; or'd with #$3 to mark (a) set, and (b) yes landing. 
        LDA varZ
        ORA #$3
        ; (X is varW, set in diag_compare_x)
        STA varBL,X
        
        jmp_stair_loop_begin_yinc:
        JMP stair_loop_begin_yinc
        
        stair_negx:
        ; get absolute value of dx, then compress it
        JSR diag_flip_prf_x
        JSR diag_compress_x
        JSR diag_compare_x
        BCC jmp_stair_loop_begin_yinc
        
        store_xpos_nset:
        ; (X is varW, set in diag_compare_x)
        TXA
        ; swap direction to horizontally opposite
        EOR #$2
        TAX
        LDA varZ
        ORA #$1
        STA varBL,X
        ; next loop (BNE guaranteed.)
        BNE jmp_stair_loop_begin_yinc
    
    IFDEF SECONDARY_BANK6_OFFSET
        JMP stair_loop_end
        FROM SECONDARY_BANK6_OFFSET
    ENDIF
    
stair_loop_end:

    IFDEF STAIR_STACK_VARIABLES
        ; put variables on stack back into memory
        PLA
        STA $4
        PLA
        STA $5
        PLA
        STA $6
    ENDIF

    ; ~~ check if any varBL,X set and marked as catching ~~
    LDX #$0
    mincheck_loop_start:
        LDA varBL,X
        TAY
        AND #$1 ; was this one set?
        BEQ mincheck_loop_next
        TYA
        AND #$2 ; was this one marked catching?
        BEQ mincheck_loop_next
        
    stair_check_butterzone:
        ; found a successful match -- This is the butterzone.
        ; (a true stair collision)
        
        IFDEF SPECIAL_STAIRCASE_THR_WOODS
            ; there are phantom staircases in the woods
            ; we have to ignore them.
            LDA current_stage
            CMP #$2
            BNE skip_woods
            LDA current_substage
            BEQ skip_woods
            LDA player_x+1
            BNE mincheck_loop_end
            skip_woods:
        ENDIF
        
        ; set stair direction
        STX player_stair_direction
        
        ; modify player y to be exactly on stair.
        SEC 
        
        LDY player_x
        TXA
        AND #$1
        ; (temporarily set to JMP for debug purposes)
        BNE skip_neg_x
        
        ; swap x (calc 0x10 - x)
        SEC
        LDA #$10
        SBC player_x
        TAY
        
        skip_neg_x:
        TYA
        SEC
        SBC player_y
        
        ; A now holds player_x-player_y
        AND #$7
        ; A now holds (player_x-player_y) % 8
        BEQ skip_mody
        SEC
        SBC #$8
        ; subtract from player_y
        
        skip_mody:
        CLC
        ADC player_y
        
        ; if player would end up out of bounds, abort.
        CMP #$31
        BCC mincheck_loop_end
        CMP #$D0
        BCS mincheck_loop_end
        
        STA player_y
        
        ; set vertical direction for stairs
        TXA
        ASL
        CLC
        ADC player_facing
        STA player_vspeed_direction
        
        ; have to set walking on x (player_state_b) to avoid getting stuck.
        LDX player_facing
        INX
        STX player_state_b
        
        skip_set_state_b:
        ; set on stair
        LDA #$1
        STA player_on_stairs
        LDA #$4
        STA player_state_a
        
        ; zero hspeed
        LDA #$A2
        STA player_vspeed_magnitude
        
        ; guaranteed jump
        BNE air_standard
        
    mincheck_loop_next:
        INX
        CPX #$4
        BNE mincheck_loop_start
    mincheck_loop_end:
ENDIF