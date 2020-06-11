BANK6_OFFSET = $BA3D

read_stage_stairs_base_from=$9CC2

IFDEF CHECK_STAIRS_ENABLED
    ; fixes the "crumbling tower" stage 7 nonexistent staircase.
    ; (normally it would be unreachable in the game.)
    FLOATING_STAIRCASE_STAGE_SEVEN_FIX=1
ENDIF