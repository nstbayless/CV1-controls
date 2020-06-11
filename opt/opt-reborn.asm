BANK6_OFFSET = $BC78
TERTIARY_BANK6_OFFSET=$B185
QUARTIARY_BANK6_OFFSET=$BB3B

read_stage_stairs_base_from=$9CC2

MACRO opt_code_injection_bank6
    ; fixes an (important) stair.
    FROM $BA36
        db $2A
ENDM