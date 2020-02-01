#!/bin/bash
echo "Copying in git hooks"
cp -r hooks .git

if [ -f base.nes ]
then
  echo "Marking base.nes as read-only"
  chmod a-wx base.nes
fi

if [ ! -f ./working.nes ]
then
  if [ -f ./base.nes ]
  then
	if [ -f ./patch.ips ]
	then
	  echo "Applying patch.ips to generate working.nes"
      ./apply.sh
	else
	  echo "No patch.ips nor working .nes file found; generating defaults..."
	  cp base.nes working.nes
	  chmod a+wr working.nes
	  ./make-patch.sh
	fi
  else
    echo "Warning: no base ROM or working ROM detected."
    echo "Copy base.nes into the repository and then run apply.sh"
  fi
else
  if [ ! -f ./base.nes ]
  then
    echo "Warning: working.nes but no base.nes file; you will not be able to generate patches."
    echo "(Perhaps you should delete working.nes and copy in a new base.nes?)"
  else
    echo "No changes made to base.nes or working.nes"
    echo "(If you intended to apply the patch now, then run ./apply.sh)"
  fi
fi

if [ $? -eq 0 ]
then
  echo "Setup complete."
else
  echo "Setup exited with errors. Please review."
fi