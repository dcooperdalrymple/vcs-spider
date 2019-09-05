@echo off
cd src
dasm kernel.asm -DNTSC=1 -DCOLOR_NTSC=1 -f3 -lrom.lst -orom.bin
copy .\rom.lst ..\bin\rom.lst
copy .\rom.bin ..\bin\rom.bin
del .\rom.lst
del .\rom.bin
cd ..\
