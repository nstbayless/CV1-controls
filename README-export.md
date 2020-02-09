# Castlevania Improved Controls

This hack for Castlevania modernizes the control scheme to make it more
like Symphony of the Night and Mega Man, allowing the player more
control while in the air.

Compatability with [Ultimate Castlevania](https://www.romhacking.net/hacks/3736/) and with [The Holy Relics](https://www.romhacking.net/hacks/3759/) is confirmed.

## Complete changelog

- Enables the player to control their x-velocity in mid-air while jumping (including while jump-attacking).
- When releasing the jump button, one immediately starts falling again; this allows the player to make smaller hops if desired.
- After being knocked back, the player regains control after a split second and can angle their fall.
- When walking off an edge, the player retains control instead of dropping straight down.
- The player can jump off of stairs at any point in the climb (however, it is still impossible to land on stairs, so be careful jumping from long flights of stairs over pits)

## Credits

ASM hacking: NaOH.

Tools: `fceux` and `asm6f`.

Special thanks to revility and OmegaJP for input.

## ROM information

### Standard

For `cv1-controls.ips`, which is PRG0- and PRG1-compatible:

PRG0:
```
File SHA-1: A31B8BD5B370A9103343C866F3C2B2998E889341
ROM SHA-1: EE09B857C90916EDD92A20C463485A610B0A76FD
```

PRG1:
```
File SHA-1: D1A247025B6256D4BF2187B137CF554AFFFFD616
ROM SHA-1: 1ABB2838CFA0F74510CC818F462B1AD1908D162E
```

### Ultimate CV

For `cv1-uc-controls.ips`, which is compatible with Ultimate CV:

```
File SHA-1: 8CDAE6284056949DF993F8AD35C9105CCB7305B6
ROM SHA-1: A3982C0881E55920928E8B8AA42577E60E54F5B0
```

### Ultimate THR

For `cv1-thr-controls.ips`, which is compatible with The Holy Relics:

```
File SHA-1: F7F2AC72C5A5343D81F0959AADC6271EDB824269
ROM SHA-1: 6387E2C908E63BBA086C9AFE8B5F4E6D9EDE1ED2
```