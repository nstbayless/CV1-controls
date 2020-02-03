incnes "base.nes"

; macros
SEEK EQU SEEKABS
SKIP EQU SKIPREL

MACRO SUPPRESS
    ENUM $
ENDM
ENDSUP EQU ENDE

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

BASE $49
simon_hspeed_1: db 0

BASE $51
;$FF iff simon-hspeed is $FF.
simon_hspeed_ff: db 0

; FF: right
; 00: stopped
; 01: left
BASE $52
simon_hspeed_2: db 0

; @ facing. 1 if left, 0 if right.
BASE $0450
player_facing: db 0

; start of jump: 90
; crest: A4->A2
; end: 8F
BASE $04DC
player_vspeed_magnitude: db 0

; 0: up
; 1: down
BASE $514
player_vspeed_direction: db 0

BASE $488
; an increasing counter related to simon's animation. Value at crest: 16
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
; be negative when simon begins jumping or the
; game will freak out.
BASE $54C
player_stun_timer: db 0

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


ENDE

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
; inside simon's cliff-falling routine.
FROM $93ca

    LDA $11
    STA $0488
    NOP
    LDA #$01
    STA $046C
    NOP
    JMP $BAE4

; --------------------------------------
; Originally this code calculated which direction
; Simon should move in while being knocked back.
; Now it jumps to a subroutine below.
FROM $970b

    JSR $BA9F
    NOP
    NOP
    NOP
    NOP
    NOP

; --------------------------------------
; location of some unused space.
FROM $BA3C

custom_handle_jump:
    JSR $BACC
    BNE $BA8D
    LDY $0450
    LDA $F7
    AND #$03
    BNE $BA51
    LDA #$80
    STA $0584
    BNE $BA73
    LDX #$00
    LSR A
    BCC $BA60
    STX $0450
    LDX #$81
    STX $0584
    BCS $BA69
    INX
    STX $0450
    LDX #$82
    STX $0584
    LDA $0434
    CMP #$00
    BEQ $BA73
    STY $0450
    LDA $F7
    AND #$80
    BNE $BA8D
    LDA $0514
    BNE $BA8D
    LDA $04DC
    CMP #$95
    BMI $BA8D
    JSR $BA90
    LDA #$17
    STA $0488
    JMP $9482
    LDA #$01
    STA $0514
    LDA #$A2
    STA $04DC
    RTS ;-----------------------------
    
    ; add some junk data for no reason
    ; TODO: remove this.
    DB $ff
    DB $ff
    DB $ff
    DB $ff
    
    ; Additional functions
    LDA $45
    BEQ $BAC1
    JSR $BACC
    BNE $BAC1
    LDA $04DC
    CMP #$B3
    BPL $BAC1
    LDA $0514
    BEQ $BAC1
    LDA $F7
    AND #$03
    BEQ $BAC0
    CMP #$03
    BNE $BAC0
    LDA $00
    RTS ;------------------------------
    LDA $0450
    CLC
    ADC #$01
    EOR #$03
    RTS ;------------------------------
    
    ; add some junk data for no reason
    ; TODO: remove this.
    DB $ff
    DB $ff
    
    ; code continues
    LDA $45
    BEQ $BAD2
    LDA $18
    CMP #$05
    RTS ;------------------------------
    STA $49
    LDX $0450
    INX
    STX $0584
    LDA #$07
    STA $046C
    RTS ;------------------------------
    JSR $BACC
    BNE $BAD5
    LDA #$00
    STA $054C
    BNE $BADC
    LDA $04F8
    BEQ $BADC
    BNE $BA97
    ; no fallthrough
    
custom_handle_stair:
    JSR $BACC
    BEQ $BAFF
    JMP $9586
    LDA $F5
    AND #$80
    BEQ $BAFC
    LDA $0434
    BNE $BAFC
    JSR $940C
    LDA #$01
    STA $046C
    JMP $9482

SEEK 10