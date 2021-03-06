; ------------------------------------------------------------------------------
; memory address values
ENUM $0

BASE $1A
timer: db 0

BASE $28
current_stage: db 0

; either 0 or 1
BASE $46
current_substage: db 0

BASE $15B
subweapon: db 0

; little-endian x value in section.
BASE $2E
camera_x: dw 0

BASE $3F
player_y: db 0

; little-endian x value in section.
BASE $40
player_x: dw 0

; the player's x offset from the camera
BASE $38C
player_x_camera_offset: db 0

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

; where vspeed is read from.
; seems to read from $9b90, which
; ranges from FB (-5) to 0.
BASE $04F8
vspeed_map: db 0

; start of jump: 90
; crest: A4->A2
; end: 8F (see above)
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

BASE $4c0
player_stair_direction: db 0

; 0 if not moving, 1 if left, 2 if right
BASE $3C
player_stair_direction_2: db 0

BASE $3E
player_on_stairs: db 0

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
; 40: attacking (but never when in the air)
; 80: air, vertical
; 81: air, right
; 82: air, left
BASE $584
player_state_b: db 0

; Stun timer. This must not
; be negative when player begins jumping or the
; game will freak out.
; (it seems it must be 0 anytime not in knockback, actually.)
BASE $54C
player_stun_timer: db 0

; amount of invincibility time remaining.
BASE $5B
player_iframes: db 0

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

; ---- input ----
; 80: jump
; 40: whip
; 20: Select
; 10: Start
; 08: Up
; 04: Down
; 02: Left
; 01: Right
; buttons (just now) pressed this frame
BASE $F5
button_press: db 0

;held down buttons (includes buttons pressed this frame)
BASE $F7
button_down: db 0

; time remaining in seconds (last two digits)
BASE $42
time_remaining_b: db 0

; time remaining in seconds (first two digits)
BASE $43
time_remaining_a: db 0

; array of word pointers to stage stair data offset
; stair data: 0-terminated list.
; stair (2 bytes; 1 byte if 0):
; low byte:
;   - if 0, EOL
;   - bytes 0-1: direction
;   - byte 2: substage
;   - byte 3: ?
;   - bytes 4-7: y position + 16
; high byte:
;   - bytes 3-7: x position
;   - bytes 0-2: screen x

; stage_stairs_base

; general-use variables
; the names are completely meaningless; historically they had meaning
; but the addresses have moved. Only varBL...varTL make sense in the context
; of stair logic. (bottom-left, etc.)

BASE $0
varBL: db 0
varBR: db 0
varTR: db 0
varTL: db 0

; these two must be sequential
varE=$E
varF=$F

varW=$10
varZ=$11
varX=$12
varY=$13
varYY=$14
varOD=$15
varOE=$16
varOF=$17

ENDE