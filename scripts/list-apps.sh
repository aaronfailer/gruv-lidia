#!/bin/bash

DESKTOP_DIRS=(
    /usr/share/applications
    "$HOME/.local/share/applications"
    /var/lib/flatpak/exports/share/applications
    "$HOME/.local/share/flatpak/exports/share/applications"
)

{
find "${DESKTOP_DIRS[@]}" -name "*.desktop" 2>/dev/null | while read f; do
    grep -q "^NoDisplay=true" "$f" 2>/dev/null && continue
    grep -q "^Type=Application" "$f" 2>/dev/null || continue
    name=$(grep "^Name=" "$f" | head -1 | cut -d= -f2)
    icon=$(grep "^Icon=" "$f" | head -1 | cut -d= -f2)
    exec=$(grep "^Exec=" "$f" | head -1 | cut -d= -f2 | sed 's/ %[uUfFdDnNickvm]//g; s/%[uUfFdDnNickvm]//g')
    [ -z "$name" ] && continue
    [ -z "$icon" ] && icon="application-x-executable"
    [ -z "$exec" ] && continue
    echo "$name|$icon|$exec"
done | sort -t'|' -k1,1 -u
} > /tmp/qs_all_apps.txt
