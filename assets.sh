#!/bin/bash

# Playfield Images

echo "/assets/logo.png => /src/logo_image.asm"
python ./assets/pf_image.py -type full -name LogoImage -in ./assets/logo.png -out ./src/logo_image.asm

echo "/assets/title.png => /src/title_image.asm"
python ./assets/pf_image.py -type full -name TitleImage -in ./assets/title.png -out ./src/title_image.asm

echo "/assets/web.png => /src/game_image.asm"
python ./assets/pf_image.py -type mirror -name GameImage -in ./assets/web.png -out ./src/game_image.asm

# Sprites

echo "/assets/player.png => /src/game_player.asm"
python ./assets/sprite_image.py -name GamePlayerSprite -in ./assets/player.png -out ./src/game_player.asm
