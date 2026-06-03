#!/bin/bash

IGNORE="sh|bash|python|python3|chromium|chrome|electron|xdg|dbus|at-spi|portal"

{
find /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications ~/.local/share/flatpak/exports/share/applications -name "*.desktop" 2>/dev/null | while read f; do
    grep -q "^NoDisplay=true" "$f" && continue
    grep -q "^Type=Application" "$f" || continue

    name=$(grep "^Name=" "$f" | head -1 | cut -d= -f2)
    icon=$(grep "^Icon=" "$f" | head -1 | cut -d= -f2)
    exec=$(grep "^Exec=" "$f" | head -1 | cut -d= -f2 | sed 's/ %[uUfFdDnNickvm]//g' | awk '{print $1}' | xargs basename 2>/dev/null)

    [ -z "$exec" ] && continue
    [ -z "$name" ] && continue

    echo "$exec" | grep -qE "^($IGNORE)$" && continue

    pgrep -x "$exec" > /dev/null 2>&1 || continue

    has_window=$(hyprctl clients -j 2>/dev/null | python3 -c "
import sys,json
clients = json.load(sys.stdin)
exec_name = '$exec'.lower()
for c in clients:
    if not c['mapped']:
        continue
    cls = c['class'].lower()
    icls = c['initialClass'].lower()
    if exec_name in cls or exec_name in icls or cls in exec_name or icls in exec_name:
        print('yes')
        sys.exit(0)
print('no')
" 2>/dev/null)

    [ "$has_window" = "yes" ] && continue

    echo "$name|$icon|$exec"
done | sort -t'|' -k3,3 -u
} > /tmp/qs_tray_procs.txt
