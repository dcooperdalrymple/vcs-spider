#!/bin/bash

# Assets

## Playfield Images

echo "/assets/logo.png => /src/logo_image.asm"
python ./assets/pf_image.py -type full -split 0 -name LogoImage -in ./assets/logo.png -out ./src/logo_image.asm

echo "/assets/title.png => /src/title_image.asm"
python ./assets/pf_image.py -type full -split 0 -name TitleImage -in ./assets/title.png -out ./src/title_image.asm

echo "/assets/web.png => /src/game_image.asm"
python ./assets/pf_image.py -type mirror -split 1 -name GameImage -in ./assets/web.png -out ./src/game_image.asm

## Sprites

echo "/assets/player.png => /src/game_player.asm"
python ./assets/sprite_image.py -name GamePlayerSprite -in ./assets/player.png -out ./src/game_player.asm

# Source

cd src
dasm kernel.asm -DNTSC=1 -DCOLOR_NTSC=1 -f3 -v5 -lrom.lst -orom.bin -srom.sym
mv ./rom.lst ../bin/rom.lst
mv ./rom.bin ../bin/rom.bin
mv ./rom.sym ../bin/rom.sym
cd ../
