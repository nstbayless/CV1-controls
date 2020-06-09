"""
reads file containing hex data for stairs, one per line,
prints out human-readable meaning of stairs
e.g. file `./in` should be like:

66B0
B6C0
8789
C5D1
C769
91B9
B468
5088
6389
00
"""

def printdir(dir):
    if dir == 0:
        print("  dir: 0 (bottom-left)")
    elif dir == 1:
        print("  dir: 1 (bottom-right)")
    elif dir == 2:
        print("  dir: 2 (top-right)")
    elif dir == 3:
        print("  dir: 3 (top-left)")

def print_stair(data, i):
    if data == 0:
        print("EOL")
    else:
        print("Stair " + hex(i)[2:] + '-' + hex(i+1)[2:] + ":", "[" +hex(data)[2:] + "]")
        level = (data & 0x0400) >> 10
        print("  sublevel:", level)
        if data & 0x0800:
            print("  ~~Unknown bit (0x08) set~~")
        dir = (data & 0x0300) >> 8
        printdir(dir)
        x = (data & 0x00f8) | ((data & 0x0007) << 8)
        
        # for some reason, dir=2 means x+=8
        if dir == 2:
            x += 8
        
        print("  x:", '#' + hex(x)[2:])
        y = (data & 0xf000) >> 8
        print("  y:", '#' + hex(y)[2:])
        print()
        
with open("in") as f:
    i = 0
    for line in f:
        data = int(line.strip(), 16)
        print_stair(data, i * 2)
        i += 1
        if data == 0:
            break