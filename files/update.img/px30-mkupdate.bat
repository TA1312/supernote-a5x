move Image\boot.img Image\boot.img.tmp
move Image\recovery.img Image\recovery.img.tmp
move Image\kernel.img Image\kernel.img.tmp

move Image\boot.img.krnl Image\boot.img
move Image\recovery.img.krnl Image\recovery.img
move Image\kernel.img.krnl Image\kernel.img

copy Image\parameter.txt .\parameter

Afptool -pack ./ Image\tmp-update.img

RKImageMaker.exe -RKPX30 Image\MiniLoaderAll.bin  Image\tmp-update.img update.img -os_type:androidos

move Image\boot.img Image\boot.img.krnl
move Image\recovery.img Image\recovery.img.krnl
move Image\kernel.img Image\kernel.img.krnl

move Image\boot.img.tmp Image\boot.img
move Image\recovery.img.tmp Image\recovery.img
move Image\kernel.img.tmp Image\kernel.img

del Image\tmp-update.img

pause 
