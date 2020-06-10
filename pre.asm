ifdef USEBASE
    INCLUDE "opt-base.asm"
else
    INCNES "base.nes"
endif

CLEARPATCH

; macros
SEEK EQU SEEKABS
SKIP EQU SKIPREL

MACRO SUPPRESS
    ENUM $
ENDM
ENDSUPPRESS EQU ENDE

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

; stair behaviour can be:
; - latch (hold up to land on a stair)
; - catch (don't hold down + only catch while falling)
; - none
IFDEF LATCH_STAIRS
    CHECK_STAIRS_ENABLED=1
ENDIF

IFDEF CATCH_STAIRS
    CHECK_STAIRS_ENABLED=1
ENDIF

IFDEF CHECK_STAIRS_ENABLED
    STAIR_EXIT_STAGE_TOP=#$28
    STAIR_ENTER_STAGE_BOTTOM=#$C7
ELSE
    ; default values
    STAIR_EXIT_STAGE_TOP=#$30
    STAIR_ENTER_STAGE_BOTTOM=#$CF
ENDIF

IFDEF NO_AIRCONTROL
    NO_VCANCEL=1
ENDIF