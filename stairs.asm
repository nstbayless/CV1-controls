IFDEF CHECK_STAIRS_ENABLED
stair_checking_subroutine:
    ; can latch onto stairs above this;
    ; actually, this has to be exactly 8 as currently written.
    epsilon=#$8

    ; pass through stairs when rising.
    LDA player_vspeed_direction
    BEQ stairs_rts

    IFDEF CATCH_STAIRS
        ; fall through if holding down
        LDA button_down
        AND #$04
        BNE stairs_rts
    ENDIF
    
    IFDEF LATCH_STAIRS
        ; fall through unless holding up
        LDA button_down
        AND #$08
        BEQ stairs_rts
    ENDIF
    
    IFDEF STAIR_STACK_VARIABLES
        ; put variables on stack back into memory
        LDA $4
        PHA
        LDA $5
        PHA
        LDA $6
        PHA
        IFDEF EXTENDED_STAIR_BUFFER
            LDA stair_data_buffer+$8
            PHA
            LDA stair_data_buffer+$9
            PHA
        ENDIF
    ENDIF

    IFNDEF load_stair_data
        ; get the stair data array start pointer.
        LDA current_stage
        ASL
        TAY
        IFNDEF read_stage_stairs_base_from
            ; load from stage_stairs_base statically
            LDA stage_stairs_base,Y
            STA varE
            LDA stage_stairs_base+1,Y
            STA varE+1
        ELSE
            ; if we don't know at compile time where the stage_stairs_base is, we can load it
            ; from this code which we know accesses it. This is helpful for hacks which may move the
            ; stage_stairs_base pointer.
            LDA read_stage_stairs_base_from

            ; reuse varBL,varBL+1 to hold this pointer.
            STA varBL

            LDA read_stage_stairs_base_from+1
            STA varBL+1

            LDA (varBL),Y
            STA varE
            INY
            LDA (varBL),Y
            STA varE+1
        ENDIF
    ENDIF
    
    ; zero store.
    LDA #$0
    STA varBL
    STA varBR
    STA varTR
    STA varTL
    
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
            IFDEF FLOATING_STAIRCASE_STAGE_SEVEN_FIX
                LDA current_stage
                CMP #$7
                BNE pre_load_low_byte
                CPY #$10
                BCC pre_load_low_byte
                LDA stage_seven_extradata-$10,Y
                ; guaranteed branch
                BCC post_load_low_byte
            stage_seven_extradata:
                ; two extra staircases
                db $74
                db $C1
                db $56
                db $D9
                db $0
            ENDIF
            
        pre_load_low_byte:
            ; load stair data low-byte
            LDA (varE),Y
        ENDIF
    post_load_low_byte:
        BNE check_substage
        JMP stair_loop_end
        
        IFNDEF external_stairs_rts
        ; squeeze a jumpable RTS into this opening.
        stairs_rts:
            RTS
        ELSE
            stairs_rts=external_stairs_rts
        ENDIF
    
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
            IFDEF FLOATING_STAIRCASE_STAGE_SEVEN_FIX
                LDA current_stage
                CMP #$7
                BNE pre_load_high_byte
                LDA current_substage
                BEQ pre_load_high_byte
                CPY #$10
                BMI pre_load_high_byte
                LDA stage_seven_extradata-$10,Y
                JMP post_load_high_byte
            ENDIF
            ; load stair data high-byte
            pre_load_high_byte:
            LDA (varE),Y
        ENDIF
        post_load_high_byte:
        
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
        BNE jmp_stair_loop_begin_yinc
        
        ; check that dy-dx < epsilon
        LDA varOD
        CMP #epsilon ; epsilon; come back to this later.
        BCS jmp_stair_loop_begin_yinc ;  y-x >= epsilon
        
        IFDEF SPECIAL_STAIRCASE_THR_CRYPT
            ; fix for some phantom staircases in The Holy Relics' crypt
            LDA current_stage
            CMP #$D
            BNE skip_crypt_a
            CPY #$9
            BEQ jmp_stair_loop_begin_yinc
            CPY #$3
            BEQ jmp_stair_loop_begin_yinc
            skip_crypt_a:
        ENDIF
        
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
        
        ; swap direction to horizontally opposite
        LDA varW
        EOR #$2
        STA varW
        
        JSR diag_compare_x
        BCC jmp_stair_loop_begin_yinc
        
        store_xpos_nset:
        ; (X is varW, set in diag_compare_x)
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
        IFDEF EXTENDED_STAIR_BUFFER
            PLA
            STA stair_data_buffer+$9
            PLA
            STA stair_data_buffer+$8
        ENDIF
        PLA
        STA $6
        PLA
        STA $5
        PLA
        STA $4
    ENDIF

    ; ~~ check if any varBL,X set and marked as catching ~~
    LDX #$0
    
    IFNDEF SPECIAL_STAIRCASES_THR
        mincheck_loop_start_bne_intermediate:
    ENDIF
    mincheck_loop_start:
        LDA varBL,X
        TAY
        AND #$1 ; was this one set?
        BEQ mincheck_loop_next_beq_intermediate
        TYA
        AND #$2 ; was this one marked catching?
        BEQ mincheck_loop_next_beq_intermediate
        
    stair_check_butterzone:
        ; found a successful match -- This is the butterzone.
        ; (a true stair collision)
        
        IFDEF SPECIAL_STAIRCASES_THR
            ; there are phantom staircases The Holy Relics
            ; we ignore the screens they appear on completely.
            LDY #$0
            loop_phantom_stair_begin:
            ; compare stage
            LDA thr_staircase_table,Y
            BEQ loop_phantom_stair_end
            AND #$1f
            CMP current_stage
            BNE loop_phantom_stair_next:
            ; compare substage
            LDA thr_staircase_table,Y
            IFDEF lsr_four
                JSR lsr_four
            ELSE
                LSR
                LSR
                LSR
                LSR
            ENDIF
            LSR
            AND #$1
            CMP current_substage
            BNE loop_phantom_stair_next
            ; compare screen 1
            LDA thr_staircase_table+1,Y
            AND #$0f
            CMP player_x+1
            IFDEF THR
                ; branch would be too far; this is equivalent
                BEQ some_rts_thr
            ELSE
                BEQ mincheck_loop_end
            ENDIF
            ; compare screen 2
            LDA thr_staircase_table+1,Y
            IFDEF lsr_four
                JSR lsr_four
            ELSE
                LSR
                LSR
                LSR
                LSR
            ENDIF
            AND #$0f
            CMP player_x+1
            BEQ mincheck_loop_end
            
            ; next loop
            loop_phantom_stair_next:
            INY
            INY
            ; guaranteed jump
            BNE loop_phantom_stair_begin
            
            mincheck_loop_next_beq_intermediate:
            BEQ mincheck_loop_next
            
            mincheck_loop_start_bne_intermediate:
            BNE mincheck_loop_start
            
            some_rts_thr:
            RTS
            
            ; data
            thr_staircase_table:
                ; woods staircases
                db $22
                db $12
                ; tower staircase
                db $25
                db $00
                ; river staircases
                db $0B
                db $34
                db $0B
                db $56
                ; crypt staircases
                db $2E
                db $04
                db $10
                db $00
                ; EOL
                db $0 
            loop_phantom_stair_end:
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
        CMP #STAIR_EXIT_STAGE_TOP+1
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
        ; can skip this if player is already grid-aligned.
        LDX player_facing
        INX
        TYA ; player_x , possibly -player_x % 10
        AND #$07
        BEQ skip_set_state_b
        INC player_y
        CMP #$07
        BEQ skip_set_state_b
        DEC player_y
        DEC player_y
        CMP #$01
        BEQ skip_set_state_b
        INC player_y
        STX player_state_b
        
        skip_set_state_b:
        
        ; set on stair
        LDA #$1
        STA player_on_stairs
        LDA #$4
        STA player_state_a
        
        ; zero vspeed
        LDA #$A2
        STA player_vspeed_magnitude
        RTS
        
    IFNDEF SPECIAL_STAIRCASES_THR
        mincheck_loop_next_beq_intermediate:
    ENDIF
    mincheck_loop_next:
        INX
        CPX #$4
        BNE mincheck_loop_start_bne_intermediate
    mincheck_loop_end:
        RTS
ENDIF