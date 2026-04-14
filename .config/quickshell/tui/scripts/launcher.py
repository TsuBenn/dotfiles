#!/usr/bin/env python3

import sys
import os
import json
import configparser
import tomllib
import re
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FREQ_FILE = os.path.join(SCRIPT_DIR, "frequency.json")
SETTINGS_FILE = os.path.join(SCRIPT_DIR, "settings.toml")

DESKTOP_DIRS = [
    "/usr/share/applications",
    os.path.expanduser("~/.local/share/applications")
]

# ─── Frequency ───────────────────────────────────────────────────────────────

def load_frequency():
    try:
        with open(FREQ_FILE) as f:
            return json.load(f)
    except:
        return {}

def save_frequency(freq):
    with open(FREQ_FILE, "w") as f:
        json.dump(freq, f)

def increment_frequency(app_id):
    freq = load_frequency()
    freq[app_id] = freq.get(app_id, 0) + 1
    save_frequency(freq)

# ─── Fuzzy Match ─────────────────────────────────────────────────────────────

def fuzzy_match(query, target):
    query = query.lower().strip()
    target = target.lower().strip()
    if not query or not target:
        return 0

    # exact match bonus
    if query == target:
        return 1000
    if target.startswith(query):
        return 500
    if query in target:
        return 300

    qi = 0
    score = 0
    consecutive = 0
    max_consecutive = 0

    for i, ch in enumerate(target):
        if qi < len(query) and ch == query[qi]:
            consecutive += 1
            max_consecutive = max(max_consecutive, consecutive)
            score += consecutive * 10
            if i == 0 or target[i-1] == " ":
                score += 20
            qi += 1
        else:
            consecutive = 0

    if qi < len(query):
        return 0

    # require at least half the query to be consecutive
    if max_consecutive < len(query) // 2:
        return 0

    score -= len(target) * 2
    return max(0, score)

# ─── Apps ────────────────────────────────────────────────────────────────────

def parse_desktop_file(path):
    parser = configparser.ConfigParser(interpolation=None)
    try:
        parser.read(path, encoding="utf-8")
        if "Desktop Entry" not in parser:
            return None
        entry = parser["Desktop Entry"]
        if entry.get("NoDisplay", "false").lower() == "true":
            return None
        if entry.get("Type", "") != "Application":
            return None
        return {
            "id": os.path.basename(path).replace(".desktop", ""),
            "name": entry.get("Name", ""),
            "icon": entry.get("Icon", ""),
            "exec": entry.get("Exec", ""),
            "keywords": [k for k in entry.get("Keywords", "").strip(";").split(";") if k],
            "genericName": entry.get("GenericName", ""),
            "description": entry.get("Comment", "")
        }
    except:
        return None

def scan_apps():
    apps = []
    seen = set()
    for directory in DESKTOP_DIRS:
        if not os.path.exists(directory):
            continue
        for f in os.listdir(directory):
            if f.endswith(".desktop") and f not in seen:
                seen.add(f)
                app = parse_desktop_file(os.path.join(directory, f))
                if app:
                    apps.append(app)
    save_icon_cache([{"name": app["name"], "icon": app["icon"]} for app in apps])
    return apps

def search_apps(query):
    apps = scan_apps()
    freq = load_frequency()
    if not query:
        return []
    scored = []
    for app in apps:
        score = max(
            fuzzy_match(query, app["name"]) * 3,
            fuzzy_match(query, app["genericName"]) * 2,
            max((fuzzy_match(query, k) for k in app["keywords"]), default=0),
        )
        if score <= 0:
            continue
        final_score = score + (freq.get(app["id"], 0) * 2)
        scored.append((final_score, app))
    scored.sort(key=lambda x: x[0], reverse=True)
    return [{
        "id": app["id"],
        "label": app["name"],
        "description": app["genericName"] or app["description"],
        "icon": app["icon"],
        "type": "action"
    } for _, app in scored[:20]]

def select_app(app_id):
    apps = scan_apps()
    app = next((a for a in apps if a["id"] == app_id), None)
    if not app:
        return
    increment_frequency(app_id)
    exec_cmd = re.sub(r"%[a-zA-Z]", "", app["exec"]).strip()
    subprocess.Popen(exec_cmd.split(), start_new_session=True)

# ─── Settings ────────────────────────────────────────────────────────────────

def load_settings():
    try:
        with open(SETTINGS_FILE, "rb") as f:
            return tomllib.load(f).get("settings", [])
    except:
        return []

def find_node(settings, path_ids):
    current = settings
    for pid in path_ids:
        match = next((s for s in current if s.get("id") == pid), None)
        if not match:
            return None
        current = match.get("children", [])
    return current

def search_settings(query, path=None):
    settings = load_settings()
    nodes = find_node(settings, path) if path else settings
    if nodes is None:
        return []
    if not query:
        return [{
            "id": s["id"],
            "label": s["label"],
            "description": s.get("description", ""),
            "icon": s.get("icon", ""),
            "type": "submenu" if "children" in s else "action",
            "value": s.get("value", "")
        } for s in nodes]
    scored = []
    for s in nodes:
        score = max(
            fuzzy_match(query, s["label"]) * 3,
            fuzzy_match(query, s.get("description", "")) * 2,
        )
        if score > 0:
            scored.append((score, s))
    scored.sort(key=lambda x: x[0], reverse=True)
    return [{
        "id": s["id"],
        "label": s["label"],
        "description": s.get("description", ""),
        "icon": s.get("icon", ""),
        "type": "submenu" if "children" in s else "action",
        "value": s.get("value", "")
    } for _, s in scored]

def select_setting(full_id):
    path = full_id.split(":")
    settings = load_settings()
    # walk to the final node
    current = settings
    node = None
    for pid in path:
        node = next((s for s in current if s.get("id") == pid), None)
        if not node:
            return
        current = node.get("children", [])
    if not node:
        return
    if "children" not in node and "value" in node:
        subprocess.Popen(node["value"], shell=True, start_new_session=True)

# ─── Web ─────────────────────────────────────────────────────────────────────

def is_url(query):
    return bool(re.match(r'^(https?://|www\.)|(\.[a-z]{2,}(/|$))', query))

def select_web(query):
    if is_url(query):
        url = query if query.startswith("http") else "https://" + query
    else:
        url = "https://www.google.com/search?q=" + query.replace(" ", "+")
    subprocess.Popen(["xdg-open", url], start_new_session=True)

# ─── Calculator ──────────────────────────────────────────────────────────────

def calculate(expr):
    try:
        allowed = set("0123456789+-*/().% ")
        if not all(c in allowed for c in expr):
            return [{"label": "Invalid expression", "type": "info"}]
        result = eval(expr)
        return [{"label": str(result), "type": "result"}]
    except:
        return [{"label": "Error", "type": "info"}]

# ─── Icon ────────────────────────────────────────────────────────────────────

ICON_CACHE_FILE = os.path.join(SCRIPT_DIR, "icon_cache.json")

def load_icon_cache():
    try:
        with open(ICON_CACHE_FILE) as f:
            return json.load(f)
    except:
        return []

def save_icon_cache(cache):
    with open(ICON_CACHE_FILE, "w") as f:
        json.dump(cache, f, indent=2)

# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    args = sys.argv[1:]

    if "--mode" not in args:
        print(json.dumps([]))
        return

    mode_idx = args.index("--mode")
    mode = args[mode_idx + 1]
    is_select = "--select" in args

    if mode == "apps":
        if is_select:
            select_idx = args.index("--select")
            app_id = args[select_idx + 1]
            select_app(app_id)
            print(json.dumps([]))
        else:
            query = " ".join(args[mode_idx + 2:])
            print(json.dumps(search_apps(query)))

    elif mode == "settings":
        if is_select:
            select_idx = args.index("--select")
            full_id = args[select_idx + 1]
            path = full_id.split(":")
            query = " ".join(args[select_idx + 2:])
            if query:
                # searching inside submenu
                print(json.dumps(search_settings(query, path)))
            else:
                node_settings = load_settings()
                node = find_node(node_settings, path)
                if node is not None:
                    # has children, show submenu
                    print(json.dumps(search_settings("", path)))
                else:
                    # leaf node, execute
                    select_setting(full_id)
                    print(json.dumps([]))
        else:
            query = " ".join(args[mode_idx + 2:])
            print(json.dumps(search_settings(query)))

    elif mode == "web":
        if is_select:
            select_idx = args.index("--select")
            query = " ".join(args[select_idx + 1:])
            select_web(query)
            print(json.dumps([]))

    elif mode == "calc":
        expr = " ".join(args[mode_idx + 2:])
        print(json.dumps(calculate(expr)))

    else:
        print(json.dumps([]))

main()
