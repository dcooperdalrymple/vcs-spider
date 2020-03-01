# Development To-Do list

## TODO

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

## BUGS

- [x] Improve multiple sprite scanlines
- [x] Start on button release
- [x] Spider boundary
- [x] Line spawning
- [x] Fix playfield loading of title after color switch
- [x] Fix line wsync
- [x] Logo b/w mode
- [x] COLUP1 when swatter isn't visible

## Maybe

- [ ] ~~Increase player speed with level~~
- [ ] ~~Increase stun length with level~~
- [x] Add success screen (using over.asm code) when reached 99 points on level 20
- [ ] Only write graphics registers after wsync to reduce mid-line graphical glitches
