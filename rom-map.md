# ROM/RAM Map

This document maps different ROM and RAM values that are useful for the hack.

## RAM

### Simon State

$0450: Facing. 1 if left, 0 if right.

$046C: state variable A
| 0: standing/walking
| 1: jumping
| 2: attacking & subweapon
| 3: crouching
| 4: stairs
| 5: knockback
| 6: walk to stair
| 7: falling
| 8: dead
| 9: stunned

$434: attack variable
| 00: not attacking
| 01: attacking (ground)
| 02: attacking (crouch)
| 03: attacking (air)

$0584: state variable B
| 0: standing
| 1: walking right
| 2: walking left
| 4: crouching
| 40: attacking
| 80: air, vertical
| 81: air, right
| 82: air, left

$0049: simon's horizontal speed (?)
$0052: simon's horizontal speed (?)
| FF: right
| 00: stopped
| 01: left
$0051: $FF iff simon-hspeed is $FF.

$96A1: hit invulnerability timer

### Simon vspeed state
$04DC: vertical speed (magnitude).
| start of jump: 90
| crest: A4->A2
| end: 8F
$514: vertical direction
| 0: up
| 1: down
$0488: an increasing counter related to simon's animation. Value at crest: 16

$054c: Stun timer. This must not
be negative when simon begins jumping or the
game will freak out.

### Other

$0017: "Game Mode" (see "Game-mode-specific step code" below)
$00F5: buttons pressed this frame
$00F7: held down buttons (includes buttons pressed this frame)
$0042: time remaining in seconds (last two digits).

## ROM

06:944A: simon step event turn around
01937C: Jump Table
default value: 809382941195399586955B9620975797AA97F297A545F00210034CE5A1201D9A
hack: 8294 (in air) -> 3CBA

standard jump code: 9482
custom jump code: BA3C

custom stair code: BAF7

custom code in ROM: 0x01ba4b

### Game-mode-specific step code
step dispatch: 07:c1A1 (ROM 01c1b1)
jump-to-table subroutine: 07:CA1E (ROM 01ca2e)
jump table: 07:C1B1 (ROM 01C1C0) | contents: DCB7 23B8 59B8 D2B8 11B9 EFC1 8FC2 DDC2 33C3 98C4 98C4 9386 A6C5 F8C7 EE86 4B8B FEFA A908 8525

Jumps off of "Game mode" value in $18
$18 values
| 0: first frame of game
| 1: title screen
| 2: title screen demo gameplay
| 5: normal gameplay; pre-demo loading (~17 frames)
| 6: dead; reload level (and post-demo 1, due to death)
| 7: game over