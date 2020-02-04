# note: asm6f must be on the PATH.
if [ -f "base.nes" ]
then
    chmod a-w base.nes
    which asm6f > /dev/null
    if [ $? != 0 ]
    then
        echo "asm6f is not on the PATH."
        exit
    fi
    asm6f -l -c -n patch.asm patch.nes
    
    #exit
    if ! [ -f patch.nes ]
    then
        echo
        echo "Failed to create patch.nes"
        exit
    fi
    echo
    
    # create ips patch
    chmod a+x flips/flips-linux
    flips/flips-linux --create base.nes patch.nes patch.ips
    if ! [ -f "patch.ips" ]
    then
        echo "flips patch generation failed."
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
    echo "Must supply base.nes"
fi