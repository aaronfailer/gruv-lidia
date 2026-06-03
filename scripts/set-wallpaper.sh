#!/bin/bash

IMG="$1"

hyprctl hyprpaper wallpaper "DP-1,$IMG"

cat > "$HOME/.config/hypr/hyprpaper.conf" <<EOF
wallpaper {
    monitor =
    path = $IMG
    fit_mode = cover
}
EOF
