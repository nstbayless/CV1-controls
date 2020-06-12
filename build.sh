# note: asm6f must be on the PATH.
bases=(base.nes base-hack.nes base-thr.nes base-reborn.nes)
configs=(STANDARD HACK THR REBORN)
outs=(standard hack thr reborn)
hc="patches-for-other-hacks"
folders=("." "$hc/hack" "$hc/the-holy-relics" "$hc/cv-reborn")

stair_style_defs=("FALLTHROUGH_STAIRS" "LATCH_STAIRS" "CATCH_STAIRS")
stair_styles=("fallthrough" "latch" "catch")

export="cv1-controls"

if [ -d "$export" ]
then
    rm -r $export
fi
mkdir $export
cp README.md $export/README.md

for i in {0..3}
do
    BASE="${bases[$i]}"
    CONFIG="${configs[$i]}"
    SRC="patch.asm"
    if [ "$CONFIG" == "THR" ]
    then
        SRC="patch-thr.asm"
    fi
    TAG="${outs[$i]}"
    if [ $TAG != "standard" ]
    then
        OUT="cv1-controls-$TAG"
    else
        OUT="cv1-controls"
    fi
    folder="${folders[$i]}"
    
    if [ ! -f "$BASE" ]
    then
        echo "Base ROM $BASE not found -- skipping."
        continue
    fi
    
    echo
    echo "Producing hacks for $BASE"
    
    if [ ! -d "$export/$hc" ]
    then
        mkdir "$export/$hc"
    fi
    
    mkdir "$export/$folder"
    
    #iterate: vcancel / air control
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
        
        if [ $k -eq 2 ]
        then
            vcancel_def="-dNO_AIRCONTROL"
            vcancel_enabled="air control disabled"
            vcancel_out="-stairs_only"
        fi
        
        #iterate: stair style
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
            
            folder="${folders[$i]}"
            folder="$folder/$stair_style"
            
            if [ ! -d "$export/$folder" ]
            then
                mkdir "$export/$folder"
            fi
            
            # iterate: weight
            for w in 0 1
            do
                if [ $k -eq 2 ]
                then
                    # skip pointless "stairs_only-weight" configuration
                    continue
                fi
                
                weight_def="-dWEIGHT"
                weight_enabled="weight enabled"
                weight_out="-weight"
                
                if [ $w -eq 1 ]
                then
                    weight_def=""
                    weight_enabled="weight disabled"
                    weight_out=""
                fi
                
                outfile="$OUT-$stair_style$vcancel_out$weight_out"
                
                echo "------------------------------------------"
                echo "generating patch ($outfile) from $BASE with $stair_style_def, $vcancel_enabled, and $weight_enabled"

                if [ -f "$BASE" ]
                then
                    chmod a-w "$BASE"
                    echo "INCNES \"$BASE\"" > inc-base.asm
                    echo "INCLUDE \"opt/opt-$TAG.asm\"" > inc-opt.asm
                    which asm6f > /dev/null
                    if [ $? != 0 ]
                    then
                        echo "asm6f is not on the PATH."
                        continue
                    fi
                    printf 'base size 0x%x\n' `stat --printf="%s" "$BASE"`
                    asm6f -c -n -i "-d$CONFIG" $vcancel_def $weight_def "-dUSEBASE" "-d$stair_style_def" "$SRC" "$outfile.nes"
                    
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
done

echo "============================================"
echo "Assembling export."

rm cv1-controls.zip 2>&1 > /dev/null
zip -r cv1-controls.zip $export/*