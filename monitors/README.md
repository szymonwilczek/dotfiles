# Quick Guide: Overclocking Monitor Refresh Rates on Fedora (GNOME, AMD, GRUB) using Custom EDID

This guide outlines how to force custom refresh rates for your monitors when the default EDID data prevents you from selecting higher frequencies in GNOME settings. The solution involves loading a modified EDID file directly via the Kernel at boot time.

### Prerequisites
- **System**: Fedora Linux (Workstation).
- **Environment**: GNOME (Wayland or X11).
- **GPU**: AMD Radeon (using open-source kernel drivers). *For NVIDIA tutorial, look [here](../../Arch/custom-resolution/Wayland Custom Resolution.md)
- **Bootloader**: GRUB (managed via grubby).
- **Files**: Ability to create custom EDID files (e.g., using CRU - Custom Resolution Utility on Windows).
- **Knowledge**: Your display output names (e.g., DP-1, HDMI-A-1).

## Step 1. Prepare Your Custom EDID Files

Using CRU on Windows, create the desired custom resolutions and refresh rates. Export the EDID for each monitor as a separate `.bin` file.

- Example filenames used in this guide: `asus_maly.bin`, `iiyama_left.bin`.

## Step 2. Identify Video Output Names

You need to know which physical port corresponds to which monitor. Run the following command in the terminal:

```bash
grep "^connected" /sys/class/drm/*/status
```

The output will look similar to this:

`/sys/class/drm/card1-DP-1/status:connected` -> Your output name is **DP-1**
`/sys/class/drm/card1-HDMI-A-1/status:connected` -> Your output name is **HDMI-A-1**

*Tip*: To verify which monitor is which, you can check the available modes for a specific port:

```bash
cat /sys/class/drm/card1-DP-1/modes
```

## Step 3. Place Files in the System

Fedora looks for firmware in `/usr/lib/firmware`. Create the directory and copy your files there.

```bash
# Create the directory
sudo mkdir -p /usr/lib/firmware/edid/

# Copy your files (adjust path to where your files are currently located)
sudo cp asus_maly.bin /usr/lib/firmware/edid/
sudo cp iiyama_left.bin /usr/lib/firmware/edid/
```

## Step 4. Add Files to Initramfs (Dracut)

This is a **crucial step**. The graphics driver loads very early during the boot process (KMS), so the EDID files must be present inside the initial RAM disk (initramfs), not just on the storage drive.

Create a Dracut configuration file to include these files:

```bash
echo 'install_items+=" /usr/lib/firmware/edid/asus_maly.bin /usr/lib/firmware/edid/iiyama_left.bin "' | sudo tee /etc/dracut.conf.d/99-edid.conf
```
Regenerate the initramfs image:

```bash
sudo dracut --force
```

## Step 5. Configure Kernel Parameters (GRUB)

Fedora uses the grubby tool to safely edit kernel arguments. You need to set the `drm.edid_firmware` parameter to map specific files to specific outputs.

Syntax: `OUTPUT:path/to/file` (path is relative to `/usr/lib/firmware`).

```bash
sudo grubby --update-kernel=ALL --args="drm.edid_firmware=DP-1:edid/asus_maly.bin,HDMI-A-1:edid/iiyama_left.bin"
```
*(Ensure you replace `DP-1` and `HDMI-A-1` with your actual output names from Step 2).*

## Step 6. Reboot and Verify

Reboot your computer:
```bash
sudo reboot
```

After rebooting:

Go to `Settings` -> `Displays`.
You should now be able to select the new, higher refresh rates.

*Optional*: Verify the kernel loaded the parameters:

```bash
cat /proc/cmdline
```

You should see the `drm.edid_firmware=...` string in the output.

## How to Revert Changes (Troubleshooting)

If you lose display output after rebooting, you can temporarily disable the custom EDID:

- In the GRUB boot menu, press `e` to edit.
- Find the line starting with linux and delete the `drm.edid_firmware=...` section.
- Press `Ctrl+X` or `F10` to boot.

To permanently remove the configuration from the system:

```bash
# Remove kernel arguments
sudo grubby --update-kernel=ALL --remove-args="drm.edid_firmware=DP-1:edid/asus_maly.bin,HDMI-A-1:edid/iiyama_left.bin"

# Remove Dracut config and regenerate
sudo rm /etc/dracut.conf.d/99-edid.conf
sudo dracut --force
```
