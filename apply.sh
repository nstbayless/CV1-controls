#!/bin/bash
# applies the .ips patch to base.nes, generating working.nes
# Run with -f flag to replace existing working.nes

_force=false
flips="./flips/flips.exe"

while getopts ":f" opt; do
  case ${opt} in
    f ) #force
      _force=true
  esac
done

if [ ! -f base.nes ]
then
  >&2 echo "No base.nes ROM detected; cannot generate working.nes"
  exit 4;
else
  if [ -f working.nes ]
  then
    if [ "$_force" = false ]
    then
      >&2 echo "Error: working.nes already exists."
      >&2 echo "Rerun with -f flag to force overwriting working.nes"
      exit 1;
    else
      echo "Replacing existing working.nes"
      rm working.nes
    fi
  fi
  echo "Generating working.nes..."
  op=`uname`
  
  if [ "$op" = "Linux" ]
  then
    flips="./flips/flips-linux"
  fi
  
  if [ ! -f $flips ]
  then
      >&2 echo "flips not found; do you have the flips/ folder?"
      exit 2;
  fi
  
  cp base.nes working.nes
  if [ ! $? -eq 0 ]
  then
    >&2 echo "Error creating working.nes"
    exit 3;
  fi
  
  chmod u+x $flips
  
  chmod u+wr working.nes
  
  $flips --apply patch.ips working.nes
  err=$?
  
  chmod a-x working.nes
  chmod u+wr working.nes
  
  exit $err
fi
