#!/bin/bash

[ ! -d "bin" ] && mkdir bin
if [ $1 = "pal" ]; then
    echo "PAL Mode"
    ./assets-pal.sh
    cd src
    dasm kernel.asm -DSYSTEM=0 -f3 -v5 -lrom.lst -orom.bin -srom.sym
else
    echo "NTSC Mode"
    #./assets-ntsc.sh
    cd src
    dasm kernel.asm -DSYSTEM=1 -f3 -v5 -lrom.lst -orom.bin -srom.sym
fi

mv ./rom.lst ../bin/rom.lst
mv ./rom.bin ../bin/rom.bin
mv ./rom.sym ../bin/rom.sym

cd ../
