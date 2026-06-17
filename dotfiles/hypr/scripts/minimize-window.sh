#!/bin/bash
addr=$(hyprctl activewindow -j | jq -r '.address')
hyprctl dispatch movetoworkspacesilent "99,address:$addr"
