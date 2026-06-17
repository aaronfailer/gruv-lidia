#!/bin/bash
STATE_FILE="/tmp/hypr-toggle-state"

if [ -f "$STATE_FILE" ]; then
  saved_addr=$(cat "$STATE_FILE")
  exists=$(hyprctl clients -j | jq -r --arg a "$saved_addr" \
    '.[] | select(.address == $a) | .address')
  if [ -n "$exists" ]; then
    cws=$(hyprctl monitors -j | jq -r '.[0].activeWorkspace.id')
    hyprctl dispatch movetoworkspacesilent "$cws,address:$saved_addr"
    hyprctl dispatch focuswindow "address:$saved_addr"
  fi
  rm -f "$STATE_FILE"
  exit 0
fi

active=$(hyprctl activewindow -j)
addr=$(echo "$active" | jq -r '.address // ""')
ws=$(echo "$active" | jq -r '.workspace.id // -1')

[ -z "$addr" ] || [ "$ws" = "99" ] && exit 0

echo "$addr" > "$STATE_FILE"
hyprctl dispatch movetoworkspacesilent "99,address:$addr"
