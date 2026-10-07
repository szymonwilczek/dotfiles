#!/bin/sh
# Lists the windows of every output, left to right, the scratchpad
# last, in fuzzel and focuses the picked one, switching to its
# workspace and output.  The focused window is left out.

id=$(swaymsg -t get_tree | jq -r '
  def pad(n): . + ([range(length; n)] | map(" ") | join(""));
  .nodes | sort_by(.name == "__i3", .rect.x) | .[].nodes[] |
  (if .name == "__i3_scratch" then "scratchpad" else .name end) as $ws |
  (.nodes, .floating_nodes) | .. | objects |
  select(.pid and (.focused | not)) |
  [.id, ($ws | pad(13)),
   (.app_id // .window_properties.class // "?" | split(".") | last | pad(10)),
   .name] | @tsv' |
    fuzzel --dmenu --with-nth '{2} {3} {4}' --accept-nth 1 --width 70 \
        --mesg "Okna") || exit
[ -n "$id" ] && swaymsg -q "[con_id=$id] focus"
