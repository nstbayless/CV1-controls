; horizontal weight
; uses some extra bytes in the subweapon byte to store horizontal velocity.
; replaces accesses to the subweapon with some math to get the actual subweapon out.

WEIGHT_PREVLOC = $

MACRO DEFN_LDA_subweapon
    LDA subweapon
    AND #$0f
    RTS
ENDM

MACRO DEFN_CMP_subweapon
    PHA
    LDA subweapon
    AND #$0f
    STA $00
    PLA
    CMP $00
    RTS
ENDM

MACRO DEFN_STA_subweapon
    PHA
    LDA subweapon
    AND #$f0
    STA subweapon
    PLA
    ORA subweapon
    STA subweapon
    RTS
ENDM

MACRO DEFN_LDX_subweapon
    PHA
    LDA subweapon
    AND #$0f
    TAX
    PLA

    ; refresh status
    INX
    DEX
    RTS
ENDM

; ------------------------------------------------------------------------------
; (implicit)
; BANK 6
; BASE $8000

WEIGHT_CODE_OFFSET=$

COMPARE

LDA_subweapon:
    DEFN_LDA_subweapon

IFDEF BANK6_WEIGHT_OFFSET
    FROM BANK6_WEIGHT_OFFSET
ENDIF

CMP_subweapon:
    DEFN_CMP_subweapon

LDX_subweapon:
    DEFN_LDX_subweapon
    
STA_subweapon:
    DEFN_STA_subweapon

ENDCOMPARE

; runs when using subweapon
FROM $9A8A
    JSR LDA_subweapon
    
; runs when using subweapon
FROM $9AEF
    JSR LDA_subweapon
    
; runs every frame
FROM $A115
    JSR LDA_subweapon
    
; runs every frame
FROM $A12E
    JSR LDA_subweapon
    
; runs at demo start?
; FROM $B888
;    JSR STX_subweapon
    
; runs at demo start?
; FROM $B896
;    JSR STA_subweapon
    
; runs during intro cutscene every frame
; FROM $B913
;    JSR STA_subweapon

; runs on death (sets subweapon to zero)
; FROM $C2C8
;    JSR STA_subweapon
    
; ------------------------------------------------------------------------------
BANK 7
BASE $C000

IFDEF PRG1

    ; runs when attacking?
    FROM $E12C
        JSR CMP_subweapon

    ; runs when obtaining a subweapon
    FROM $E7BD
        JSR STA_subweapon
        
    ; runs when picking up II
    FROM $E801
        JSR LDA_subweapon

    ; runs when an item spawns
    FROM $EB9D
        JSR CMP_subweapon
        
    ; runs when using subweapon
    FROM $FA2A
        JSR LDX_subweapon

ELSE

    ; runs when attacking?
    FROM $E0FC
        JSR CMP_subweapon

    ; runs when obtaining a subweapon
    FROM $E799
        JSR STA_subweapon
        
    ; runs when picking up II
    FROM $E7DD
        JSR LDA_subweapon

    ; runs when an item spawns
    FROM $EB79
        JSR CMP_subweapon
        
    ; runs when using subweapon
    FROM $FA06
        JSR LDX_subweapon

ENDIF

; ------------------------------------------------------------------------------
; duplicate code to bank 5
; this allows code in the fixed bank to work properly regardless of
; whether bank 5 or bank 6 is loaded as the changeable bank.

BANK 5
BASE $8000
FROM WEIGHT_CODE_OFFSET

COMPARE

_LDA_subweapon:
    DEFN_LDA_subweapon

IFDEF BANK6_WEIGHT_OFFSET
    FROM BANK6_WEIGHT_OFFSET
ENDIF

_CMP_subweapon:
    DEFN_CMP_subweapon

_LDX_subweapon:
    DEFN_LDX_subweapon
    
_STA_subweapon:
    DEFN_STA_subweapon

ENDCOMPARE

; ------------------------------------------------------------------------------
; return to bank 6
BANK 6
BASE $8000
FROM WEIGHT_PREVLOC