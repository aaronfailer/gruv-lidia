#!/usr/bin/env python3
import os, sys, json, shutil, stat, subprocess, zipfile, io
from urllib.parse import unquote

def list_dir(path, sort_mode="nombre", show_hidden="0"):
    entries = []
    try:
        names = os.listdir(path)
    except PermissionError:
        return {"error": "Permission denied"}
    except FileNotFoundError:
        return {"error": "Path not found"}
    for name in names:
        if show_hidden != "1" and name.startswith("."):
            continue
        full = os.path.join(path, name)
        try:
            st = os.lstat(full)
            ftype = "dir" if os.path.isdir(full) else "file" if os.path.isfile(full) else "symlink" if os.path.islink(full) else "other"
            entries.append({"name": name, "type": ftype, "size": st.st_size, "modified": int(st.st_mtime), "mode": stat.filemode(st.st_mode), "path": full})
        except Exception:
            pass
    is_dir = lambda e: 0 if e["type"] == "dir" else 1
    if sort_mode == "nombre":
        entries.sort(key=lambda e: (is_dir(e), e["name"].lower()))
    elif sort_mode == "tamano":
        entries.sort(key=lambda e: (is_dir(e), e["size"]), reverse=True)
    elif sort_mode == "fecha":
        entries.sort(key=lambda e: (is_dir(e), e["modified"]), reverse=True)
    elif sort_mode == "alfabetico":
        entries.sort(key=lambda e: (is_dir(e), e["name"].lower()))
    else:
        entries.sort(key=lambda e: (is_dir(e), e["name"].lower()))
    return {"entries": entries, "path": path}

def home_path():
    return os.path.expanduser("~")

def _create_odf(path, mimetype):
    manifest = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" '
        'manifest:version="1.2">\n'
        '  <manifest:file-entry manifest:full-path="/" manifest:version="1.2" '
        'manifest:media-type="' + mimetype + '"/>\n'
        '  <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>\n'
        '</manifest:manifest>\n'
    )
    content = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
        'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" '
        'office:version="1.2">\n'
        '  <office:body>\n'
        '    <office:text/>\n'
        '  </office:body>\n'
        '</office:document-content>\n'
    )
    buf = io.BytesIO()
    zf = zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED)
    info = zipfile.ZipInfo("mimetype")
    info.compress_type = zipfile.ZIP_STORED
    info.external_attr = 0o644 << 16
    zf.writestr(info, mimetype)
    zf.writestr("META-INF/manifest.xml", manifest)
    zf.writestr("content.xml", content)
    zf.close()
    with open(path, "wb") as f:
        f.write(buf.getvalue())

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No command"})); sys.exit(1)
    cmd = sys.argv[1]
    result = {"error": f"Unknown command: {cmd}"}
    if cmd == "list":
        path = os.path.abspath(os.path.expanduser(sys.argv[2])) if len(sys.argv) > 2 else home_path()
        sort_mode = sys.argv[3] if len(sys.argv) > 3 else "nombre"
        show_hidden = sys.argv[4] if len(sys.argv) > 4 else "0"
        result = list_dir(path, sort_mode, show_hidden)
    elif cmd == "home":
        result = {"path": home_path()}
    elif cmd == "trash":
        for p in sys.argv[2:]:
            subprocess.run(["gio", "trash", p], capture_output=True, text=True)
        result = {"success": True}
    elif cmd == "delete":
        for p in sys.argv[2:]:
            shutil.rmtree(p) if os.path.isdir(p) else os.remove(p)
        result = {"success": True}
    elif cmd == "copy":
        shutil.copytree(sys.argv[2], sys.argv[3]) if os.path.isdir(sys.argv[2]) else shutil.copy2(sys.argv[2], sys.argv[3])
        result = {"success": True}
    elif cmd == "move":
        shutil.move(sys.argv[2], sys.argv[3]); result = {"success": True}
    elif cmd == "mkdir":
        os.makedirs(sys.argv[2], exist_ok=True); result = {"success": True}
    elif cmd == "create":
        path = sys.argv[2]
        ftype = sys.argv[3] if len(sys.argv) > 3 else "empty"
        if ftype == "dir":
            os.makedirs(path, exist_ok=True)
        elif ftype == "text":
            with open(path, "w") as f: f.write("")
        elif ftype == "html":
            with open(path, "w") as f:
                f.write("<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<title></title>\n</head>\n<body>\n\n</body>\n</html>\n")
        elif ftype == "empty":
            open(path, "a").close()
        elif ftype == "web-link":
            name = os.path.splitext(os.path.basename(path))[0]
            with open(path, "w") as f:
                f.write("[Desktop Entry]\nType=Link\nName=" + name + "\nURL=https://\nIcon=text-html\n")
        elif ftype == "file-link":
            name = os.path.splitext(os.path.basename(path))[0]
            with open(path, "w") as f:
                f.write("[Desktop Entry]\nType=Link\nName=" + name + "\nURL=file:///home/\nIcon=emblem-symbolic-link\n")
        elif ftype == "app-link":
            name = os.path.splitext(os.path.basename(path))[0]
            with open(path, "w") as f:
                f.write("[Desktop Entry]\nType=Application\nName=" + name + "\nExec=\nIcon=application-x-executable\nTerminal=false\n")
        elif ftype == "odt":
            _create_odf(path, "application/vnd.oasis.opendocument.text")
        elif ftype == "ods":
            _create_odf(path, "application/vnd.oasis.opendocument.spreadsheet")
        elif ftype == "odp":
            _create_odf(path, "application/vnd.oasis.opendocument.presentation")
        elif ftype == "md":
            name = os.path.splitext(os.path.basename(path))[0]
            with open(path, "w") as f:
                f.write("# " + name + "\n\n")
        elif ftype == "py":
            with open(path, "w") as f:
                f.write("#!/usr/bin/env python3\n# -*- coding: utf-8 -*-\n\n\ndef main():\n    pass\n\n\nif __name__ == \"__main__\":\n    main()\n")
            os.chmod(path, 0o755)
        elif ftype == "sh":
            with open(path, "w") as f:
                f.write("#!/usr/bin/env bash\n\n\n")
            os.chmod(path, 0o755)
        elif ftype == "json":
            with open(path, "w") as f:
                f.write("{}\n")
        elif ftype == "css":
            open(path, "a").close()
        elif ftype == "js":
            with open(path, "w") as f:
                f.write("// " + os.path.basename(path) + "\n\n")
        result = {"success": True}
    elif cmd == "compress":
        if len(sys.argv) < 4:
            result = {"error": "Usage: compress <dest.zip> <source1> [source2 ...]"}
        else:
            dst = sys.argv[2]
            sources = sys.argv[3:]
            dirs = [os.path.dirname(s) for s in sources]
            common = os.path.commonpath(dirs)
            rels = [os.path.basename(s) for s in sources]
            r = subprocess.run(["zip", "-r", dst] + rels, cwd=common, capture_output=True, text=True)
            result = {"success": r.returncode == 0, "error": r.stderr.strip() if r.returncode != 0 else ""}
    elif cmd == "decompress":
        if len(sys.argv) < 3:
            result = {"error": "Usage: decompress <archive>"}
        else:
            src = sys.argv[2]
            dst_dir = os.path.dirname(src)
            name = os.path.basename(src).lower()
            r = None
            if name.endswith(".tar.gz") or name.endswith(".tar.bz2") or name.endswith(".tar.xz") or name.endswith(".tar"):
                r = subprocess.run(["tar", "-xf", src, "-C", dst_dir], capture_output=True, text=True)
            elif name.endswith(".zip"):
                r = subprocess.run(["unzip", "-o", src, "-d", dst_dir], capture_output=True, text=True)
            elif name.endswith(".rar"):
                r = subprocess.run(["unrar", "x", src, dst_dir], capture_output=True, text=True)
            elif name.endswith(".7z"):
                r = subprocess.run(["7z", "x", src, "-o" + dst_dir], capture_output=True, text=True)
            else:
                result = {"error": "Unsupported archive format"}
            if r is not None:
                result = {"success": r.returncode == 0, "error": r.stderr.strip() if r.returncode != 0 else ""}
    elif cmd == "restore":
        trash_info_dir = os.path.expanduser("~/.local/share/Trash/info")
        for p in sys.argv[2:]:
            base = os.path.basename(p)
            info_path = os.path.join(trash_info_dir, base + ".trashinfo")
            if os.path.exists(info_path):
                with open(info_path) as f:
                    data = f.read()
                orig = ""
                for line in data.splitlines():
                    if line.startswith("Path="):
                        orig = line[5:].strip()
                        orig = unquote(orig)
                        break
                if orig:
                    if orig.startswith("file://"):
                        orig = orig[7:]
                    os.makedirs(os.path.dirname(orig), exist_ok=True)
                    shutil.move(p, orig)
                    os.remove(info_path)
        result = {"success": True}
    elif cmd == "rename":
        os.rename(sys.argv[2], sys.argv[3]); result = {"success": True}
    elif cmd == "read":
        try:
            with open(sys.argv[2], "r", errors="replace") as f:
                lines = f.readlines()
                result = {"content": "".join(lines[:200]), "total": len(lines), "truncated": len(lines) > 200}
        except Exception as e:
            result = {"error": str(e)}
    elif cmd == "pdfpreview":
        outpath = sys.argv[3] if len(sys.argv) > 3 else "/tmp/qs_pdf_preview.jpg"
        limit = sys.argv[4] if len(sys.argv) > 4 else "400"
        if os.path.exists(outpath):
            os.remove(outpath)
        r = subprocess.run(["pdftoppm", "-singlefile", "-f", "1", "-l", "1", "-scale-to", limit, "-jpeg", sys.argv[2], outpath.replace(".jpg","")], capture_output=True, text=True)
        result = {"success": r.returncode == 0, "output": outpath, "error": r.stderr.strip() if r.returncode != 0 else ""}
    elif cmd == "open":
        subprocess.Popen(["xdg-open", sys.argv[2]]); result = {"success": True}
    elif cmd == "xdg_dirs":
        home = os.path.expanduser("~")
        result = {"success": True, "home": home}
        try:
            with open(os.path.join(home, ".config/user-dirs.dirs")) as f:
                for line in f:
                    if line.startswith("XDG_"):
                        parts = line.strip().split("=", 1)
                        if len(parts) == 2:
                            val = parts[1].strip().strip('"').replace("$HOME", home)
                            result[parts[0].replace("XDG_", "").replace("_DIR", "").lower() + "_dir"] = val
        except: pass
    elif cmd == "recent_files":
        limit = int(sys.argv[2]) if len(sys.argv) > 2 else 15
        home = os.path.expanduser("~")
        files = []
        seen = set()

        # Source 1: internal tracker (qs-recent.json)
        recent_db = os.path.join(home, ".local/share/qs-recent.json")
        if os.path.exists(recent_db):
            try:
                with open(recent_db) as f:
                    for entry in json.load(f):
                        p = entry.get("path", "")
                        if p in seen or not os.path.exists(p):
                            continue
                        seen.add(p)
                        try:
                            st = os.lstat(p)
                            is_dir = stat.S_ISDIR(st.st_mode)
                            files.append({
                                "name": entry.get("name", os.path.basename(p)),
                                "path": p,
                                "type": "dir" if is_dir else "file",
                                "modified": int(st.st_mtime),
                                "size": st.st_size,
                                "visited": entry.get("timestamp", int(st.st_mtime))
                            })
                        except:
                            pass
            except:
                pass

        # Source 2: recently-used.xbel (XDG standard)
        xbel = os.path.expanduser("~/.local/share/recently-used.xbel")
        if os.path.exists(xbel):
            try:
                import xml.etree.ElementTree as ET
                from datetime import datetime
                tree = ET.parse(xbel)
                for bk in tree.getroot().findall("bookmark"):
                    href = bk.get("href", "")
                    if not href.startswith("file://"):
                        continue
                    path = unquote(href[7:])
                    if path in seen or not os.path.exists(path):
                        continue
                    seen.add(path)
                    try:
                        visited = bk.get("visited", bk.get("modified", bk.get("added", "")))
                        ts = 0
                        try:
                            ts = int(datetime.fromisoformat(visited.replace("Z", "+00:00")).timestamp())
                        except:
                            ts = int(os.path.getmtime(path))
                        st = os.lstat(path)
                        is_dir = stat.S_ISDIR(st.st_mode)
                        files.append({
                            "name": os.path.basename(path),
                            "path": path,
                            "type": "dir" if is_dir else "file",
                            "modified": int(st.st_mtime),
                            "size": st.st_size,
                            "visited": ts
                        })
                    except:
                        pass
            except:
                pass

        # Source 3: find fallback (if both sources were empty)
        if not files:
            try:
                skip = ["/.cache/", "/.local/share/Trash/", "/.snapshots/", "/go/pkg/",
                        "/node_modules/", "/.npm/", "/.cargo/", "/.rustup/", "/.mozilla/",
                        "/.config/chromium/", "/var/", "/.local/share/opencode/"]
                out = subprocess.run(["find", home, "-maxdepth", "5", "-type", "f", "-mtime", "-7"],
                                   capture_output=True, text=True, timeout=10)
                for fpath in out.stdout.strip().split("\n"):
                    fpath = fpath.strip()
                    if not fpath or fpath in seen:
                        continue
                    if any(x in fpath for x in skip):
                        continue
                    try:
                        st = os.lstat(fpath)
                        files.append({
                            "name": os.path.basename(fpath),
                            "path": fpath,
                            "type": "file",
                            "modified": int(st.st_mtime),
                            "size": st.st_size
                        })
                    except:
                        pass
            except:
                pass

        files.sort(key=lambda x: -x.get("visited", x["modified"]))
        result = {"success": True, "files": files[:limit]}
    elif cmd == "append_recent":
        path = sys.argv[2]
        name = os.path.basename(path)
        ts = int(subprocess.run(["date", "+%s"], capture_output=True, text=True).stdout.strip())
        recent_db = os.path.join(os.path.expanduser("~"), ".local/share/qs-recent.json")
        entries = []
        try:
            if os.path.exists(recent_db):
                with open(recent_db) as f:
                    entries = json.load(f)
        except:
            entries = []
        entries = [e for e in entries if e.get("path") != path]
        entries.insert(0, {"path": path, "name": name, "timestamp": ts})
        entries = entries[:50]
        os.makedirs(os.path.dirname(recent_db), exist_ok=True)
        with open(recent_db, "w") as f:
            json.dump(entries, f, indent=2)
        result = {"success": True}
    elif cmd == "list_devices":
        r = subprocess.run(["lsblk", "--json", "-o", "NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL,FSUSED,FSAVAIL,FSUSE%,RM"], capture_output=True, text=True)
        if r.returncode == 0:
            data = json.loads(r.stdout)
            for dev in data.get("blockdevices", []):
                parent_rm = int(dev.get("rm", 0))
                for child in dev.get("children", []):
                    child_rm = child.get("rm")
                    child["rm"] = int(child_rm) if child_rm is not None else parent_rm
                    if "fsuse%" in child and child["fsuse%"] is not None:
                        child["fsuse_perc"] = child.pop("fsuse%").rstrip("%")
            result = {"success": True, "devices": data}
        else:
            result = {"error": r.stderr.strip()}
    elif cmd == "mount_device":
        r = subprocess.run(["udisksctl", "mount", "-b", sys.argv[2]], capture_output=True, text=True)
        result = {"success": r.returncode == 0, "error": r.stderr.strip() if r.returncode != 0 else "", "output": r.stdout.strip()}
    elif cmd == "unmount_device":
        r = subprocess.run(["udisksctl", "unmount", "-b", sys.argv[2]], capture_output=True, text=True)
        result = {"success": r.returncode == 0, "error": r.stderr.strip() if r.returncode != 0 else "", "output": r.stdout.strip()}
    elif cmd == "clipboard":
        subprocess.run(["wl-copy"], input=sys.argv[2], text=True)
        result = {"success": True}
    elif cmd == "revert":
        try:
            op = json.loads(sys.argv[2])
            t = op.get("type")
            if t == "rename":
                os.rename(op["newPath"], op["oldPath"])
            elif t == "create":
                p = op["path"]
                os.remove(p) if os.path.isfile(p) else shutil.rmtree(p, ignore_errors=True)
            elif t == "mkdir":
                os.rmdir(op["path"])
            elif t == "copy":
                p = op["dst"]
                os.remove(p) if os.path.isfile(p) else shutil.rmtree(p, ignore_errors=True)
            elif t == "move":
                shutil.move(op["newPath"], op["oldPath"])
            elif t == "trash":
                paths = op.get("paths", [op.get("path")])
                for p in paths:
                    if p: subprocess.run(["gio", "trash", p], capture_output=True)
            elif t == "delete":
                result = {"error": "No se puede deshacer una eliminación permanente"}
                print(json.dumps(result)); sys.exit(0)
            elif t == "compress":
                os.remove(op["dst"])
            elif t == "duplicate":
                os.remove(op["dst"])
            result = {"success": True}
        except Exception as e:
            result = {"error": str(e)}
    elif cmd == "search":
        path = os.path.abspath(os.path.expanduser(sys.argv[2]))
        query = sys.argv[3].lower()
        limit = int(sys.argv[4]) if len(sys.argv) > 4 else 50
        files = []
        try:
            out = subprocess.run(["find", path, "-maxdepth", "4", "-iname", "*" + query + "*"], capture_output=True, text=True, timeout=10)
            for fpath in out.stdout.strip().split("\n"):
                fpath = fpath.strip()
                if not fpath or fpath == path: continue
                try:
                    st = os.lstat(fpath)
                    ftype = "dir" if os.path.isdir(fpath) else "file"
                    files.append({"name": os.path.basename(fpath), "path": fpath, "type": ftype, "size": st.st_size, "modified": int(st.st_mtime)})
                except: pass
                if len(files) >= limit: break
        except: pass
        result = {"success": True, "entries": files, "path": path, "query": query}
    print(json.dumps(result))
