#!/bin/bash
# Toggles a modal of modal.h, pipewire-mixer or audio-switcher, which keeps
# running hidden in between; started anew, built, when its source changed.
# With --hidden, as sway gives at its start, only starts it.
# Builtins alone when it runs, as pkill would take longer than showing it
name=$1
dir=~/.config/sway/scripts
bin=$dir/$name
pidfile=${XDG_RUNTIME_DIR:-/tmp}/$name.pid

case $name in
pipewire-mixer | audio-switcher) libs="gtk+-3.0 json-c" ;;
*) exit 1 ;;
esac

pid=
read -r pid 2>/dev/null <"$pidfile" &&
    read -r comm 2>/dev/null <"/proc/$pid/comm" &&
    [ "$comm" = "$name" ] || pid=

if [ ! -x "$bin" ] || [ "$dir/$name.c" -nt "$bin" ] ||
    [ "$dir/modal.h" -nt "$bin" ] || [ "$dir/pactl.h" -nt "$bin" ]; then
    cc -O2 -Wall -Wextra -Wno-unused-parameter -o "$bin" "$dir/$name.c" \
        $(pkg-config --cflags --libs $libs) || exit 1
    [ -n "$pid" ] && kill "$pid"
    pid=
fi

if [ -n "$pid" ]; then
    [ "$2" = --hidden ] || kill -USR1 "$pid"
    exit 0
fi
exec "$bin" $2
