cd src
dasm spider.asm -DNTSC=1 -DCOLOR_NTSC=1 -f3 -v5 -lspider.lst -ospider.bin
mv ./spider.lst ../bin/spider.lst
mv ./spider.bin ../bin/spider.bin
cd ../
