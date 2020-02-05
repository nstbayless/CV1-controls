# note: asm6f must be on the PATH.
BASE=base.nes
if [ -f "$BASE" ]
then
    chmod a-w $BASE
    which asm6f > /dev/null
    if [ $? != 0 ]
    then
        echo "asm6f is not on the PATH."
        exit
    fi
    asm6f -l -c -n -i patch.asm
    
    #exit
    if ! [ -f patch.ips ]
    then
        echo
        echo "Failed to create patch.ips"
        exit
    fi
    echo
    
    # apply ips patch
    chmod a+x flips/flips-linux
    flips/flips-linux --apply patch.ips $BASE patch.nes
    if ! [ -f "patch.nes" ]
    then
        echo "Failed to apply the patch."
        exit
    fi
    echo "patch generated."
    
    # ipsnect map
    echo
    ipsnect patch.ips > patch.map
    if [ $? != 0 ]
    then
        echo
        echo
        echo "ipsnect failed. (Is ipsnect on the PATH?)"
        echo "(this step is optional anyway.)"
        exit
    fi
    echo
else
    echo "Must supply base nes file $BASE"
fi