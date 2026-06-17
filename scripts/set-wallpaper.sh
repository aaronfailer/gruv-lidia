#!/bin/bash

IMG="$1"

if ! pgrep -x hyprpaper >/dev/null 2>&1; then
    hyprpaper &
    sleep 0.5
fi

hyprctl hyprpaper wallpaper "DP-1,$IMG"

cat > "$HOME/.config/hypr/hyprpaper.conf" <<EOF
wallpaper {
    monitor =
    path = $IMG
    fit_mode = cover
}
EOF
