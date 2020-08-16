#!/bin/bash

# Assets

## Playfield Images

#echo "/assets/logo.png => /src/logo_image.asm"
#python ./assets/pf_image.py -type full -split 1 -reverse 1 -name LogoImage -in ./assets/logo.png -out ./src/logo_image.asm

echo "/assets/title-frame-top.png => /src/title_frame_top.asm"
python ./assets/pf_image.py -type full -split 0 -reverse 0 -name TitleFrameTop -in ./assets/title-frame-top.png -out ./src/title_frame_top.asm

echo "/assets/title-frame-bottom.png => /src/title_frame_bottom.asm"
python ./assets/pf_image.py -type full -split 0 -reverse 0 -name TitleFrameBottom -in ./assets/title-frame-bottom.png -out ./src/title_frame_bottom.asm

echo "/assets/score-label.png => /src/objects/score_label.asm"
python ./assets/pf_image.py -type full -split 0 -reverse 0 -name ScoreLabel -in ./assets/score-label.png -out ./src/objects/score_label.asm

echo "/assets/web_pal.png => /src/objects/web_image.asm"
python ./assets/pf_image.py -type mirror -split 1 -reverse 0 -name WebImage -in ./assets/web_pal.png -out ./src/objects/web_image.asm

#echo "/assets/over_lose.png => /src/over_lose_image.asm"
#python ./assets/pf_image.py -type mirror -split 1 -reverse 1 -name OverLoseImage -in ./assets/over_lose.png -out ./src/over_lose_image.asm

#echo "/assets/over_win.png => /src/over_win_image.asm"
#python ./assets/pf_image.py -type mirror -split 1 -reverse 1 -name OverWinImage -in ./assets/over_win.png -out ./src/over_win_image.asm

## Sprites

echo "/assets/title-spider.png => /src/title_spider.asm"
python ./assets/sprite_image.py -name TitleSpider -in ./assets/title-spider.png -out ./src/title_spider.asm -reverse 1 -flip 0

echo "/assets/title-bug.png => /src/title_bug.asm"
python ./assets/sprite_image.py -name TitleBug -in ./assets/title-bug.png -out ./src/title_bug.asm -reverse 1 -flip 0

echo "/assets/title-logo.png => /src/title_logo.asm"
python ./assets/sprite_image.py -name TitleLogo -in ./assets/title-logo.png -out ./src/title_logo.asm -reverse 1 -flip 0

echo "/assets/player.png => /src/objects/spider_sprite.asm"
python ./assets/sprite_image.py -name SpiderSprite -in ./assets/player.png -out ./src/objects/spider_sprite.asm -reverse 1 -flip 0

echo "/assets/swatter.png => /src/objects/swatter_sprite.asm"
python ./assets/sprite_image.py -name SwatterSprite -in ./assets/swatter.png -out ./src/objects/swatter_sprite.asm -reverse 1 -flip 0

echo "/assets/digits-pad.png => /src/objects/score_digits.asm"
python ./assets/sprite_image.py -name ScoreDigits -in ./assets/digits-pad.png -out ./src/objects/score_digits.asm -reverse 0 -flip 0

echo "/assets/digits-pad.png => /src/objects/score_digits_flip.asm"
python ./assets/sprite_image.py -name ScoreDigitsFlip -in ./assets/digits-pad.png -out ./src/objects/score_digits_flip.asm -reverse 0 -flip 1
