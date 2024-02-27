# Spider Web
> Spider Web game for Atari VCS/2600<br />
> Created by D Cooper Dalrymple 2018 - [dcdalrymple.com](https://dcdalrymple.com/)<br />
> Licensed under GNU LGPL V3.0<br />
> Last revision: May 23rd, 2022

<a href="https://www.tindie.com/products/relic/spider-web-for-the-atari-2600/?ref=offsite_badges&utm_source=sellers_dcdalrymple&utm_medium=badges&utm_campaign=badge_small"><img src="https://d2ss6ovg47m0r5.cloudfront.net/badges/tindie-smalls.png" alt="I sell on Tindie" width="200" height="55"></a>

## Compilation

The **dasm macro assembler** is required to compile this program on your local machine. Pre-compiled rom files are also available in the `bin` folder. To download the dasm executables, visit [dasm-dillon.sourceforge.net](http://dasm-dillon.sourceforge.net).

### Linux

Make sure that you have the `dasm` executable copied into a location in your bash path. Compile the project using the by giving the build file execute permission `chmod +x ./build.sh` and running it with `./build.sh` in your terminal while inside the `vcs-spider` directory.

### Windows

Make sure that you have the `dasm` executable copied into a location in your path variable. Either run the `build.bat` program from a command prompt or double click it in your file explorer.

## Distribution

Physical distribution for commercial use (whether in cartridge or compact format) is not permitted whereas for personal use is strongly recommended as this game is intended to be used on the original Atari 2600 hardware.

## Built With

* Assembled with dasm from [dasm-dillon.sourceforge.net](http://dasm-dillon.sourceforge.net)
* Tested with Stella from [stella-emu.github.io](https://stella-emu.github.io)
* Tested with real Atari 2600 using custom EEPROM cartridges

## License

This project is licensed under GNU LGPL V3.0 - see the [LICENSE](LICENSE) file for details.
