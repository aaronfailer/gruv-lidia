#!/usr/bin/env python3
import json
import subprocess
import time
import sys

MINIMIZE_WS = 99
POLL_INTERVAL = 0.5

def get_clients():
    r = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=3)
    if r.returncode != 0:
        return None
    return json.loads(r.stdout)

def get_active_workspace():
    r = subprocess.run(['hyprctl', 'activeworkspace', '-j'], capture_output=True, text=True, timeout=3)
    if r.returncode != 0:
        return None
    return json.loads(r.stdout).get('id')

def rescue(addr):
    subprocess.run(
        ['hyprctl', 'dispatch', 'movetoworkspacesilent', str(MINIMIZE_WS), f'address:{addr}'],
        capture_output=True, text=True, timeout=3
    )

def main():
    prev = {}
    first = True

    while True:
        try:
            clients = get_clients()
            active_ws = get_active_workspace()
            if clients is None or active_ws is None:
                if first:
                    print('minimize-rescue: waiting for hyprland...', flush=True)
                    first = False
                time.sleep(POLL_INTERVAL)
                continue

            current = set()
            for c in clients:
                addr = c['address']
                current.add(addr)
                hidden = c.get('hidden', False)
                ws = c.get('workspace', {}).get('id', -1)

                if addr in prev:
                    p = prev[addr]
                    if not p['hidden'] and hidden and p['ws'] == ws == active_ws and ws != MINIMIZE_WS:
                        print(f'minimize-rescue: rescuing {addr} ({c.get("class", "?")}: {c.get("title", "?")}) to ws {MINIMIZE_WS}', flush=True)
                        rescue(addr)

                prev[addr] = {'hidden': hidden, 'ws': ws}

            for addr in list(prev.keys()):
                if addr not in current:
                    del prev[addr]

        except (json.JSONDecodeError, subprocess.TimeoutExpired, subprocess.CalledProcessError):
            pass
        except Exception:
            pass

        time.sleep(POLL_INTERVAL)

if __name__ == '__main__':
    main()
