read_stage_stairs_base_from=$9CC2

; This could go as low as $BCB8 potentially, but higher is better as it's less likely to have a collision with another hack's custom asm.
IFDEF WEIGHT
    BANK6_OFFSET = $BCE0
ELSE
    BANK6_OFFSET = $BD40
ENDIF
