### Prerequisites for this approach
- `systemd-boot` installed
- Optional: `UKI` (Unified Kernel Image) in `systemd-boot` configuration

1. Install neccessary packages:
```bash
sudo pacman -Syu sbctl
sudo sbctl create-keys
```

2. Go into `UEFI`, enable `Secure Boot` as *Custom Mode* and 
**CLEAR** all keys.

3. Reboot after enabling *Custom Mode* and **clearing** keys and check status:
```bash
sudo sbctl status
```
4. Enroll new keys:
```bash
sudo sbctl enroll-keys -m
```
5. Verify:
```bash
sudo sbctl verify
```
> This command will return all of the files that needs to  be signed in next step.

6. Sign required files (e.g.):
```bash
sudo sbctl sign -s /boot/efi/EFI/systemd/systemd-bootx64.efi
sudo sbctl sign -s /boot/efi/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/efi/EFI/Linux/arch.efi
```

> If some file name has been misspelled, you can just:
```bash
sudo sbctl remove-file [file name]
```

7. Verify, if all files were properly signed:
```bash
sudo sbctl verify
```

8. Enable `ALL_CONFIG` in `mkinitcpio`:
```bash
sudo nano /etc/mkinitcpio.d/linux.preset
```
**Uncomment** `ALL_config="/etc/mkinitcpio.conf"`

9. Re-create `mkinitcpio` config:
```bash
sudo mkinitcpio -P
```

10. Reboot again, go back into `UEFI`
11. Switch **Custom Mode** to `Standard Mode`, **but please, be aware!!!**: `DO NOT` missclick the *default variables*. Click `NO`.
    If you happen to missclick, you have to redo the whole process.
12. Enable `Secure Boot` and go back into your system.

Congrats!
