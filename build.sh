# note: asm6f must be on the PATH.
if [ -f "base.nes" ]
then
    which asm6f > /dev/null
    if [ $? != 0 ]
    then
        echo "asm6f is not on the PATH."
        exit
    fi
    asm6f patch.asm
    if [ -f patch.bin ]
    then
        # ips patch
        chmod a+x flips/flips-linux
        flips/flips-linux --create --ips base.nes patch.bin patch.ips
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
    fi
else
    echo "Must supply base.nes"
fi