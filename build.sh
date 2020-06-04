# note: asm6f must be on the PATH.
bases=(base.nes base-prg0.nes base-prg1.nes base-uc.nes base-thr.nes)
srcs=(patch.asm patch.asm patch.asm patch.asm patch-thr.asm)
configs=(STANDARD PRG0 PRG1 UC THR)
outs=(cv1-controls cv1-prg0-controls cv1-prg1-controls cv1-uc-controls cv1-thr-controls)

for i in 0 1 2 3 4
do
    BASE="${bases[$i]}"
    CONFIG="${configs[$i]}"
    SRC="${srcs[$i]}"
    OUT="${outs[$i]}"

    echo "------------------------------------------"
    echo "generating patch #$i ($OUT) from $BASE."

    if [ -f "$BASE" ]
    then
        chmod a-w "$BASE"
        echo "INCNES \"$BASE\"" > opt-base.asm
        which asm6f > /dev/null
        if [ $? != 0 ]
        then
            echo "asm6f is not on the PATH."
            continue
        fi
        printf 'base size 0x%x\n' `stat --printf="%s" "$BASE"`
        asm6f -c -n -i "-d$CONFIG" "-dUSEBASE" "$SRC" "$OUT.nes"
        printf 'out size 0x%x\n' `stat --printf="%s" "$OUT.nes"`
        
        if [ $? != 0 ]
        then
            continue
        fi
        
        #continue
        if ! [ -f patch.ips ]
        then
            echo
            echo "Failed to create patch.ips"
            continue
        fi
        echo
        
        # apply ips patch
        chmod a+x flips/flips-linux
        rm patch.nes 2>&1 > /dev/null
        flips/flips-linux --apply "$OUT.ips" "$BASE" patch.nes
        if ! [ -f "patch.nes" ]
        then
            echo "Failed to apply patch $i."
            continue
        fi
        echo "patch generated."
        md5sum "${OUT}.nes"
        
        cmp "$OUT.nes" patch.nes
        if [ $? != 0 ]
        then
            continue
        fi
        
        # ipsnect map
        echo
        ipsnect "$OUT.ips" "$BASE" > "$OUT.map"
        if [ $? != 0 ]
        then
            echo
            echo
            echo "ipsnect failed. (Is ipsnect on the PATH?)"
            echo "(this step is optional anyway.)"
        fi
    else
        echo "Must supply base nes file $BASE"
    fi
done

echo "============================================"
echo "Assembling export."

export="cv1-controls"

rm -rf $export > /dev/null
mkdir $export
cp cv1-controls.ips $export/
cp cv1-uc-controls.ips $export/
cp cv1-thr-controls.ips $export/
cp README-export.md $export/README.md

rm cv1-controls.zip 2>&1 > /dev/null
zip -r cv1-controls.zip $export/*