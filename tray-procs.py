#!/usr/bin/env python3
import json, os, re, subprocess
from pathlib import Path

BG_FILE = "/tmp/qs_tray_procs.txt"
FG_FILE = "/tmp/qs_tray_foreground.txt"
IGNORE = {"sh", "bash", "python", "python3", "chromium", "chrome", "electron",
          "xdg", "dbus", "at-spi", "portal"}
SEARCH_DIRS = [
    "/usr/share/applications",
    os.path.expanduser("~/.local/share/applications"),
    "/var/lib/flatpak/exports/share/applications",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
]

# 1. Get mapped window classes (once)
mapped_classes = set()
try:
    clients = json.loads(subprocess.check_output(
        ["hyprctl", "clients", "-j"], timeout=3))
    for c in clients:
        if c.get("mapped"):
            key = c["class"].lower().replace("-", "").replace(" ", "")
            mapped_classes.add(key)
except Exception:
    pass

# 2. Get running processes (from /proc — instant, no subprocess per app)
running_procs = set()
for p in Path("/proc").iterdir():
    if p.name.isdigit():
        try:
            comm = (p / "comm").read_text().strip().lower()
            running_procs.add(comm)
        except Exception:
            pass

# 3. Get flatpak running apps (once)
flatpak_running = set()
try:
    out = subprocess.check_output(
        ["flatpak", "ps", "--columns=application"], text=True, timeout=5)
    flatpak_running = {line.strip() for line in out.split("\n") if line.strip()}
except Exception:
    pass

background = []
foreground = []
seen_bg = set()
seen_fg = set()

# 4. Scan all .desktop files
for d in SEARCH_DIRS:
    if not os.path.isdir(d):
        continue
    try:
        entries = os.listdir(d)
    except Exception:
        continue
    for fname in entries:
        if not fname.endswith(".desktop"):
            continue
        fpath = os.path.join(d, fname)
        try:
            with open(fpath, encoding="utf-8", errors="replace") as fh:
                content = fh.read()
        except Exception:
            continue

        if "NoDisplay=true" in content:
            continue
        if "Type=Application" not in content:
            continue

        name = icon = exec_line = ""
        for line in content.split("\n"):
            if line.startswith("Name=") and not name:
                name = line.split("=", 1)[1]
            elif line.startswith("Icon=") and not icon:
                icon = line.split("=", 1)[1]
            elif line.startswith("Exec=") and not exec_line:
                exec_line = line.split("=", 1)[1]

        if not name or not exec_line:
            continue

        # Determine real executable name
        exec_name = flatpak_id = ""
        if "flatpak run" in exec_line:
            m = re.search(r'--command=(\S+)', exec_line)
            if m:
                exec_name = m.group(1)
            # Flatpak ID is after all -- flags, before % or @@
            parts = exec_line.split()
            for i, part in enumerate(parts):
                if part.startswith("--"):
                    continue
                if part in ("run", "/usr/bin/flatpak", "flatpak"):
                    continue
                if part.startswith("%") or part.startswith("@@"):
                    continue
                flatpak_id = part
        else:
            clean = re.sub(r' %[uUfFdDnNickvm]', '', exec_line)
            first = clean.split()[0] if clean.split() else ""
            exec_name = first.split("/")[-1] if "/" in first else first

        if not exec_name:
            continue
        if exec_name.lower() in IGNORE:
            continue

        # Check if process is running
        is_running = exec_name.lower() in running_procs
        if not is_running and flatpak_id and flatpak_id in flatpak_running:
            is_running = True
        if not is_running:
            continue

        # Check if has window (foreground)
        key = exec_name.lower().replace("-", "").replace(" ", "")
        has_window = key in mapped_classes

        entry = f"{name}|{icon}|{exec_name}|{flatpak_id}"
        if has_window:
            if exec_name not in seen_fg:
                foreground.append(entry)
                seen_fg.add(exec_name)
        else:
            if exec_name not in seen_bg:
                background.append(entry)
                seen_bg.add(exec_name)

# 5. Add direct Hyprland entries for windows not matched by .desktop
all_matched_keys = set()
for entry in foreground + background:
    exec_name = entry.split("|")[2]
    all_matched_keys.add(exec_name.lower().replace("-", "").replace(" ", ""))

for c in clients:
    if c.get("mapped"):
        cls = c["class"]
        key = cls.lower().replace("-", "").replace(" ", "")
        if key and key not in all_matched_keys and key not in IGNORE:
            entry = f"{cls}||{cls}|"
            foreground.append(entry)
            all_matched_keys.add(key)

# 6. Sort and write
background.sort(key=lambda x: x.split("|")[2])
foreground.sort(key=lambda x: x.split("|")[2])

with open(BG_FILE, "w") as f:
    f.write("\n".join(background))
with open(FG_FILE, "w") as f:
    f.write("\n".join(foreground))
