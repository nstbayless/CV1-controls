; Build instructions: please se README_BUILD.md

INCLUDE "pre.asm"

INCLUDE "defs.asm"

INCLUDE "inc-opt.asm"

; ------------------------------------------------------------------------------
BANK 6
BASE $8000

FROM $934c:

player_step_dispatch:
    SUPPRESS
        db 0
    ENDSUPPRESS
    
; --------------------------------------
; player jump table
FROM $936c
    player_jump_table:

FROM $936e
    ; 1: jump 
    dw custom_handle_jump
    
SKIP 4
    ; 4: stair
    dw custom_handle_stair
    
IFDEF NO_AIRCONTROL
    SKIP 4
        ; 7: falling
        dw custom_handle_falling
ENDIF
    
; --------------------------------------
; inside player's cliff-falling routine.
FROM $93ca

IFNDEF NO_AIRCONTROL
    ; switch to jumping.
    LDA #$0D
    STA player_v_animation_counter
    LDA #$01
    STA player_state_a
    JMP custom_handle_cliff_drop
    NOP
    NOP
ENDIF

; --------------------------------------
; Originally this code calculated which direction
; player should move in while being knocked back.
; Now it jumps to a subroutine below.
FROM $970b

    JSR custom_knockback
    NOP
    NOP
    NOP
    NOP
    NOP

IFDEF CHECK_STAIRS_ENABLED
    ; change the y value for exiting stage top
    FROM $9FFA
        FILLVALUE #$30
        COMPARE
        db #STAIR_EXIT_STAGE_TOP
        ENDCOMPARE
    
    FROM $A000
        FILLVALUE #$CF
        COMPARE
        db #STAIR_ENTER_STAGE_BOTTOM
        ENDCOMPARE
ENDIF

; beginning of a jump
FROM $940F
    IFDEF WEIGHT_HORIZONTAL
        IFNDEF NO_AIRCONTROL
            JSR custom_begin_jump
        ENDIF
    ENDIF

; --------------------------------------
; location of some unused space.
FROM BANK6_OFFSET

; check that we only overwrite the value $FF
FILLVALUE $FF
COMPARE

IFNDEF NO_AIRCONTROL
    IFDEF WEIGHT_HORIZONTAL
        momentum=subweapon
        lsr_four:
            LSR
            LSR
            LSR
            LSR
            RTS
        custom_begin_jump:
            ; (original code)
            STA $4DC
            
            ; set momentum
            LDA momentum
            AND #$0f
            STA momentum
            LDA button_down
            AND #$01
            BNE custom_begin_jump_right
            LDA button_down
            AND #$02
            BNE custom_begin_jump_left
            RTS
        custom_begin_jump_left:
            LDA #$70
            ; guaranteed jump
            BNE +
        custom_begin_jump_right:
            LDA #$90
          + ORA momentum
            STA momentum
            RTS
        weight_lookup_table:
            db 7
            db 3
            db 3
            db 1
            db 1
            db 1
            db 0
        weight_mincheck:
            LDA $0
            CMP #$ff
            BNE add_momentum
            INC $0
            ; guaranteed jump
            BEQ add_momentum
        weight_maxcheck:
            LDA $0
            CMP #$01
            BNE add_momentum
            DEC $0
            ; guaranteed jump
            BEQ add_momentum
    ENDIF
ENDIF

jmp_to_air_standard:    
    ; return to original code
    JMP player_air_code

custom_handle_jump:
    JSR can_control
    BNE jmp_to_air_standard
    
; set direction in mid-air
IFNDEF NO_AIRCONTROL
        IFDEF WEIGHT_HORIZONTAL_POOR
            ; skip update on frames not divisible by 4
            LDA player_vspeed_magnitude
            AND #$3
            BNE check_v_cancel
        ENDIF
        
        IFDEF WEIGHT_HORIZONTAL
            ; fairly involved math for weight
            LDX #$80
            STX player_state_b
            LDA momentum
            PHA ; store momentum/subweapon
            AND #$f0
            BEQ update_momentum
            STA momentum
            BMI +
            INX
          + INX
            STX player_state_b
            
            ; reset speed to 0 except on some frames, depending on momentum
            
            ; absolute value
            LDA momentum
            BPL +
            SEC
            LDA #$0
            SBC momentum
          + JSR lsr_four
            TAX
            LDA timer
            AND weight_lookup_table-1,X
            BEQ update_momentum
            LDA #$80
            STA player_state_b
            
        update_momentum: ; increase/decrease momentum
        
            ; determine hold direction
            LDA button_down
            AND #$3
            TAX
            BNE +
            ; not held; set to 1 or -1 depending on *momentum*
            LDA momentum
            AND #$f0
            BEQ skip_weight
            BMI neg_momentum
            LDA #$ff
            db $2C; skip (BIT trick)
        neg_momentum:
            LDA #$01
            STA $0
            
            ; guaranteed jump
            BNE clamp_momentum
            
            ; set to 1 or -1 depending on direction
          + TXA
            AND #$1
            STA $0
            TXA
            LSR
            SEC
            SBC $0
            STA $0
            ; get upper 4 bytes of momentum in lower
        clamp_momentum:
            PLA
            PHA
            LSR
            LSR
            LSR
            LSR
            STA momentum
            
            ; clamp to -7,+7
            CMP #$9
            BEQ weight_mincheck
            CMP #$7
            BEQ weight_maxcheck
        add_momentum:
            CLC
            LDA momentum
            ADC $0
            
            ; sleight of hand
            ASL
            ASL
            ASL
            ASL
            STA $0
            
            ; restore subweapon
            PLA
            AND #$0f
            ORA $0
            PHA
            
        skip_weight:
            ; restore momentum / subweapon
            PLA
            STA momentum;
        fin_momentum:
        ENDIF
        
        LDA button_down
        LDY player_facing
        AND #$03
        BNE check_right
        IFDEF WEIGHT_HORIZONTAL
            ; guaranteed jump
            BEQ check_v_cancel
        ELSE
            LDA #$80
            STA player_state_b
            ; guaranteed jump
            BNE check_v_cancel
        ENDIF
    check_right:
        LDX #$00
        LSR
        ; guaranteed jump
        BCC turn_left
    turn_right:
        STX player_facing
        
        IFDEF WEIGHT_HORIZONTAL_POOR
            ; must pass through zero-hspeed first
            LDA player_state_b
            CMP #$82 ; air left?
            BNE +
        weight_store_hspeed_zero:
            LDA #$80
            STA player_state_b
            ; guaranteed jump
            BNE check_reset_facing
            +
        ENDIF
        
        IFNDEF WEIGHT_HORIZONTAL
            LDX #$81
            STX player_state_b
            ; guaranteed jump
            BNE check_reset_facing
        ELSE
            BCS check_reset_facing
        ENDIF
    turn_left:
        INX
        STX player_facing
        
        IFDEF WEIGHT_HORIZONTAL_POOR
            ; must pass through zero-hspeed first
            LDA player_state_b
            CMP #$81 ; air-right?
            BEQ weight_store_hspeed_zero
        ENDIF
        
        IFNDEF WEIGHT_HORIZONTAL
            LDX #$82
            STX player_state_b
        ENDIF
    check_reset_facing:
        LDA player_state_atk
        CMP #$00
        BEQ check_v_cancel
        STY player_facing
ENDIF

    check_v_cancel:
IFNDEF NO_VCANCEL
    LDA button_down
    AND #$80
    BNE check_stair_catch
    LDA player_vspeed_direction
    BNE check_stair_catch ; OPTIMIZE: could actually jump a few instructions later.
    
    ; dont v-cancel too early (i.e. when rising too fast)
    LDA player_vspeed_magnitude
    CMP #$95
    BMI check_stair_catch
    
    IFDEF WEIGHT_VCANCEL
        ; don't v-cancel too late (i.e. when rising slowly)
        CMP #$9A
        BPL check_stair_catch
    ENDIF
    
    JSR v_cancel
    LDA #$17
    STA player_v_animation_counter
ENDIF
    
check_stair_catch:
    IFDEF CHECK_STAIRS_ENABLED
        JSR stair_checking_subroutine
    ENDIF
    JMP player_air_code

IFDEF NO_AIRCONTROL
    custom_handle_falling:
    IFDEF CHECK_STAIRS_ENABLED
        LDA player_vspeed_direction
        PHA
        LDA #$1
        STA player_vspeed_direction
        DEC player_y
        JSR stair_checking_subroutine
        PLA
        STA player_vspeed_direction
    ENDIF
    LDA player_state_a
    CMP #$7
    BNE external_stairs_rts
    IFDEF CHECK_STAIRS_ENABLED
        INC player_y
    ENDIF
    JMP player_fall_code
external_stairs_rts:
    RTS
ENDIF

INCLUDE "stairs.asm"

IFDEF QUINTARY_BANK6_OFFSET
    FROM QUINTARY_BANK6_OFFSET
ENDIF

INCLUDE "stairs_helper.asm"
    
IFDEF TERTIARY_BANK6_OFFSET
    FROM TERTIARY_BANK6_OFFSET
ENDIF

; ------------------------------------
custom_knockback:
    LDA player_hp
    BEQ knockback_standard
    JSR can_control
    BNE knockback_standard
    LDA player_vspeed_magnitude
    CMP #$B3
    BPL knockback_standard
    LDA player_vspeed_direction
    BEQ knockback_standard
    
    IFDEF CHECK_STAIRS_ENABLED
        ; allow landing on stairs during a knockback.
        JSR stair_checking_subroutine
        LDA player_state_a
        CMP #$5
        BEQ +
            ; 30 iframes for getting hit.
            LDA #$30
            STA player_iframes
            ; if the stun timer is not negative here, the game totally freaks out.
            LDA #$00
            STA player_stun_timer
            RTS
        +
    ENDIF
    
    IFNDEF NO_AIRCONTROL
        LDA button_down
        AND #$03
        CMP #$03
        BNE RETURNB
        ; if holding L+R, do standard knockback behaviour for lack of any other reasonable option.
    ENDIF
    
; ------------------------------------
knockback_standard:
    ; this is the original knockback code.
    LDA player_facing
    CLC
    ADC #$01
    EOR #$03
RETURNB:
    ; value of A is important.
    RTS
    
; ------------------------------------
; pure function, determines whether or not can currently control.
; (Z if can control, z if cannot)
can_control:
    ; illegible, but this produces correct behaviour
    LDA time_remaining_a
    BNE +
    LDA time_remaining_b
    BEQ ++
  + LDA player_hp
    BEQ ++            
    LDA game_mode
 ++ CMP #$05
    RTS
    
IFNDEF NO_AIRCONTROL
    ; ------------------------------------
    cutscene_fall:
        STA player_hspeed_1
        LDX player_facing
        INX
        STX player_state_b
    set_falling:
        ; note that setting falling causes 
        LDA #$07
        STA player_state_a
        RTS
        
    ; ------------------------------------
    custom_handle_cliff_drop:
        JSR can_control
        BNE cutscene_fall
        
        ; if the player stun timer is not negative when a jump begins,
        ; the game totally freaks out.
        LDX #$00
        STX player_stun_timer
        INX
        STX player_vspeed_direction
        LDA vspeed_map
        BNE +
        LDA #$9B
        STA vspeed_map
        
        +
        ; guaranteed jump
        BNE store_vspeed_magnitude
ENDIF

; ------------------------------------
IFNDEF NO_VCANCEL
v_cancel:
    IFDEF WEIGHT_VCANCEL
        LDA #$9A
    ELSE
        LDA #$01
        STA player_vspeed_direction
        LDA #$A2
    ENDIF
ENDIF

store_vspeed_magnitude:
    STA player_vspeed_magnitude
    RTS
    
IFDEF QUARTIARY_BANK6_OFFSET
    FROM QUARTIARY_BANK6_OFFSET
ENDIF
    
; ------------------------------------
control_handle_stair:
    IFDEF FLOATING_STAIRCASE_STAGE_SEVEN_FIX
        ; special code to fall off floating stairs on stage seven.
        LDA current_stage
        CMP #$7
        BNE standard_control_handle_stair
        LDA current_substage
        BEQ standard_control_handle_stair
        LDA player_x+1
        CMP #$1
        BNE standard_control_handle_stair
        
        ; can't fall off while attacking
        LDA player_state_b
        AND #$40
        BNE standard_control_handle_stair
        
        LDA player_state_atk
        BNE standard_control_handle_stair
        
        ; can fall off at these specific x values.
        LDA player_x
        CMP #$BF
        BEQ fall_off_floating_stairs
        CMP #$C0
        BEQ fall_off_floating_stairs
        CMP #$DF
        BEQ fall_off_floating_stairs
        CMP #$E0
        BEQ fall_off_floating_stairs
        CMP #$E1
        BNE standard_control_handle_stair
        fall_off_floating_stairs:
            JSR begin_jump
            JMP control_fall_through_stairs
    ENDIF

standard_control_handle_stair:
    ; check if jump is pressed
    LDA button_press
    AND #$80
    BEQ jump_to_stairs
    LDA player_state_atk
    BNE jump_to_stairs
    JSR begin_jump
    
    ; check if down is held while jumping, fall through
    LDA button_down
    AND #$04
    BEQ control_handle_stair_nofall
    ; fall through
    
control_fall_through_stairs:
    LDA #$A0
    STA player_vspeed_magnitude
    LDA #$1
    STA player_vspeed_direction
    ; arrest horizontal motion
    LDA #$80
    STA player_state_b
    
control_handle_stair_nofall:
    LDA #$01
    STA player_state_a
    JMP player_air_code
    
; ------------------------------------
custom_handle_stair:
    JSR can_control
    BEQ control_handle_stair
jump_to_stairs:
    JMP stairs

IFDEF DISABLE_CUTSCENE_SUPPORT
    ; prevent cutscene demo at start.
FROM $B9A6
    NOP
    NOP
ENDIF

ENDCOMPARE

IFDEF WEIGHT_HORIZONTAL
    include "weight.asm"
ENDIF

IFDEF opt_code_injection_bank6
    opt_code_injection_bank6
ENDIF

; ------------------------------------
; definitions of some existing addresses
SUPPRESS

BASE $940C
begin_jump:                 db 0

BASE $9586
stairs:                     db 0

BASE $9482
player_air_code: db 0

BASE $9757
player_fall_code: db 0

ENDSUPPRESS