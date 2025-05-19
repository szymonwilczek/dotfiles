1. Firstly, install `shell` script:
```bash
sudo pacman -S  edk2-shell
```

2. Copy files to your `boot` dir:
```bash
sudo cp /usr/share/edk2-shell/x64/Shell.efi /boot/shellx64.efi
```

3. Edit `loader` configuration:
```bash
sudo nano /boot/loader/loader.conf
```

	Paste there:
```bash
console-mode max
```

4. Map Windows' `EFI` to Linux's `EFI`:
```bash
sudo nano /boot/windows.nsh
```

	Paste there:
```bash
FS5:\EFI\Microsoft\Boot\Bootmgfw.efi
```
> This step needs additional configuration if your disk is not labeled as `FS5` -> through Shell from `systemd-boot`

5. Create Windows loader entry:
```bash
sudo nano /boot/loader/entries/windows.conf
```

	Paste there:
```bash
title   Windows (via EFI Shell)
efi     /shellx64.efi
options -nointerrupt -noconsolein -noconsoleout windows.nsh
```
