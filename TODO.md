# Development To-Do list

## TODO
- [x] Remove logo screen for more rom real estate
- [x] Add copyright info to title screen
- [ ] Missle 1 color to spider color when no swatter
- [x] Use difficulty switches to change variable scaling, not starting level (always start on level 1)
- [ ] Health/power/points pickup
- [ ] Game Over text
- [ ] Better success screen (baby spiders?)
- [x] PAL Support
- [ ] Add level points matrix to manual
- [x] Remove background color variations
- [ ] Improve playfield level color choices

## BUGS
- [ ] ~~Score Midline color swap timing~~
- [x] Lost scanline when spider is at the bottom of the playfield

## Maybe
- [ ] Web playfield variations
- [ ] Boss levels: restrict spider to top shooting down with missle 0
- [ ] Bug boss level: use bug sprite from intro with missle 1
- [ ] Swatter boss level: use standard sprite (or larger flipped), no missle
- [ ] Reduce levels to 10; 5 -> Bug Boss -> 5 -> Swatter Boss
- [x] Creep up with swatter
- [ ] 4 digit score without level clearing
- [ ] Bonus bug running across top of screen
- [ ] ~~Only write graphics registers after wsync to reduce mid-line graphical glitches~~

## Past TODO

- [x] Level variable with increasing difficulty and changing color palette
- [x] Difficulty switch support to increase starting difficulty
- [x] Health bar and level counter
- [x] Black and white TV switch support
- [x] Game select switch support? (Easter egg?)
- [x] Revised game kernel
- [x] Swatter collision logic
- [x] Swatter enemy sprite, kernel routines, and animation
- [x] Add strands of web holding each spider up on title screen using missles and balls
- [x] Optimize game kernel loop for rom size
- [x] Improve level progression
- [x] Improve title screen music
- [x] Increase game music speed with level
- [x] Support second joystick for aiming and firing
- [x] Spawn bugs at the sides of playfield area
- [x] Increase player health with each bug
- [x] Add success screen (using over.asm code) when reached 99 points on level 20

## Past BUGS

- [x] Improve multiple sprite scanlines
- [x] Start on button release
- [x] Spider boundary
- [x] Line spawning
- [x] Fix playfield loading of title after color switch
- [x] Fix line wsync
- [x] Logo b/w mode
- [x] COLUP1 when swatter isn't visible
