## My personal performance commands to quickly setup whole workstation

### CPU Temperature

```sh
sudo tee /etc/udev/rules.d/50-amd-epp.rules > /dev/null << 'EOF'
ACTION=="add", SUBSYSTEM=="cpu", ATTR{cpufreq/energy_performance_preference}="balance_performance"
ACTION=="add", SUBSYSTEM=="cpu", ATTR{cpufreq/scaling_governor}="powersave"
EOF
```

### Filesystem

```sh
sudo sed -i 's/subvol=root,compress/subvol=root,noatime,compress/' /etc/fstab

sudo sed -i 's/subvol=home,compress/subvol=home,noatime,compress/' /etc/fstab

cat /etc/fstab | grep btrfs
```

### Zram

> Needs reboot.

```sh
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
EOF

cat /sys/block/zram0/comp_algorithm
```

### Sysctl VM tunelling

```sh
sudo tee /etc/sysctl.d/99-performance.conf > /dev/null << 'EOF'
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
EOF

sudo sysctl -p /etc/sysctl.d/99-performance.conf
```

### I do not use those services:

```sh
sudo systemctl disable --now ModemManager.service

sudo systemctl disable --now avahi-daemon.service
sudo systemctl disable --now avahi-daemon.socket

sudo systemctl disable docker.service
sudo systemctl enable docker.socket

systemctl is-enabled ModemManager avahi-daemon docker.service docker.socket
# disabled disabled disabled enabled
```

### Journald

```sh
 sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/size.conf > /dev/null << 'EOF'
[Journal]
SystemMaxUse=256M
EOF

sudo journalctl --vacuum-size=256M
sudo systemctl restart systemd-journald
```

### Readahead (for my SSD)

```sh
sudo tee /etc/udev/rules.d/60-readahead.rules > /dev/null << 'EOF'
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0",
ATTR{queue/read_ahead_kb}="256"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger
echo 256 | sudo tee /sys/block/sdb/queue/read_ahead_kb
```

### IO Scheduler

```sh
sudo tee /etc/udev/rules.d/60-iosched.rules > /dev/null << 'EOF'
# SSD
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0",
ATTR{queue/scheduler}="mq-deadline"
# HDD
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1",
ATTR{queue/scheduler}="bfq"
# NVMe
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger
echo mq-deadline | sudo tee /sys/block/sdb/queue/scheduler
```

### Flatpak GPU acceleration

```sh
flatpak override --user --env=MESA_LOADER_DRIVER_OVERRIDE=radeonsi
flatpak override --user --env=LIBVA_DRIVER_NAME=radeonsi

cat ~/.local/share/flatpak/overrides/global
```

### System clearing

> I use only Fedora

```sh
sudo dnf remove --oldinstallonly --setopt installonly_limit=2 -y

sudo dnf clean all

flatpak uninstall --unused -y

sudo coredumpctl list 2>/dev/null && sudo find /var/lib/systemd/coredump -type f -mtime +7 -delete 2>/dev/null

rm -rf ~/.cache/thumbnails/*
```

#### Reboot verification

```sh
echo "--- MOUNT ---"
findmnt / -o OPTIONS | tr ',' '\n' | grep -E 'noatime|relatime'

echo "--- ZRAM ---"
cat /sys/block/zram0/comp_algorithm

echo "--- SYSCTL ---"
sysctl vm.vfs_cache_pressure vm.dirty_ratio vm.dirty_background_ratio

echo "--- SERVICES ---"
systemctl is-enabled ModemManager avahi-daemon docker.service docker.socket

echo "--- JOURNAL ---"
journalctl --disk-usage

echo "--- READAHEAD ---"
cat /sys/block/sdb/queue/read_ahead_kb

echo "--- IO SCHED ---"
cat /sys/block/sdb/queue/scheduler

echo "--- BOOT TIME ---"
systemd-analyze
```
