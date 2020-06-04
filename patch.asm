INCLUDE "pre.asm"

INCLUDE "defs.asm"

ifdef PRG0
    INCLUDE "opt-prg0.asm"
else
    ifdef PRG1
        INCLUDE "opt-prg1.asm"
    else
        ifdef UC
            INCLUDE "opt-uc.asm"
        else
            INCLUDE "opt-standard.asm"
        endif
    endif
endif

; ------------------------------------------------------------------------------
BANK 6
BASE $8000

; --------------------------------------
; player jump table
FROM $936e

    dw custom_handle_jump
    
SKIP 4

    dw custom_handle_stair

; --------------------------------------
; inside player's cliff-falling routine.
FROM $93ca

    LDA #$0D
    STA player_v_animation_counter
    NOP
    LDA #$01
    STA player_state_a
    NOP
    JMP custom_handle_cliff_drop

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

; --------------------------------------
; location of some unused space.
FROM BANK6_OFFSET

; check that we only overwrite the value $FF
FILLVALUE $FF
COMPARE

custom_handle_jump:
    JSR can_control
    BNE RETURNA
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
check_v_cancel:
    LDA button_down
    AND #$80
    BNE RETURNA
    LDA player_vspeed_direction
    BNE RETURNA
    LDA player_vspeed_magnitude
    CMP #$95
    BMI RETURNA
    JSR v_cancel
    LDA #$17
    STA player_v_animation_counter
RETURNA:
    JMP player_air_code
    
; ------------------------------------
v_cancel:
    LDA #$01
    STA player_vspeed_direction
    LDA #$A2
store_vspeed_magnitude:
    STA player_vspeed_magnitude
    RTS
    
; ------------------------------------
custom_knockback:
    LDA $45
    BEQ knockback_standard
    JSR can_control
    BNE knockback_standard
    LDA player_vspeed_magnitude
    CMP #$B3
    BPL knockback_standard
    LDA player_vspeed_direction
    BEQ knockback_standard
    LDA button_down
    AND #$03
    BEQ RETURNB
    CMP #$03
    BNE RETURNB
    LDA $00
RETURNB:
    RTS
    
; ------------------------------------
knockback_standard:
    LDA player_facing
    CLC
    ADC #$01
    EOR #$03
    RTS
    
; ------------------------------------
; const function, determines whether or not can currently control.
; (Z if can control, z if cannot)
can_control:
    LDA player_hp
    BEQ +             ; illegible, but this produces correct behaviour
    LDA game_mode
  + CMP #$05
    RTS
    
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
   + BNE store_vspeed_magnitude
    
; ------------------------------------
custom_handle_stair:
    JSR can_control
    BEQ control_handle_stair
jump_to_stairs:
    JMP stairs
    
; ------------------------------------
control_handle_stair:
    LDA button_press
    AND #$80
    BEQ jump_to_stairs
    LDA player_state_atk
    BNE jump_to_stairs
    JSR begin_jump
    LDA #$01
    STA player_state_a
    JMP player_air_code

ENDCOMPARE

; ------------------------------------
; definitions of some existing addresses
SUPPRESS

BASE $940C
begin_jump:                 db 0

BASE $9586
stairs:                     db 0

BASE $9482
player_air_code: db 0

ENDSUPPRESS