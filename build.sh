#!/bin/bash

# Assets
#./asset.sh

# Source
cd src
dasm kernel.asm -DNTSC=1 -DCOLOR_NTSC=1 -f3 -v5 -lrom.lst -orom.bin -srom.sym
mv ./rom.lst ../bin/rom.lst
mv ./rom.bin ../bin/rom.bin
mv ./rom.sym ../bin/rom.sym
cd ../
