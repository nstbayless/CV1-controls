# ROM/RAM Map

This document maps different ROM and RAM values that are useful for the hack.

## RAM

### Simon State

$0450: Facing. 1 if left, 0 if right.

$046C: state variable A
| 0: standing/walking
| 1: jumping
| 2: attacking
| 3: crouching

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

$0052: simon's horizontal speed
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

### Other

$00F7: held down buttons
$0042: time remaining in seconds (last two digits).

## ROM

06:944A: simon step event turn around
01937C: Jump Table
default value: 809382941195399586955B9620975797AA97F297A545F00210034CE5A1201D9A
hack: 8294 (in air) -> 3BBA

standard jump code: 9482
custom jump code: BA3B

standard knockback code: 965B
custom knockback code: BAAA