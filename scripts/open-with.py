#!/usr/bin/env python3
import sys, os, json, subprocess, configparser, re, shlex

APPS_DIR = '/usr/share/applications'

def get_mime(filepath):
    try:
        r = subprocess.run(['file', '--mime-type', '-b', filepath],
                          capture_output=True, text=True, timeout=5)
        return r.stdout.strip()
    except:
        return ''

def find_mime_apps(mime):
    apps = []
    if not os.path.isdir(APPS_DIR):
        return apps
    for f in sorted(os.listdir(APPS_DIR)):
        if not f.endswith('.desktop'):
            continue
        path = os.path.join(APPS_DIR, f)
        try:
            cp = configparser.ConfigParser(interpolation=None)
            cp.read(path)
            de = cp['Desktop Entry']
            if de.get('NoDisplay', 'false').lower() == 'true':
                continue
            if de.get('Hidden', 'false').lower() == 'true':
                continue
            mts = de.get('MimeType', '')
            if mime in [m.strip() for m in mts.split(';') if m.strip()]:
                apps.append({
                    'name': de.get('Name', f),
                    'icon': de.get('Icon', ''),
                    'exec': de.get('Exec', ''),
                    'desktop': f
                })
        except:
            pass
    return apps

def find_all_file_apps():
    apps = []
    if not os.path.isdir(APPS_DIR):
        return apps
    for f in sorted(os.listdir(APPS_DIR)):
        if not f.endswith('.desktop'):
            continue
        path = os.path.join(APPS_DIR, f)
        try:
            cp = configparser.ConfigParser(interpolation=None)
            cp.read(path)
            de = cp['Desktop Entry']
            if de.get('NoDisplay', 'false').lower() == 'true':
                continue
            if de.get('Hidden', 'false').lower() == 'true':
                continue
            exec_cmd = de.get('Exec', '')
            if '%f' in exec_cmd.lower() or '%F' in exec_cmd.lower() or '%u' in exec_cmd.lower() or '%U' in exec_cmd.lower():
                apps.append({
                    'name': de.get('Name', f),
                    'icon': de.get('Icon', ''),
                    'exec': exec_cmd,
                    'desktop': f
                })
        except:
            pass
    return apps

def launch(filepath, exec_cmd):
    qp = shlex.quote(filepath)
    uri = shlex.quote('file://' + filepath)
    cmd = exec_cmd.replace('%f', qp).replace('%F', qp)
    cmd = cmd.replace('%u', uri).replace('%U', uri)
    cmd = re.sub(r'%(?!%)[dDnNvmick]', '', cmd)
    cmd = cmd.replace('%%', '%')
    subprocess.Popen(['sh', '-c', cmd.strip()])

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('[]')
        sys.exit(0)
    action = sys.argv[1]
    if action == 'list' and len(sys.argv) >= 3:
        mime = get_mime(sys.argv[2])
        apps = find_mime_apps(mime)
        if not apps:
            apps = find_all_file_apps()
        print(json.dumps(apps))
    elif action == 'list_all':
        apps = find_all_file_apps()
        print(json.dumps(apps))
    elif action == 'launch' and len(sys.argv) >= 4:
        launch(sys.argv[2], sys.argv[3])
