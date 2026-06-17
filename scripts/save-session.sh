#!/bin/bash
# save-session.sh — Guarda estado de la sesion Hyprland
# Detecta: nativas, flatpaks, wine, appimage, steam, tmux
LOG="$HOME/.cache/session-save.log"
TMP_CLIENTS=$(mktemp)
hyprctl clients -j 2>/dev/null > "$TMP_CLIENTS"

echo "[$(date +%H:%M:%S)] save-session: inicio" > "$LOG"
hyprctl clients -j 2>/dev/null | python3 -c "import json,sys; print(f'  Ventanas detectadas: {len(json.load(sys.stdin))}')" >> "$LOG"

python3 - "$TMP_CLIENTS" "$LOG" << 'PYEOF'
import json, sys, os, subprocess, shlex, time

clients_file = sys.argv[1]
log_file = sys.argv[2]

def log(msg):
    with open(log_file, "a") as f:
        f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\n")

with open(clients_file) as f:
    clients = json.load(f)

log(f"Procesando {len(clients)} ventanas")

# ── helpers ──────────────────────────────────────────────

def _env_var(pid, name):
    try:
        with open(f"/proc/{pid}/environ", "rb") as f:
            for entry in f.read().split(b"\0"):
                if entry.startswith(name.encode() + b"="):
                    return entry.split(b"=", 1)[1].decode("utf-8", errors="replace")
    except Exception:
        return None

def _cmdline_list(pid):
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            raw = f.read()
        return [p.decode("utf-8", errors="replace") for p in raw.split(b"\0") if p]
    except Exception:
        return None

# ── tmux session detection ───────────────────────────────

def find_tmux_sessions(terminal_pids):
    """Return (mapping, orphaned) mapping: pid->session_name, orphaned: [session_names]"""
    mapping = {}
    orphaned = []

    # Method 1: attached clients matched to terminal PIDs
    try:
        fp_out = subprocess.run(
            ["tmux", "list-clients", "-F", "#{client_pid} #{session_name}"],
            capture_output=True, text=True, timeout=5
        ).stdout
        for line in fp_out.strip().split('\n'):
            parts = line.split()
            if len(parts) >= 2 and parts[0].isdigit():
                client_pid = int(parts[0])
                session_name = parts[1]
                p = client_pid
                while p > 1:
                    if p in terminal_pids:
                        mapping[p] = session_name
                        break
                    try:
                        with open(f"/proc/{p}/status") as f:
                            for l in f:
                                if l.startswith("PPid:"):
                                    p = int(l.split()[1], 10)
                                    break
                    except Exception:
                        break
    except Exception as e:
        log(f"  tmux list-clients fallo: {e}")

    # Method 2: orphaned sessions (no client attached)
    try:
        fp_out = subprocess.run(
            ["tmux", "list-sessions", "-F", "#{session_name}"],
            capture_output=True, text=True, timeout=5
        ).stdout
        for line in fp_out.strip().split('\n'):
            sn = line.strip()
            if sn and sn not in mapping.values():
                orphaned.append(sn)
    except Exception as e:
        log(f"  tmux list-sessions fallo: {e}")

    return mapping, orphaned

# ── Flatpak detection (fixed) ────────────────────────────

# Mapeo de clases conocidas a app IDs de flatpak
FLATPAK_CLASS_MAP = {
    "opera": "com.opera.opera-gx",
    "opera gx": "com.opera.opera-gx",
    "discord": "com.discordapp.Discord",
    "slack": "com.slack.Slack",
    "spotify": "com.spotify.Client",
    "telegram": "org.telegram.desktop",
    "whatsapp": "io.github.mimbrero.WhatsAppDesktop",
    "obsidian": "md.obsidian.Obsidian",
    "onlyoffice": "org.onlyoffice.desktopeditors",
    "libreoffice": "org.libreoffice.LibreOffice",
    "gimp": "org.gimp.GIMP",
    "inkscape": "org.inkscape.Inkscape",
    "firefox": "org.mozilla.firefox",
    "thunderbird": "org.mozilla.Thunderbird",
}

def detect_flatpak(pid, exe, cls, cmdline_parts):
    # Method 1: FLATPAK_ID env var
    app_id = _env_var(pid, "FLATPAK_ID")
    if app_id:
        cmdline = f"flatpak run {app_id}"
        if cmdline_parts and len(cmdline_parts) > 1:
            args = cmdline_parts[1:]
            cmdline += " " + " ".join(shlex.quote(a) for a in args)
        return {"exe": "flatpak", "cmdline": cmdline}

    # Method 2: match by exe path
    if exe and ("/app/" in exe or "/var/lib/flatpak/" in exe):
        try:
            fp_out = subprocess.run(
                ["flatpak", "ps", "--columns=pid,application"],
                capture_output=True, text=True, timeout=5
            ).stdout
            for line in fp_out.strip().split('\n'):
                parts = line.split()
                if len(parts) >= 2 and parts[0].isdigit():
                    fp_pid = int(parts[0])
                    try:
                        fp_exe = os.readlink(f"/proc/{fp_pid}/exe")
                        if fp_exe == exe:
                            return {"exe": "flatpak", "cmdline": f"flatpak run {parts[1]}"}
                    except Exception:
                        pass
        except Exception:
            pass

        # Method 3: fallback by class name mapping
        cls_lower = cls.lower().strip()
        if cls_lower in FLATPAK_CLASS_MAP:
            app_id = FLATPAK_CLASS_MAP[cls_lower]
            return {"exe": "flatpak", "cmdline": f"flatpak run {app_id}"}

        # Method 4: fallback by exe path fragment
        app_id = None
        if exe and "/app/" in exe:
            exe_parts = exe.split("/")
            if len(exe_parts) >= 4 and exe_parts[-3] == "app":
                app_short = exe_parts[-2]
                try:
                    fp_out = subprocess.run(
                        ["flatpak", "list", "--columns=application"],
                        capture_output=True, text=True, timeout=5
                    ).stdout
                    for line in fp_out.strip().split('\n'):
                        known = line.strip()
                        if app_short and app_short in known.lower():
                            app_id = known
                            break
                except Exception:
                    pass

        if not app_id:
            app_id = FLATPAK_CLASS_MAP.get(cls_lower, cls_lower.replace(" ", "-"))
        return {"exe": "flatpak", "cmdline": f"flatpak run {app_id}"}

    return None

# ── Wine detection ───────────────────────────────────────

def detect_wine(pid, exe, cls, cmdline_parts):
    exe_lower = (exe or "").lower()

    if exe and exe.lower().endswith(".exe"):
        wp = _env_var(pid, "WINEPREFIX")
        cmd = f"wine {shlex.quote(exe)}"
        if wp:
            return {"exe": "wine", "cmdline": f"WINEPREFIX={shlex.quote(wp)} {cmd}", "use_shell": True}
        return {"exe": "wine", "cmdline": cmd, "use_shell": True}

    if any(x in exe_lower for x in ["/wine", "wine64", "wine-preloader"]):
        exe_path = None
        ppid = None
        if cmdline_parts:
            for p in cmdline_parts:
                if ".exe" in p.lower():
                    exe_path = p
                    break
        if not exe_path:
            try:
                with open(f"/proc/{pid}/status") as f:
                    for line in f:
                        if line.startswith("PPid:"):
                            ppid = int(line.split()[1], 10)
                            break
                if ppid:
                    parent = _cmdline_list(ppid)
                    if parent:
                        for p in parent:
                            if ".exe" in p.lower():
                                exe_path = p
                                break
            except Exception:
                pass
        if exe_path:
            wp = _env_var(pid, "WINEPREFIX") or (_env_var(ppid, "WINEPREFIX") if ppid else None)
            cmd = f"wine {shlex.quote(exe_path)}"
            if wp:
                return {"exe": "wine", "cmdline": f"WINEPREFIX={shlex.quote(wp)} {cmd}", "use_shell": True}
            return {"exe": "wine", "cmdline": cmd, "use_shell": True}

    if cmdline_parts:
        for p in cmdline_parts:
            if ".exe" in p.lower():
                wp = _env_var(pid, "WINEPREFIX")
                cmd = f"wine {shlex.quote(p)}"
                if wp:
                    return {"exe": "wine", "cmdline": f"WINEPREFIX={shlex.quote(wp)} {cmd}", "use_shell": True}
                return {"exe": "wine", "cmdline": cmd, "use_shell": True}

    return None

# ── AppImage detection ───────────────────────────────────

def detect_appimage(pid, exe, cls, cmdline_parts):
    if not (exe and exe.startswith("/tmp/.mount_")):
        return None
    try:
        with open(f"/proc/{pid}/mountinfo") as f:
            for line in f:
                line = line.strip()
                if "-" in line and ".AppImage" in line:
                    parts = line.split()
                    idx = parts.index("-")
                    if idx + 2 < len(parts):
                        src = parts[idx + 2]
                        if src.endswith(".AppImage"):
                            return {"exe": src, "cmdline": src}
    except Exception:
        pass
    try:
        with open(f"/proc/{pid}/mounts") as f:
            for line in f:
                src = line.split()[0]
                if src.endswith(".AppImage"):
                    return {"exe": src, "cmdline": src}
    except Exception:
        pass
    return None

# ── Steam detection ──────────────────────────────────────

def detect_steam(pid, exe, cls, cmdline_parts):
    if cls and "steam" in cls.lower():
        return {"exe": "steam", "cmdline": "steam"}
    return None

# ── main processing ──────────────────────────────────────

all_pids = {c["pid"] for c in clients if c.get("pid", 0) > 0}
tmux_mapping, orphaned_tmux = find_tmux_sessions(all_pids)

if tmux_mapping:
    log(f"  tmux attached: {tmux_mapping}")
if orphaned_tmux:
    log(f"  tmux orphaned: {orphaned_tmux}")

save = []
seen_cmdlines = set()

for c in clients:
    wid = c.get("workspace", {}).get("id", -1)
    if wid <= 0 or wid == 99:
        log(f"  skip ws={wid} class={c.get('class','?')}")
        continue

    cls = c.get("class", "")
    title = c.get("title", "")
    pid = c.get("pid", 0)
    addr = c.get("address", "")

    if cls == "quickshell" or not cls:
        continue

    entry = {
        "class": cls, "title": title, "workspace": wid,
        "x": c.get("at", [0, 0])[0], "y": c.get("at", [0, 0])[1],
        "w": c.get("size", [0, 0])[0], "h": c.get("size", [0, 0])[1],
        "address": addr,
    }

    handler = None
    if pid and pid > 0:
        exe = None
        cmdline_parts = None
        try:
            exe = os.readlink(f"/proc/{pid}/exe")
        except Exception:
            pass
        cmdline_parts = _cmdline_list(pid)

        # handler chain
        handler = detect_flatpak(pid, exe, cls, cmdline_parts)
        if not handler:
            handler = detect_wine(pid, exe, cls, cmdline_parts)
        if not handler:
            handler = detect_appimage(pid, exe, cls, cmdline_parts)
        if not handler:
            handler = detect_steam(pid, exe, cls, cmdline_parts)

        if handler:
            entry["exe"] = handler["exe"]
            entry["cmdline"] = handler["cmdline"]
            if handler.get("use_shell"):
                entry["use_shell"] = True
            log(f"  {cls}: handler={handler['exe']}")
        else:
            # Generic fallback
            if exe and not any(x in exe.lower() for x in ["quickshell", "hyprpaper"]):
                entry["exe"] = exe
            if cmdline_parts:
                cmdline = " ".join(shlex.quote(p) for p in cmdline_parts)
                if cmdline:
                    entry["cmdline"] = cmdline
            log(f"  {cls}: fallback generic exe={exe}")

    # Tmux session detection
    if pid in tmux_mapping:
        entry["tmux_session"] = tmux_mapping[pid]
        log(f"  {cls}: tmux_session={tmux_mapping[pid]}")
    elif "kitty" in cls.lower() and orphaned_tmux:
        # No attached client but orphaned sessions exist
        entry["tmux_session"] = orphaned_tmux[0]
        entry["tmux_orphaned"] = orphaned_tmux
        log(f"  {cls}: tmux_orphaned={orphaned_tmux[0]}")

    if entry.get("cmdline"):
        # Dedup: skip same app on same workspace
        dedup_key = (entry["cmdline"], wid)
        if dedup_key not in seen_cmdlines:
            seen_cmdlines.add(dedup_key)
            save.append(entry)
        else:
            log(f"  {cls}: skip duplicado en ws{wid}")
    else:
        log(f"  {cls}: omitido (sin cmdline)")

os.makedirs(os.path.expanduser("~/.cache"), exist_ok=True)
with open(os.path.expanduser("~/.cache/hyprland-session.json"), "w") as f:
    json.dump(save, f, indent=2)
log(f"Guardadas {len(save)} ventanas en hyprland-session.json")

# App history (keep last 200 lines)
history_file = os.path.expanduser("~/.config/quickshell/app_history.log")
os.makedirs(os.path.dirname(history_file), exist_ok=True)
with open(history_file, "a") as f:
    for app in save:
        name = app.get("class", "")
        icon = name.lower().replace(".exe", "").replace(" ", "-") or "application-x-executable"
        exec_ = app.get("cmdline", name)
        if name:
            f.write(f"{name}|{icon}|{exec_}\n")
try:
    with open(history_file) as f:
        lines = f.readlines()
    if len(lines) > 200:
        with open(history_file, "w") as f:
            f.writelines(lines[-200:])
except Exception:
    pass

PYEOF
rm -f "$TMP_CLIENTS"
