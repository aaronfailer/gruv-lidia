#!/bin/bash
# Clipboard persistence + history para Wayland y XWayland

# ── Persistencia Wayland ──────────────────────────────────────
wl-clip-persist --clipboard regular &>/dev/null &

# ── Historial (Wayland) ───────────────────────────────────────
wl-paste --type text --watch cliphist store &>/dev/null &
wl-paste --type image --watch cliphist store &>/dev/null &

# ── Persistencia X11 / XWayland ───────────────────────────────
(
  pid=""
  last_hash=""
  while true; do
    content=$(xclip -selection clipboard -o 2>/dev/null)
    if [ -n "$content" ]; then
      hash=$(echo -n "$content" | md5sum | cut -d' ' -f1)
      if [ "$hash" != "$last_hash" ]; then
        [ -n "$pid" ] && kill "$pid" 2>/dev/null
        echo -n "$content" | xclip -selection clipboard -i &>/dev/null &
        pid=$!
        last_hash="$hash"
      fi
    fi
    sleep 1
  done
) &

wait
