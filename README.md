# Castlevania Improved Controls

This hack for Castlevania modernizes the control scheme to make it more
like Symphony of the Night and Mega Man, allowing the player more
control while in the air.

Compatability with the following romhacks is confirmed:
 - [Ultimate Castlevania](https://www.romhacking.net/hacks/3736/)
 - [The Holy Relics](https://www.romhacking.net/hacks/3759/). (Note: Knockback onto stairs is unavailable with this version (normally this behaviour is included with `catch` and `latch`). Some lag may be encountered when using `catch` or `latch` stair behaviour -- see below.)
 - [Castlevania Retold](https://www.romhacking.net/hacks/13/)
 - [Castlevania: Blood Moon](https://www.romhacking.net/hacks/79/)
 - [Orchestra of Despair](https://www.romhacking.net/hacks/181/)
 - [Chorus of Mysteries](https://www.romhacking.net/hacks/181/)

Source code available at https://github.com/nstbayless/CV1-controls; 

## Complete list of changes

Some or all of these options can be disabled by selecting a particular patch. See "How to apply" below for more information.

- Enables the player to control their x-velocity in mid-air while jumping (including while jump-attacking).
- When releasing the jump button, one immediately starts falling again; this allows the player to make smaller hops if desired.
- After being knocked back, the player regains control after a split second and can angle their fall.
- When walking off an edge, the player retains control instead of dropping straight down.
- The player can jump off of stairs at any point in the climb
- The player can land on stairs (either by default or by holding up to latch)

## How to apply

Use an ips patcher, such as flips or Lunar IPS. A variety of .ips files are provided depending on what you want.
If you're not use what you want, you likely want `prg0/cv1-controls-prg0-catch-vcancel.ips` or `prg1/cv1-controls-prg1-catch-vcancel.ips`.

These are the options provided:

### Base ROM

You can determine whether your ROM is prg0 or prg1 by comparing the hash with the hashes listed at the bottom of this readme.

- `prg0`: compatible with prg0 ROMs.
- `prg1`: compatible with prg1 ROMs, including prg1 [!] (goodnes).

Compatability with other hacks (see the "hack-compatible/" directory):
- `hack-prg0`: compatible with several PRG0 hacks including *Orchestra of Despair*.
- `hack-prg1`: compatible with several PRG1 hacks including *Castlevania Blood Moon* and *Castlevania Retold* (PRG1).
- `uc`: compatible with *Ultimate Castlevania*.
- `thr`: compatible (only) with *The Holy Relics*.

### Stair Behaviour

- `fallthrough`: this is the default behaviour. The player cannot land on stairs.
- `catch`: this is the recommended behaviour. The player will land on stairs by default, and fall through by holding down.
- `latch`: this is close to the CV4 behaviour. The player will land on stairs only when holding up.

### Air control

- `vcancel` allows the player to control the height of their jumps by releasing the jump button early.
- `stairs_only` means that no air control is permitted at all; the only change made by the hack is stair landing/catching.

## Credits

ASM hacking: NaOH.

Tools: `fceux` and `asm6f`.

Special thanks to revility and OmegaJP for input.

## ROM information

These hashes are for the base roms that cv1-controls can be applied to.

PRG0 (U):
```
File SHA-1: A31B8BD5B370A9103343C866F3C2B2998E889341
ROM SHA-1: EE09B857C90916EDD92A20C463485A610B0A76FD
```

PRG1 (U):
```
File SHA-1: D1A247025B6256D4BF2187B137CF554AFFFFD616
ROM SHA-1: 1ABB2838CFA0F74510CC818F462B1AD1908D162E
```

PRG1 (U) [!]:
```
File SHA-1: 7A20C44F302FB2F1B7ADFFA6B619E3E1CAE7B546
ROM SHA-1: 3DCB69A8C861C041AEB56C04E39ADF6D332EDA3A
```

Ultimate Castlevania:
```
File SHA-1: 8CDAE6284056949DF993F8AD35C9105CCB7305B6
ROM SHA-1: A3982C0881E55920928E8B8AA42577E60E54F5B0
```

The Holy Relics
```
File SHA-1: F7F2AC72C5A5343D81F0959AADC6271EDB824269
ROM SHA-1: 6387E2C908E63BBA086C9AFE8B5F4E6D9EDE1ED2
```

Castlevania Blood Moon:
```
File SHA-1: AF27FF849208FBAEF36476C6E52BE9C285A64CD5
ROM SHA-1: FF4C3D61E96B677B73F4EC8ADC40BF81C7C16541
```

Castlevania Retold (PRG1):
```
File SHA-1: 1AD4A450D94498B34AE4D2D0F40EA102F1E762B3
ROM SHA-1: C3A1DC516E54BBDFA8A17B70AAE218249F0E0685
```