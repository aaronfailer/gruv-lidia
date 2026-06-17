#!/bin/bash
# art-bridge.sh: resolve a MPRIS trackArtUrl to a host-accessible path
# Usage: art-bridge.sh <dbus-name> <track-art-url>
# Outputs the resolved file:// URL to stdout.

dbus_name="$1"
track_art_url="$2"

if [ -z "$track_art_url" ]; then
    echo ""
    exit 0
fi

# Non-file URLs (https:// etc.) pass through
if ! echo "$track_art_url" | grep -q "^file://"; then
    echo "$track_art_url"
    exit 0
fi

sandbox_path="${track_art_url#file://}"

# If file exists on host, use directly
if [ -f "$sandbox_path" ]; then
    echo "$track_art_url"
    exit 0
fi

# File is inside a sandbox (flatpak) — get PID via D-Bus
if [ -n "$dbus_name" ]; then
    pid=$(dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply \
        /org/freedesktop/DBus \
        org.freedesktop.DBus.GetConnectionUnixProcessID \
        string:"$dbus_name" 2>/dev/null | grep uint32 | awk '{print $2}')

    if [ -n "$pid" ]; then
        proc_path="/proc/$pid/root/$sandbox_path"

        if [ -f "$proc_path" ]; then
            hash=$(echo "$track_art_url" | md5sum | head -c 8)
            dest="/tmp/quickshell-art-$hash"
            cp "$proc_path" "$dest" 2>/dev/null
            if [ -f "$dest" ]; then
                echo "file://$dest"
                exit 0
            fi
        fi
    fi
fi

# Fallback: try flatpak-run for known apps
known_apps="com.opera.opera-gx org.mozilla.firefox"
for app in $known_apps; do
    result=$(flatpak run --command=sh "$app" -c "cat '$sandbox_path' 2>/dev/null | base64" 2>/dev/null)
    if [ -n "$result" ]; then
        hash=$(echo "$track_art_url" | md5sum | head -c 8)
        dest="/tmp/quickshell-art-$hash"
        echo "$result" | base64 -d > "$dest"
        if [ -f "$dest" ] && [ -s "$dest" ]; then
            echo "file://$dest"
            exit 0
        fi
    fi
done

echo ""
exit 1
