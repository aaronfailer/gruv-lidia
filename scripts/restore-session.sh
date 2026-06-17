#!/bin/bash
# restore-session.sh — Restaura el estado de la sesion Hyprland
STATE_FILE="$HOME/.cache/hyprland-session.json"
LOG="$HOME/.cache/session-restore.log"

FLAG="/tmp/hyprland-session-restore-flag"

if [ ! -f "$FLAG" ]; then
    echo "[$(date +%H:%M:%S)] restore: sin flag (cold boot o apagado), no se restaura" > "$LOG"
    rm -f "$STATE_FILE"
    exit 0
fi

rm -f "$FLAG"

if [ ! -s "$STATE_FILE" ]; then
    echo "[$(date +%H:%M:%S)] restore: no hay sesion guardada" > "$LOG"
    exit 0
fi

echo "[$(date +%H:%M:%S)] restore: inicio" > "$LOG"

python3 - "$STATE_FILE" "$LOG" << 'PYEOF'
import json, subprocess, time, os, sys, shlex, re

state_file = sys.argv[1]
log_file = sys.argv[2]

def log(msg):
    with open(log_file, "a") as f:
        f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\n")

try:
    with open(state_file) as f:
        windows = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    log("  archivo no encontrado o invalido")
    sys.exit(0)

if not windows:
    log("  sesion vacia")
    sys.exit(0)

log(f"Restaurando {len(windows)} ventanas")

# Strip Desktop Entry placeholders: %U, %u, %f, %F, %i, %c, %k
PLACEHOLDER_RE = re.compile(r'%[UufFick]')

def clean_cmdline(cmd):
    if not cmd:
        return cmd
    return PLACEHOLDER_RE.sub('', cmd).strip()

def move_to_workspace(addr, ws):
    """Mueve la ventana a su workspace."""
    try:
        subprocess.run(
            ["hyprctl", "dispatch", "movetoworkspace", str(ws), f"address:{addr}"],
            capture_output=True, timeout=2
        )
    except Exception:
        pass

def set_window_geometry(addr, x, y, w, h):
    """Ajusta posicion y tamano de la ventana."""
    try:
        # Mover primero
        subprocess.run(
            ["hyprctl", "dispatch", "movewindowpixel", f"exact {x} {y}", f"address:{addr}"],
            capture_output=True, timeout=2
        )
        time.sleep(0.1)
        # Redimensionar
        subprocess.run(
            ["hyprctl", "dispatch", "resizewindowpixel", f"exact {w} {h}", f"address:{addr}"],
            capture_output=True, timeout=2
        )
    except Exception:
        pass

def is_flatpak(cmdline):
    return cmdline and cmdline.strip().startswith("flatpak run")

by_ws = {}
for w in windows:
    ws = w["workspace"]
    if ws == 99:
        log(f"  skip ws=99 (minimized): {w.get('class','?')}")
        continue
    by_ws.setdefault(ws, []).append(w)

log(f"Workspaces: {sorted(by_ws.keys())}")

total = 0
for ws in sorted(by_ws.keys()):
    # Cambiar al workspace
    subprocess.run(["hyprctl", "dispatch", "workspace", str(ws)], capture_output=True)
    time.sleep(0.4)

    for w in by_ws[ws]:
        cls = w.get("class", "")
        cmdline = w.get("cmdline")
        exe = w.get("exe")
        tmux_session = w.get("tmux_session")
        addr = w.get("address", "")

        log(f"  [{ws}] {cls}: cmdline={cmdline}")

        # ── Tmux session ──
        if tmux_session and exe and "kitty" in exe.lower():
            launch = [exe, "-e", "tmux", "new-session", "-A", "-s", tmux_session]
            log(f"    → kitty + tmux: {tmux_session}")

        # ── Flatpak ──
        elif is_flatpak(cmdline):
            cmdline = clean_cmdline(cmdline)
            launch = cmdline
            log(f"    → flatpak (shell=True)")

        # ── Cmdline normal ──
        elif cmdline:
            cmdline = clean_cmdline(cmdline)
            if w.get("use_shell") or "WINEPREFIX" in cmdline:
                launch = cmdline
                log(f"    → shell: {cmdline[:80]}")
            else:
                try:
                    launch = shlex.split(cmdline)
                    log(f"    → exec: {launch[0]}")
                except Exception as e:
                    log(f"    → shlex.split fallo: {e}, fallback shell")
                    launch = cmdline

        elif exe:
            launch = [exe]
            log(f"    → exe: {exe}")
        elif cls:
            launch = [cls.lower()]
            log(f"    → cls: {cls.lower()}")
        else:
            log(f"    → saltar (sin cmdline/exe/cls)")
            continue

        # ── Lanzar ──
        proc = None
        try:
            if isinstance(launch, str):
                proc = subprocess.Popen(launch, shell=True, start_new_session=True)
            else:
                proc = subprocess.Popen(launch, start_new_session=True)

            # Esperar a que la ventana aparezca
            time.sleep(1.5)

            # Buscar la nueva ventana y moverla al workspace + posicion
            if proc and proc.pid:
                for attempt in range(10):
                    try:
                        clients = json.loads(
                            subprocess.run(
                                ["hyprctl", "clients", "-j"],
                                capture_output=True, text=True, timeout=3
                            ).stdout or "[]"
                        )
                        # Buscar por PID o por clase
                        for c in clients:
                            c_addr = c.get("address", "")
                            c_pid = c.get("pid", 0)
                            c_cls = c.get("class", "")
                            if c_pid == proc.pid or c_cls == cls:
                                if ws != 1:  # no mover si ya esta en ws 1
                                    move_to_workspace(c_addr, ws)
                                    time.sleep(0.1)
                                set_window_geometry(
                                    c_addr,
                                    w.get("x", 0), w.get("y", 0),
                                    max(w.get("w", 800), 100), max(w.get("h", 600), 100)
                                )
                                log(f"    → posicionado en ws{ws}")
                                break
                        break
                    except Exception:
                        time.sleep(0.5)

            total += 1

        except Exception as e:
            log(f"    → ERROR: {e}")
            continue

# Volver al workspace 1
subprocess.run(["hyprctl", "dispatch", "workspace", "1"], capture_output=True)
log(f"Restauradas {total}/{len(windows)} ventanas")
PYEOF
