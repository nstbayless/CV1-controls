ifdef PRG0
    INCLUDE "opt/opt-prg0.asm"
else
    ifdef PRG1
        INCLUDE "opt/opt-prg1.asm"
    else
        ifdef UC
            INCLUDE "opt/opt-uc.asm"
        else
            ifdef HACK
                INCLUDE "opt/opt-hack-prg1.asm"
            else
                ifdef HACKPRG0
                    INCLUDE "opt/opt-hack-prg0.asm"
                else
                    ifdef COMV2
                        INCLUDE "opt/opt-comv2.asm"
                    else
                        ERROR "A configuration is required (try -dPRG0 or -dPRG1)"
                    endif
                endif
            endif
        endif
    endif
endif