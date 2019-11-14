#!/bin/bash

# Assets

## Playfield Images

echo "/assets/logo.png => /src/logo_image.asm"
python ./assets/pf_image.py -type full -split 0 -name LogoImage -in ./assets/logo.png -out ./src/logo_image.asm

echo "/assets/title.png => /src/title_image.asm"
python ./assets/pf_image.py -type full -split 0 -name TitleImage -in ./assets/title.png -out ./src/title_image.asm

echo "/assets/web.png => /src/objects/web_image.asm"
python ./assets/pf_image.py -type mirror -split 1 -name WebImage -in ./assets/web.png -out ./src/objects/web_image.asm

## Sprites

echo "/assets/player.png => /src/objects/spider_sprite.asm"
python ./assets/sprite_image.py -name SpiderSprite -in ./assets/player.png -out ./src/objects/spider_sprite.asm -mirror 0

echo "/assets/digits.png => /src/objects/score_digits.asm"
python ./assets/sprite_image.py -name ScoreDigits -in ./assets/digits.png -out ./src/objects/score_digits.asm -mirror 0

# Source

cd src
dasm kernel.asm -DNTSC=1 -DCOLOR_NTSC=1 -f3 -v5 -lrom.lst -orom.bin -srom.sym
mv ./rom.lst ../bin/rom.lst
mv ./rom.bin ../bin/rom.bin
mv ./rom.sym ../bin/rom.sym
cd ../
