#!/bin/bash
dir=~/.config/sway/scripts
bin=$dir/night-light
protocol=$dir/wlr-gamma-control-unstable-v1.xml

if pkill -x night-light; then
    swayosd-client --custom-icon night-light-disabled-symbolic \
        --custom-message "Night light off"
    exit 0
fi

if [ ! -x "$bin" ] || [ "$dir/night-light.c" -nt "$bin" ]; then
    build=$(mktemp -d)
    trap 'rm -rf "$build"' EXIT
    wayland-scanner client-header "$protocol" \
        "$build/wlr-gamma-control-unstable-v1-client-protocol.h" &&
        wayland-scanner private-code "$protocol" "$build/protocol.c" &&
        cc -O2 -Wall -I"$build" -o "$bin" "$dir/night-light.c" \
            "$build/protocol.c" -lwayland-client -lm || exit 1
fi

"$bin" &
swayosd-client --custom-icon night-light-symbolic \
    --custom-message "Night light $("$bin" -p)K"
