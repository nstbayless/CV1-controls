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
    
    ; zero store.
    LDA #$0
    STA varBL
    STA varBR
    STA varTL
    STA varTR

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
        BNE check_substage
        JMP check_loop_end
    
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
        LDA varYY
        ; varZ now stores dy-dx (low byte)
        
    stair_loop_check_dydx:
        ; check that 0 <= dy-dx < 0x100
        ; (check high byte)
        SBC varX
        BNE stair_loop_begin
        
        ; check that 0 <= dy-dx < epsilon
        LDA varOD
        epsilon=#$8
        CMP epsilon ; epsilon; come back to this later.
        BCS stair_loop_begin ;  y-x > epsilon
        
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
        BCC jmp_stair_loop_begin
        
        store_xpos_set:
        ; store x position in varBL,X
        ; or'd with #$3 to mark (a) set, and (b) yes landing. 
        LDA varZ
        ORA #$3
        ; (X is varW, set in diag_compare_x)
        STA varBL,X
        
        jmp_stair_loop_begin:
        JMP stair_loop_begin
        
        stair_negx:
        ; get absolute value of dx, then compress it
        JSR diag_flip_prf_x
        JSR diag_compress_x
        JSR diag_compare_x
        BCC jmp_stair_loop_begin
        
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
        BNE jmp_stair_loop_begin
    
check_loop_end:
    ; ~~ check if any varBL,X set and marked as catching ~~
    LDX #$0
    check_loop_start:
        LDA varBL,X
        TAY
        AND #$1 ; was this one set?
        BEQ check_loop_next
        TYA
        AND #$2 ; was this one marked catching?
        BEQ check_loop_next
        
    stair_check_butterzone:
        ; found a successful match -- This is the butterzone.
        ; (a true stair collision)
        
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
        AND #$f
        ; A now holds (player_x-player_y) % 16
        BEQ skip_mody
        SEC
        SBC #$10
        
        ; subtract from player_y
        CLC
        ADC player_y
        STA player_y
        skip_mody:
        
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
        
        ; set on stair
        LDA #$1
        STA player_on_stairs
        LDA #$4
        STA player_state_a
        
        ; zero hspeed
        LDA #$A2
        STA player_vspeed_magnitude
        
        ; guaranteed jump
        BNE RETURNA
        
    check_loop_next:
        INX
        CPX #$4
        BNE check_loop_start
endif
        
RETURNA:
    ; return to original code
    JMP player_air_code

if CHECK_STAIRS_ENABLED
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
endif
    
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