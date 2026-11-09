#!/bin/bash
# Toggles a modal of modal.h, pipewire-mixer, audio-switcher, powermenu
# or wallpaper, which keeps running hidden in between;
# built by make and started anew when its source changed.
# With --hidden, as sway gives at its start, only starts it. Builtins alone
# when it runs, as pkill would take longer than showing it
name=$1
scripts_dir=~/.config/sway/scripts
src_dir=$scripts_dir/src
bin=$scripts_dir/bin/$name
pidfile=${XDG_RUNTIME_DIR:-/tmp}/$name.pid

case $name in
pipewire-mixer | audio-switcher | powermenu | wallpaper | calculator | net-info) ;;
*) exit 1 ;;
esac

pid=
read -r pid 2>/dev/null <"$pidfile" &&
    read -r comm 2>/dev/null <"/proc/$pid/comm" &&
    [ "$comm" = "$name" ] || pid=

# make only when a source is newer, as it takes longer than all the rest
for src in "$src_dir/$name.c" "$src_dir/modal.h" "$src_dir/pactl.h"; do
    if [ "$src" -nt "$bin" ]; then
        make -s -C "$src_dir" RESTART= "$name" || exit 1
        break
    fi
done

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
