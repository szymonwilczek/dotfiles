#!/bin/bash
# Toggles a modal of modal.h, pipewire-mixer or audio-switcher, which keeps
# running hidden in between; built by make and started anew when its source
# changed.
# With --hidden, as sway gives at its start, only starts it. Builtins alone
# when it runs, as pkill would take longer than showing it
name=$1
dir=~/.config/sway/scripts
bin=$dir/$name
pidfile=${XDG_RUNTIME_DIR:-/tmp}/$name.pid

case $name in
pipewire-mixer | audio-switcher) ;;
*) exit 1 ;;
esac

pid=
read -r pid 2>/dev/null <"$pidfile" &&
    read -r comm 2>/dev/null <"/proc/$pid/comm" &&
    [ "$comm" = "$name" ] || pid=

make -s -C "$dir" RESTART= "$name" || exit 1

# Built since it started, as it leaves its pid then
if [ -n "$pid" ] && [ "$bin" -nt "$pidfile" ]; then
    kill "$pid"
    pid=
fi

if [ -n "$pid" ]; then
    [ "$2" = --hidden ] || kill -USR1 "$pid"
    exit 0
fi
exec "$bin" $2
