#!/bin/bash

# Assets
#./assets.sh

# Source
[ ! -d "bin" ] && mkdir bin
cd src
if [ $1 = "pal" ]; then
    echo "PAL Mode"
    dasm kernel.asm -DSYSTEM=0 -f3 -v5 -lrom.lst -orom.bin -srom.sym
else
    echo "NTSC Mode"
    dasm kernel.asm -DSYSTEM=1 -f3 -v5 -lrom.lst -orom.bin -srom.sym
fi
mv ./rom.lst ../bin/rom.lst
mv ./rom.bin ../bin/rom.bin
mv ./rom.sym ../bin/rom.sym
cd ../
