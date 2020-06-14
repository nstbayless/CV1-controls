read_stage_stairs_base_from=$9CC2

; BANK6_OFFSET could go as low as $BCB8 potentially, but
; higher is better as it's less likely to have a
; collision with another hack's custom asm.

; Here we roughly try to get bank6 offset as close to
; the end of the bank as possible.
BANK6_OFFSET = $BCB8

IFDEF FALLTHROUGH_STAIRS
    BANK6_OFFSET = BANK6_OFFSET + $120
ENDIF

IFNDEF WEIGHT
    BANK6_OFFSET = BANK6_OFFSET + $70
ENDIF

IFDEF NO_VCANCEL
    BANK6_OFFSET = BANK6_OFFSET + $20
ENDIF

IFDEF WEIGHT
    IFNDEF FALLTHROUGH_STAIRS
            BANK6_WEIGHT_OFFSET=$BBA0
    ENDIF
ENDIF