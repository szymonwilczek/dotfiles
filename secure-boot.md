- archinstall systemd-boot & UKI (Unified Kernel Image)

sudo pacman -Syu sbctl
sudo sbctl create-keys

Secure Boot w Custom Mode w UEFI (i wyczyszczenie kluczy)

sudo sbctl status
sudo sbctl enroll-keys -m

sudo sbctl verify

Podpisanie wszystkiego (np.:)
sudo sbctl sign -s /boot/efi/EFI/systemd/systemd-bootx64.efi
sudo sbctl sign -s /boot/efi/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/efi/EFI/Linux/arch.efi
vmlinuz tez

> Jakby byl missclick
sudo sbctl remove-file plik

sudo sbctl verify

sudo nano /etc/mkinitcpio.conf
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
MODULES puste

sudo nano /etc/mkinitcpio.d/linux.preset
odkomentowac ALL_config="/etc/mkinitcpio.conf"
sudo mkinitcpio -P

Potem w UEFI:
Zmienic na StandardMode (w dialogu przy powrocie do defaultow dac "NO")
Wlaczyc SecureBoot
