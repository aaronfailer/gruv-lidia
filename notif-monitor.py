#!/usr/bin/env python3
import json, os, subprocess, time, sys, re
from threading import Timer

NOTIF_FILE = "/tmp/qs_notifications.json"
MAX_NOTIFS = 50

class NotifMonitor:
    def __init__(self):
        self.notifications = {}
        self.swaync_to_local = {}
        self.local_to_swaync = {}
        self.pending = {}
        self.next_id = int(time.time() * 1000) % 1000000
        self.load_state()
        self.run()

    def load_state(self):
        if os.path.exists(NOTIF_FILE):
            try:
                with open(NOTIF_FILE) as f:
                    for n in json.load(f).get("notifications", []):
                        self.notifications[n["id"]] = n
                        self.next_id = max(self.next_id, n["id"] + 1)
            except:
                pass

    def write_state(self):
        sorted_n = sorted(self.notifications.values(), key=lambda x: -x["timestamp"])[:MAX_NOTIFS]
        clean = []
        for n in sorted_n:
            d = {k: v for k, v in n.items() if not k.startswith("_")}
            clean.append(d)
        with open(NOTIF_FILE, "w") as f:
            json.dump({"notifications": clean, "count": len(clean)}, f)

    def add_notification(self, data):
        nid = self.next_id
        self.next_id += 1
        notif = {
            "id": nid,
            "app_name": data.get("app_name", ""),
            "app_icon": data.get("app_icon", ""),
            "summary": data.get("summary", ""),
            "body": data.get("body", ""),
            "timestamp": time.time(),
        }
        expire = data.get("expire_timeout", -1)
        if expire > 0:
            t = Timer(expire / 1000.0 + 1, self.remove_notification, [nid])
            t.daemon = True
            t.start()
            notif["_timer"] = t
        self.notifications[nid] = notif
        self.write_state()
        return nid

    def remove_notification(self, nid):
        if nid not in self.notifications:
            return
        if nid in self.local_to_swaync:
            sid = self.local_to_swaync[nid]
            del self.swaync_to_local[sid]
            del self.local_to_swaync[nid]
        if self.notifications[nid].get("_timer"):
            self.notifications[nid]["_timer"].cancel()
        del self.notifications[nid]
        self.write_state()

    def remove_by_swaync_id(self, sid):
        if sid in self.swaync_to_local:
            self.remove_notification(self.swaync_to_local[sid])

    def run(self):
        proc = subprocess.Popen(
            ["dbus-monitor", "--session"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )
        parsing_notify = False
        parsing_return = False
        parsing_closed = False
        ret_serial = 0
        arg_count = 0
        array_depth = 0
        nd = {}
        for line in proc.stdout:
            raw = line.rstrip()
            s = raw.strip()
            if 'interface=org.freedesktop.Notifications' in raw and 'member=Notify' in raw:
                parsing_notify = True
                parsing_return = False
                parsing_closed = False
                arg_count = 0
                array_depth = 0
                nd = {}
                m = re.search(r'serial=(\d+)', raw)
                if m:
                    nd["_serial"] = int(m.group(1))
                continue
            if 'reply_serial=' in raw and 'method return' in raw:
                m = re.search(r'reply_serial=(\d+)', raw)
                if m:
                    rs = int(m.group(1))
                    if rs in self.pending:
                        parsing_return = True
                        parsing_notify = False
                        parsing_closed = False
                        ret_serial = rs
                        arg_count = 0
                continue
            if 'member=NotificationClosed' in raw:
                parsing_closed = True
                parsing_notify = False
                parsing_return = False
                arg_count = 0
                closed_id = None
                continue
            if parsing_notify:
                if 'array [' in s:
                    array_depth += 1
                    continue
                if array_depth > 0:
                    array_depth += s.count("[") - s.count("]")
                    if array_depth <= 0:
                        array_depth = 0
                    continue
                if s.startswith("string "):
                    val = s[7:].strip('"')
                    if arg_count == 0:
                        nd["app_name"] = val
                    elif arg_count == 2:
                        nd["app_icon"] = val
                    elif arg_count == 3:
                        nd["summary"] = val
                    elif arg_count == 4:
                        nd["body"] = val
                    arg_count += 1
                elif s.startswith("uint32 "):
                    if arg_count == 1:
                        nd["replaces_id"] = int(s.split()[-1])
                    arg_count += 1
                elif s.startswith("int32 "):
                    nd["expire_timeout"] = int(s.split()[-1])
                    serial = nd.get("_serial", 0)
                    self.pending[serial] = dict(nd)
                    parsing_notify = False
                continue
            if parsing_return:
                if s.startswith("uint32 "):
                    swaync_id = int(s.split()[-1])
                    if ret_serial in self.pending:
                        data = self.pending[ret_serial]
                        nid = self.add_notification(data)
                        self.swaync_to_local[swaync_id] = nid
                        self.local_to_swaync[nid] = swaync_id
                        self.notifications[nid]["swaync_id"] = swaync_id
                        self.write_state()
                        del self.pending[ret_serial]
                    parsing_return = False
                continue
            if parsing_closed:
                if s.startswith("uint32 "):
                    val = int(s.split()[-1])
                    if arg_count == 0:
                        closed_id = val
                        arg_count += 1
                    else:
                        self.remove_by_swaync_id(closed_id)
                        parsing_closed = False
                continue
        proc.wait()

if __name__ == "__main__":
    NotifMonitor()
