; cc65 complains if these are not defined.

; header
.segment "HEADER"

.incbin "base.nes", $0, $10

.segment "ROM0"
.segment "STARTUP"
.segment "VECTORS"
.segment "CODE"

.org $0
.byte $3c, $ba