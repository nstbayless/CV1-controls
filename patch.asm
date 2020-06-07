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

FROM $934e:

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

jmp_to_returna:
    JMP RETURNA
custom_handle_jump:
    JSR can_control
    BNE jmp_to_returna
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
    BNE check_stair_catch
    LDA player_vspeed_direction
    BNE check_stair_catch ; OPTIMIZE: could actually jump a few instructions later.
    LDA player_vspeed_magnitude
    CMP #$95
    BMI check_stair_catch
    JSR v_cancel
    LDA #$17
    STA player_v_animation_counter
    
check_stair_catch:

    LDA player_vspeed_direction
    BEQ jmp_to_returna

if CHECK_STAIRS_ENABLED
    ; 
    LDA current_stage
    ASL
    TAX
    LDA stage_stairs_base,X
    STA varE
    LDA stage_stairs_base+1,X
    STA varE+1
    LDY #$FE
    stair_loop_begin:
        INY
        INY
        ; load stair data low-byte
        LDA (varE),Y
        BEQ RETURNA
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
        
        ; store y value of stair 
        TXA
        AND #$f0
        STA varY
        
        ; calculate y difference (player_y - y)
        SEC
        LDA player_y
        SBC varY
        STA varY
        LDA #$0
        SBC #$0
        STA varYY
        
        ; store x value of stair
        INY
        LDA (varE),Y
        DEY
        TAX
        
        ; calculate x (low byte)
        AND #$f8
        STA varZ
        ; add 8 if ends in 8. (not sure why this is done this way...)
        AND #$8
        CLC
        ADC varZ
        STA varZ
        
        ; x (high byte)
        TXA
        ADC #$0
        AND #$7
        STA varX
        
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
        
        ; dy-dx
        SEC
        LDA varY
        SBC varZ
        STA varZ
        LDA varYY
        ; varZ now stores dy-dx (low byte)
        
        ; check that 0 <= dy-dx < 0x100
        ; (check high byte)
        SBC varX
        BNE stair_loop_begin
        
        ; check that 0 <= dy-dx < epsilon
        LDA varZ
        CMP #$8 ; epsilon; come back to this later.
        BCS stair_loop_begin ;  y-x > epsilon
        
        ; ~~ the butter zone ~~
        ; (a stair collision)
        
        ; add the difference to player_y to land on the stair exactly
        SEC
        LDA player_y
        SBC varZ
        STA player_y
        
        ; set on stair
        LDA #$1
        STA player_on_stairs
        LDA #$4
        STA player_state_a
        
        ; skip regular jump update.
        PLA
        PLA

endif
        
RETURNA:
    ; return to original code
    JMP player_air_code
    
; sets varY to -varY if varW is 0 or 3.
diag_flip:
    LDA varW
    BEQ diag_flip_rts
    CMP #$2
    BEQ diag_flip_rts
; perfom flip
diag_flip_prf:
    SEC
    LDA #$0
    SBC varZ
    STA varZ
    LDA #$0
    SBC varX
    STA varX
diag_flip_rts:
    RTS
    
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