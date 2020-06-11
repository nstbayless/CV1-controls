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

; --------------------------------------
; location of some unused space.
FROM BANK6_OFFSET

; check that we only overwrite the value $FF
FILLVALUE $FF
COMPARE

custom_handle_jump:
    IFNDEF DISABLE_CUTSCENE_SUPPORT
        JSR can_control
        BNE jmp_to_air_standard
    ENDIF
    
; set direction in mid-air
IFNDEF NO_AIRCONTROL
        LDY player_facing
        LDA button_down
        AND #$03
        BNE check_right
        LDA #$80
        STA player_state_b
        BNE check_v_cancel
    check_right:
        LDX #$00
        LSR A
        BCC turn_left
    turn_right:
        STX player_facing
        LDX #$81
        STX player_state_b
        BCS check_reset_facing
    turn_left:
        INX
        STX player_facing
        LDX #$82
        STX player_state_b
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
    LDA player_vspeed_magnitude
    CMP #$95
    BMI check_stair_catch
    JSR v_cancel
    LDA #$17
    STA player_v_animation_counter
ENDIF
    
check_stair_catch:
    IFDEF CHECK_STAIRS_ENABLED
        JSR stair_checking_subroutine
    ENDIF
jmp_to_air_standard:    
    ; return to original code
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
    IFNDEF DISABLE_CUTSCENE_SUPPORT
        JSR can_control
        BNE knockback_standard
    ELSE
        LDA player_hp
        BEQ knockback_standard
    ENDIF
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
    
IFNDEF DISABLE_CUTSCENE_SUPPORT
    ; ------------------------------------
    ; pure function, determines whether or not can currently control.
    ; (Z if can control, z if cannot)
    can_control:
        LDA player_hp
        BEQ +             ; illegible, but this produces correct behaviour
        LDA game_mode
      + CMP #$05
        RTS
ENDIF
    
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
        IFNDEF DISABLE_CUTSCENE_SUPPORT
            JSR can_control
            BNE cutscene_fall
        ENDIF
        
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

IFDEF DISABLE_CUTSCENE_SUPPORT
custom_handle_stair:
    JMP control_handle_stair
ENDIF

; ------------------------------------
IFNDEF NO_VCANCEL
v_cancel:
    LDA #$01
    STA player_vspeed_direction
    LDA #$A2
ENDIF

store_vspeed_magnitude:
    STA player_vspeed_magnitude
    RTS
    
IFDEF QUARTIARY_BANK6_OFFSET
    FROM QUARTIARY_BANK6_OFFSET
ENDIF
    
IFDEF DISABLE_CUTSCENE_SUPPORT
jump_to_stairs:
    JMP stairs
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
IFNDEF DISABLE_CUTSCENE_SUPPORT
    custom_handle_stair:
        JSR can_control
        BEQ control_handle_stair
    jump_to_stairs:
        JMP stairs
ENDIF

IFDEF DISABLE_CUTSCENE_SUPPORT
    ; prevent cutscene demo at start.
FROM $B9A6
    NOP
    NOP
ENDIF

ENDCOMPARE

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