# note: asm6f must be on the PATH.
if [ -f "base.nes" ]
then
    chmod a-w base.nes
    which nesasm > /dev/null
    if [ $? != 0 ]
    then
        echo "nesasm is not on the PATH."
        exit
    fi
    cl65 patch.s -C ./nes.cfg -o patch.nes -v
    
    #exit
    
    if ! [ -f patch.nes ]
    then
        echo "Failed to create patch.o"
        exit
    fi
    
    # ips patch
    chmod a+x flips/flips-linux
    flips/flips-linux --create --ips base.nes patch.nes patch.ips
    if ! [ -f "patch.ips" ]
    then
        echo "flips patch generation failed."
        exit
    fi
    echo "Patch generated."

    # ipsnect map
    echo
    ipsnect patch.ips
    if [ $? != 0 ]
    then
        echo
        echo
        echo "ipsnect failed. (Is ipsnect on the PATH?)"
        echo "(this step is optional.)"
        exit
    fi
    echo
else
    echo "Must supply base.nes"
fi