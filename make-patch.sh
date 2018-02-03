#!/bin/bash
# creates a patch based on the difference between base.nes and working.nes

# find flips patcher:
flips="./flips/flips.exe"
outdir="patch.ips"
if [ $# -eq 1 ]
then
  outdir="$1"
fi

if [ "$op" = "Linux" ]
then
  flips="./flips/flips-linux"
fi

if [ ! -f $flips ]
then
    >&2 echo "flips not found; do you have the flips/ folder?"
    exit 2;
fi

echo "Generating $outdir..."

chmod u+w $outdir 2>/dev/null

rm $outdir 2>/dev/null

$flips --create --ips base.nes working.nes "$outdir"
err=$?

chmod u+r $outdir
chmod a-wx $outdir

exit $?
