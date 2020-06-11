## Instructions for Building and Contributing

You require a [special version of asm6f](https://github.com/nstbayless/asm6f) which has support for patching directives. Make sure this version of `asm6f` is on the PATH.

Optionally, put [ipsnect](https://github.com/nstbayless/ipsnect) on the path to generate a patch map.

Finally, place your ROM into this directory and call it `base-prg0.nes` (assuming your ROM is PRG0). You can also
add `base-prg1.nes`, `base-uc.nes`, and `base-thr.nes` (for
    PRG1, Ultimate CV, and The Holy Relics respectively), and various other base files -- see the top of build.sh

Then run `./build.sh`. You will need bash to do this. On windows, if you have git installed, you may be able to run `./build.sh` from your git terminal.
You should see several files generated, including .ips and .nes files.

Please do not commit any .nes files to the repo if they are not in the public domain.