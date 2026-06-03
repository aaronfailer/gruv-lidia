#!/bin/bash
# Clipboard persist + history for Wayland
# Keeps clipboard alive after source app closes
# Prevents infinite loop via dedup file

wl-paste --type text --watch sh -c '
  c=$(cat)
  last=$(cat /tmp/.qs_clip_last 2>/dev/null)
  if [ "$c" != "$last" ] && [ -n "$c" ]; then
    echo "$c" > /tmp/.qs_clip_last
    echo "$c" | cliphist store 2>/dev/null
    echo "$c" | wl-copy 2>/dev/null
  fi
'
