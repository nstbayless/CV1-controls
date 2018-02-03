## Instructions for Setting Up and Contributing

Run the `setup.sh` script before starting in order to enable githooks
and to automatically apply the patch.

First you must supply your own ROM for Castlevania (USA).
Paste the ROM into the repo and name it `base.nes`. Then run `setup.sh`.
This will generate a `working.nes` file which you can run and edit,
which should be up-to-date with the repository patch.

Before contributing, a githook will require you to make sure that
`patch.ips` is up-to-date with `working.nes`. If you would like to
commit, either run `make-patch.sh` to bring `patch.ips` up-to-date with
`working.nes` (recommended), or commit again with the `--no-verify`
option to prevent git from running the githook (not recommended).

Finally, if possible, please make sure your contributions are compatible
with this English localization hack as well:
http://www.romhacking.net/hacks/1983/
You can do this by applying the localization patch directly to `base.nes`.

Do not commit any .nes files to the repo which are not in the public domain!

### ROM details

No-Intro Name: Castlevania (USA)
(No-Intro version  20130731-235630)
File SHA-1: A31B8BD5B370A9103343C866F3C2B2998E889341
ROM SHA-1: EE09B857C90916EDD92A20C463485A610B0A76FD
