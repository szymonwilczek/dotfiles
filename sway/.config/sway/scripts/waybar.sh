#!/bin/bash
# Starts waybar, with what it runs of sway/scripts built by make; a module
# that fails to build or load leaves the rest of the bar working
dir=~/.config/sway/scripts
make -s -k -C "$dir" RESTART= waybar-clock.so calendar spotify-island

# module_path of cffi/clock is relative to it
cd ~ || exit 1
LC_ALL=pl_PL.UTF-8 exec waybar
