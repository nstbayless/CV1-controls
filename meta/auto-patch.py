"""
Requires python 3
usage:
    auto-patch.py base.nes tag
    
    finds unused regions in bank6 and generates opt-tag.asm
"""

def uhex(i):
    return hex(i).upper()[2:]

import sys

if len(sys.argv) != 3:
    print("Error: requires 2 arguments.")
    sys.exit(1)
    
base=sys.argv[1]
tag=sys.argv[2]

intervals = []

with open(base, mode='rb') as f: # b is important -> binary
    f.read(0x10) # read header
    
    for i in range(0, 7):
        bank = f.read(0x4000) # read a whole bank
    
    start=0
    i=0
    MINLEN=0x20
    
    for byte in bank:
        b=int(byte)
        if b != 0xff or i + 1 == 0x4000:
            l = i - start
            if l >= MINLEN:
                intervals.append([start, l])
            start = i + 1
        i=i+1
    
    # sort by length of the intervals
    intervals.sort(key=lambda x : - x[1])
    
    print("intervals:", intervals)
    
    if len(intervals) == 0:
        print("No intervals found.")
        sys.exit(2)
    
    # for simplicity, we read let the hack itself read the stair base
    # so that this script doesn't need to.
    opt="read_stage_stairs_base_from=$9CC2\n"
    
    MARGIN = 3
    
    if intervals[0][1] > 710 + MARGIN * 2:
        opt += "BANK6_OFFSET = $" + uhex(intervals[0][0] + 0x8000 + MARGIN) + "\n"
    elif len(intervals) >= 2 and intervals[0][1] > 455 + MARGIN * 2 and intervals[1][1] + > 173 + MARGIN * 2: 
        opt += "BANK6_OFFSET = $" + uhex(intervals[0][0] + 0x8000 + MARGIN) + "\n"
        opt += "BANK6_TERTIARY_OFFSET = $" + uhex(intervals[1][0] + 0x8000 + MARGIN) + "\n"
    elif len(intervals) >= 3 and intervals[0][1] > 455 + MARGIN * 2 and intervals[1][1] + > 122 + MARGIN * 2 and and intervals[2][1] + > 52 + MARGIN * 2: 
        opt += "BANK6_OFFSET = $" + uhex(intervals[0][0] + 0x8000 + MARGIN) + "\n"
        opt += "BANK6_TERTIARY_OFFSET = $" + uhex(intervals[1][0] + 0x8000 + MARGIN) + "\n"
        opt += "QUARTIARY_BANK6_OFFSET = $" + uhex(intervals[2][0] + 0x8000 + MARGIN) + "\n"
    print(opt)