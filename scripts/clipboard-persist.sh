#!/bin/bash
# Clipboard persistence + history para Wayland y XWayland

# ── Persistencia Wayland ──────────────────────────────────────
wl-clip-persist --clipboard regular &>/dev/null &

# ── Historial (Wayland) ───────────────────────────────────────
wl-paste --type text --watch cliphist store &>/dev/null &
wl-paste --type image --watch cliphist store &>/dev/null &

wait
