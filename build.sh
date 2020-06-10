# note: asm6f must be on the PATH.
bases=(base-prg0.nes base-prg1.nes base-uc.nes base-thr.nes base-cvbm.nes base-ood.nes base-comv2.nes)
srcs=(patch.asm patch.asm patch.asm patch-thr.asm patch.asm patch.asm patch.asm)
configs=(PRG0 PRG1 UC THR HACK HACKPRG0 COMV2)
outs=(prg0 prg1 uc thr hack-prg1 hack-prg0 comv2)
hc="hack-compatible"
folders=("prg0" "prg1" "$hc/ultimate-cv" "$hc/the-holy-relics" "$hc/cv-hack-prg1" "$hc/cv-hack-prg0" "$hc/chorus-of-mysteries")

# FALLTHROUGH_STAIRS is default behaviour, so the asm actually ignores it.
stair_style_defs=("FALLTHROUGH_STAIRS" "LATCH_STAIRS" "CATCH_STAIRS")
stair_styles=("-fallthrough" "-latch" "-catch")

export="cv1-controls"

if [ -d "$export" ]
then
    rm -r $export
fi
mkdir $export
cp README.md $export/README.md

for i in 0 1 2 3 4 5 6
do
    BASE="${bases[$i]}"
    CONFIG="${configs[$i]}"
    SRC="${srcs[$i]}"
    OUT="cv1-controls-${outs[$i]}"
    folder="${folders[$i]}"
    
    if [ ! -f "$SRC" ]
    then
        echo "Base ROM $SRC not found -- skipping."
        continue
    fi
    
    if [ ! -d "$export/hack-compatible" ]
    then
        mkdir "$export/hack-compatible"
    fi
    
    mkdir "$export/$folder"
    
    for k in 0 1 2
    do
        vcancel_def=""
        vcancel_enabled="vcancel enabled"
        vcancel_out="-vcancel"
        if [ $k -eq 1 ]
        then
            vcancel_def="-dNO_VCANCEL"
            vcancel_enabled="vcancel disabled"
            vcancel_out=""
        fi
        if [ $k -eq 1 ]
        then
            vcancel_def="-dNO_AIRCONTROL"
            vcancel_enabled="air control disabled"
            vcancel_out="-stairs_only"
        fi
        
        for j in 0 1 2
        do
            stair_style_def="${stair_style_defs[$j]}"
            stair_style="${stair_styles[$j]}"
            
            if [ $k -eq 2 ]
            then
                if [ $j -eq 0 ]
                then
                    # skip pointless "fallthrough-stairs_only" configuration.
                    continue
                fi
            fi
            
            outfile="$OUT$stair_style$vcancel_out"
            
            echo "------------------------------------------"
            echo "generating patch ($outfile) from $BASE with $stair_style_def and $vcancel_enabled"

            if [ -f "$BASE" ]
            then
                chmod a-w "$BASE"
                echo "INCNES \"$BASE\"" > inc-base.asm
                which asm6f > /dev/null
                if [ $? != 0 ]
                then
                    echo "asm6f is not on the PATH."
                    continue
                fi
                printf 'base size 0x%x\n' `stat --printf="%s" "$BASE"`
                asm6f -c -n -i "-d$CONFIG" $vcancel_def "-dUSEBASE" "-d$stair_style_def" "$SRC" "$outfile.nes"
                
                if [ $? != 0 ]
                then
                    exit
                fi
                
                printf 'out size 0x%x\n' `stat --printf="%s" "$outfile.nes"`
                
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
                flips/flips-linux --apply "$outfile.ips" "$BASE" patch.nes
                if ! [ -f "patch.nes" ]
                then
                    echo "Failed to apply patch $i."
                    continue
                fi
                echo "patch generated."
                md5sum "$outfile.nes"
                
                cmp "$outfile.nes" patch.nes
                if [ $? != 0 ]
                then
                    continue
                fi
                
                cp $outfile.ips "$export/$folder/"
                
                # ipsnect map
                echo
                ipsnect "$outfile.ips" "$BASE" > "$outfile.map"
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
    done
done

echo "============================================"
echo "Assembling export."

rm cv1-controls.zip 2>&1 > /dev/null
zip -r cv1-controls.zip $export/*