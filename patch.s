; cl65 complains if these aren't defined.
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

; use base's .nes header
.incbin "base.nes", $0, $10

; include original nes ROM.
.org $10
.incbin "base.nes", $10, $8000