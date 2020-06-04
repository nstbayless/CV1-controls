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