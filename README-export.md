# Castlevania Improved Controls

This hack for Castlevania modernizes the control scheme to make it more
like Symphony of the Night and Mega Man, allowing the player more
control while in the air.

Compatability with [Ultimate Castlevania](https://www.romhacking.net/hacks/3736/) and with [The Holy Relics](https://www.romhacking.net/hacks/3759/) is confirmed.

## Complete list of changes

Options marked with an asterisk (\*) are optional. See "How to apply" below for more information.

- Enables the player to control their x-velocity in mid-air while jumping (including while jump-attacking).
- (\*) When releasing the jump button, one immediately starts falling again; this allows the player to make smaller hops if desired.
- After being knocked back, the player regains control after a split second and can angle their fall.
- When walking off an edge, the player retains control instead of dropping straight down.
- The player can jump off of stairs at any point in the climb
- (\*) The player can land on stairs (either by default or by holding up to latch)

## How to apply

Use an ips patcher, such as flips or Lunar IPS. A variety of .ips files are provided depending on what you want.
If you're not use what you want, use `prg0/cv1-controls-prg0-catch-vcancel.ips`. These are the options provided:

### Base ROM

- prg0: compatible with prg0 ROMs. (This is the most common ROM.)
- prg1: compatible with prg1 ROMs.
- uc: compatible with Ultimate CV.
- thr: compatible with The Holy Relics.

### Stair Behaviour

- fallthrough: this is the default behaviour. The player cannot land on stairs.
- catch: this is the recommended behaviour. The player will land on stairs by default, and fall through by holding down.
- latch: this is close to the CV4 behaviour. The player will land on stairs only when holding up.

### V-cancelling

`vcancel` allows the player to control the height of their jumps by releasing the jump button early.

## Credits

ASM hacking: NaOH.

Tools: `fceux` and `asm6f`.

Special thanks to revility and OmegaJP for input.

## ROM information

### Standard

