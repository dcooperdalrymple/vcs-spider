@echo off
dasm spider.asm -DNTSC=1 -DCOLOR_NTSC=1 -f3 -lspider.lst -ospider.bin
copy spider.lst bin\spider.lst
copy spider.bin bin\spider.bin
del spider.lst
del spider.bin
