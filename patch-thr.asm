; The Holy Relics-compatible hack.
INCNES "base.nes"

CLEARPATCH

; macros
SEEK EQU SEEKABS
SKIP EQU SKIPREL

MACRO SUPPRESS
    ENUM $
ENDM
ENDSUPPRESS EQU ENDE

MACRO SKIPTO pos
    if ($ >= 0)
        SKIP pos - $
        
        ; just to be safe.
        if ($ != pos)
            ERROR "failed to skipto."
        endif
    endif
ENDM
FROM EQU SKIPTO

MACRO BANK bank
    SEEK (bank * $4000) + $10
ENDM

; ------------------------------------------------------------------------------
; memory address values
ENUM $0

; FF: right
; 00: stopped
; 01: left
BASE $49
player_hspeed_1: db 0

; FF: right
; 00: stopped
; 01: left
BASE $52
player_hspeed_2: db 0

BASE $51
;$FF iff player-hspeed is $FF.
player_hspeed_ff: db 0

; @ facing. 1 if left, 0 if right.
BASE $450
player_facing: db 0

; start of jump: 90
; crest: A4->A2
; end: 8F
BASE $4DC
player_vspeed_magnitude: db 0

; 0: up
; 1: down
BASE $514
player_vspeed_direction: db 0

BASE $488
; an increasing counter related to player's animation. Value at crest: 16
player_v_animation_counter: db 0

; @ player state
; 0: standing/walking
; 1: jumping
; 2: attacking & subweapon
; 3: crouching
; 4: stairs
; 5: knockback
; 6: walk to stair
; 7: falling
; 8: dead
; 9: stunned
BASE $46C
player_state_a: db 0

; attack state
; 00: not attacking
; 01: attacking (ground)
; 02: attacking (crouch)
; 03: attacking (air)
BASE $434
player_state_atk: db 0

; state variable B
; 0: standing
; 1: walking right
; 2: walking left
; 4: crouching
; 40: attacking
; 80: air, vertical
; 81: air, right
; 82: air, left
BASE $584
player_state_b: db 0

; Stun timer. This must not
; be negative when player begins jumping or the
; game will freak out.
BASE $54C
player_stun_timer: db 0

; player hitpoints
BASE $45
player_hp: db 0

; "Game Mode"
; 0: first frame of game
; 1: title screen
; 2: title screen demo gameplay
; 5: normal gameplay; pre-demo loading (~17 frames)
; 6: dead; reload level (and post-demo 1, due to death)
; 7: game over
BASE $18
game_mode: db 0

; buttons pressed this frame
BASE $F5
button_press: db 0

;held down buttons (includes buttons pressed this frame)
BASE $F7
button_down: db 0

; time remaining in seconds (last two digits)
BASE $42
time_remaining_b: db 0

BASE $04F8
vspeed_map: db 0

ENDE

; ------------------------------------------------------------------------------
BANK 6
BASE $8000

; player jump table; replace stair jump routine.
FROM $9374

    dw custom_stair_launchpad

; start of player's jump routine
FROM $9482

    LDA #>custom_handle_jump
    LDX #<custom_handle_jump-1
bank4_pre_switch_jmp:
    PHA
    TXA
    PHA
    LDY #$4
    JMP bank_switch_jmp

custom_jump_return:
    SUPPRESS
        db 0
    ENDSUPPRESS
    
if $ != $948E
    ERROR "incorrect length for aerial patch."
endif

; --------------------------------------
; inside player's falling routine.
FROM $93ca

fall_routine_in:
    LDA #>custom_handle_cliff_drop
    LDX #<custom_handle_cliff_drop-1
    JMP bank4_pre_switch_jmp
custom_stair_launchpad:
    LDA #>custom_handle_stair
    LDX #<custom_handle_stair-1
    JMP bank4_pre_switch_jmp
custom_fall_return:
    SUPPRESS
        db 0
    ENDSUPPRESS

if $ != $93d8
    ERROR "incorrect length for falling patch."
endif

; --------------------------------------
; Originally this code calculated which direction
; player should move in while being knocked back.
; Now it jumps to a subroutine below.
FROM $970b

knockback_direction:
    LDA #>custom_knockback
    LDX #<custom_knockback-1
    JMP bank4_pre_switch_jmp
    NOP
    NOP
    NOP

custom_knockback_return:
    SUPPRESS
        db 0
    ENDSUPPRESS
    
if $ != $9715
    ERROR "incorrect length for knockback patch."
endif

; stairs routine start
FROM $9586

stairs:
SUPPRESS
    db 0
ENDSUPPRESS

; ------------------------------------------------------------------------------
BANK 4
BASE $8000

; location of some unused space.
FROM $B410

; code complies with original
air_standard:
    LDA $3F
    SEC
    SBC #$E0
    CMP #$10
    BCS +
    LDY #>alt_air_code
    LDX #<alt_air_code
    JMP bank6_switch_jmp
  + LDY #>custom_jump_return
    LDX #<custom_jump_return
    JMP bank6_switch_jmp
; -----------------------------------

custom_handle_jump:
    JSR can_control
    BNE air_standard
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
    BNE air_standard
    LDA player_vspeed_direction
    BNE air_standard
    LDA player_vspeed_magnitude
    CMP #$95
    BMI air_standard
    JSR v_cancel
    LDA #$17
    STA player_v_animation_counter
    BNE air_standard
    
; ------------------------------------
v_cancel:
    LDA #$01
    STA player_vspeed_direction
    LDA #$A2
store_vspeed_magnitude:
    STA player_vspeed_magnitude
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
custom_knockback:
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
    LDY #>custom_knockback_return
    LDX #<custom_knockback_return
    JMP bank6_switch_jmp
    
; ------------------------------------
knockback_standard:
    LDA player_facing
    CLC
    ADC #$01
    EOR #$03
    STA $00
    JMP RETURNB
    
; ------------------------------------
stair_standard:
    LDY #>stairs
    LDX #<stairs
    JMP bank6_switch_jmp

; ------------------------------------
custom_handle_stair:
    JSR can_control
    BEQ control_handle_stair
    BNE stair_standard
        
; ------------------------------------
control_handle_stair:
    LDA button_press
    AND #$80
    BEQ stair_standard
    LDA player_state_atk
    BNE stair_standard
    LDY #>begin_jump
    LDX #<begin_jump
    JSR bank6_switch_call
    LDA #$01
    STA player_state_a
    LDY #>begin_jump
    LDX #<begin_jump
    JMP air_standard

; ------------------------------------
cutscene_fall:
    LDA #$0
    STA player_hspeed_1
    LDX player_facing
    INX
    STX player_state_b
set_falling:
    LDA #$07
    STA player_state_a
    RTS

; ------------------------------------
custom_handle_cliff_drop:
    LDA #$10
    STA player_v_animation_counter
    LDA #$01
    STA player_state_a
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
  + JSR store_vspeed_magnitude
    LDY #>custom_fall_return
    LDX #<custom_fall_return
    JMP bank6_switch_jmp
    
; LDY #>address
; LDX #<address
; JMP here
bank6_switch_jmp:
    STA $00
    ; decrement return address (YX)
    INX
    DEX
    BNE +
    DEY
  + DEX
    ; put return addres (YX) on stack.
    TYA
    PHA
    TXA
    PHA
    LDY #$6
    LDA $00
    JMP bank_switch_call
    
; LDY #>address
; LDX #<address
; JSR here
bank6_switch_call:
    STA $00
    LDA #>bank_switch_return
    PHA
    LDA #<bank_switch_return-1
    PHA
    ; decrement return address (YX)
    INX
    DEX
    BNE +
    DEY
  + DEX
    ; put return addres (YX) on stack.
    TYA
    PHA
    TXA
    PHA
    LDY #$4
    STY $27
    LDY #$6
    LDA $00
    JMP bank_switch_call    

if $ > $BB20
    ERROR "exceeded space for bank-4 patch."
endif

; ------------------------------------
; definitions of some existing addresses
SUPPRESS

BASE $940C
begin_jump:                 db 0

BASE $A1E5
alt_air_code:               db 0

BASE $9449
bank6_rts:                  db 0

; usage (JMP): put destination bank in Y,
; dst address on the stack, and
; jmp here.
BASE $C1D8
bank_switch_jmp:           db 0

; usage (RTS):
; store current bank in $27,
; return address on the stack,
; then `bank_switch_return` on the stack,
; then destination address on stack
; LDY destination bank
; then JMP to bank_switch_call
BASE $C1D8
bank_switch_call:

BASE $C1CF
bank_switch_return:



ENDSUPPRESS