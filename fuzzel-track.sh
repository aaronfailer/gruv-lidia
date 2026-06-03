#!/bin/bash

DESKTOP_DIRS=(
    /usr/share/applications
    "$HOME/.local/share/applications"
    /var/lib/flatpak/exports/share/applications
    "$HOME/.local/share/flatpak/exports/share/applications"
)

MENU_ITEMS=$(
    find "${DESKTOP_DIRS[@]}" -name "*.desktop" 2>/dev/null | while read f; do
        grep -q "^NoDisplay=true" "$f" 2>/dev/null && continue
        grep -q "^Type=Application" "$f" 2>/dev/null || continue
        name=$(grep "^Name=" "$f" | head -1 | cut -d= -f2)
        [ -z "$name" ] && continue
        echo "$name"
    done | sort -u
)

OUTPUT_FILE=$(mktemp /tmp/qs_fuzzel_sel.XXXXXX)

echo "$MENU_ITEMS" | fuzzel --dmenu --placeholder="Buscar aplicaciones..." > "$OUTPUT_FILE" 2>/dev/null &
FUZZEL_PID=$!

sleep 0.3

FUZZEL_ADDR=$(hyprctl clients -j 2>/dev/null | python3 -c "
import sys, json
for c in json.load(sys.stdin):
    if c.get('pid') == $FUZZEL_PID:
        print(c.get('address', ''))
" 2>/dev/null)

IDLE=0
while kill -0 "$FUZZEL_PID" 2>/dev/null; do
    ACTIVE_ADDR=$(hyprctl activewindow -j 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('address', ''))
except:
    print('')
" 2>/dev/null)

    if [ -z "$FUZZEL_ADDR" ] || [ "$ACTIVE_ADDR" = "$FUZZEL_ADDR" ]; then
        IDLE=0
    else
        IDLE=$((IDLE + 1))
        if [ "$IDLE" -ge 20 ]; then
            kill "$FUZZEL_PID" 2>/dev/null
            break
        fi
    fi
    sleep 0.1
done

SELECTED=$(cat "$OUTPUT_FILE" 2>/dev/null)
rm -f "$OUTPUT_FILE"

if [ -n "$SELECTED" ]; then
    NAME="$SELECTED"

    for dir in "${DESKTOP_DIRS[@]}"; do
        DESKTOP=$(find "$dir" -name "*.desktop" 2>/dev/null | while read f; do
            grep -q "^Name=$NAME$" "$f" 2>/dev/null && echo "$f" && break
        done)
        [ -n "$DESKTOP" ] && break
    done

    if [ -n "$DESKTOP" ]; then
        ICON=$(grep "^Icon=" "$DESKTOP" | head -1 | cut -d= -f2)
        EXEC=$(grep "^Exec=" "$DESKTOP" | head -1 | cut -d= -f2 | sed 's/ %[uUfFdDnNickvm]//g; s/%[uUfFdDnNickvm]//g')

        echo "$NAME|$ICON|$EXEC" >> "$HOME/.config/quickshell/app_history.log"
        tail -200 "$HOME/.config/quickshell/app_history.log" > /tmp/qs_history_tmp && mv /tmp/qs_history_tmp "$HOME/.config/quickshell/app_history.log"

        gtk-launch "$(basename "$DESKTOP")" &
    fi
fi
