#!/bin/bash
# (Re)starts autotiling, built by make
dir=~/.config/sway/scripts
bin=$dir/autotiling

pkill -x autotiling

make -s -C "$dir" RESTART= autotiling || exit 1

exec "$bin"
