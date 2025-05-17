sudo pacman -S edk2-shell

sudo cp /usr/share/edk2-shell/x64/Shell.efi /boot/shellx64.efi

sudo nano /boot/loader/loader.conf
console-mode max


sudo nano /boot/windows.nsh
FS5:\EFI\Microsoft\Boot\Bootmgfw.efi
DOSTOSOWAC JAK ULEGLO ZMIANIE TE FS5 przez Shella (komenda map)

sudo nano /boot/loader/entries/windows.conf

title   Windows (via EFI Shell)
efi     /shellx64.efi
options -nointerrupt -noconsolein -noconsoleout windows.nsh
