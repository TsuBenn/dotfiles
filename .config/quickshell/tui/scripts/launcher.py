#!/usr/bin/env python3

from config import SETTINGS, CALC, COLORS
import os
import sys
import json
import configparser
import re
import subprocess

# ─── ENV ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FREQ_FILE = os.path.join(SCRIPT_DIR, "frequency.json")
SETTINGS_FILE = os.path.join(SCRIPT_DIR, "settings.toml")

DESKTOP_DIRS = [
    "/usr/share/applications",
    "/usr/local/share/applications/",
    "/var/lib/flatpak/exports/share/applications/",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications/"),
    os.path.expanduser("~/.local/share/applications")
]

ICON_DIRS = [
    "/usr/share/icons/hicolor",
    "/usr/share/icons",
    "/usr/share/pixmaps",
    "/var/lib/flatpak/exports/share/icons/",
    "/var/lib/flatpak/exports/share/icons/hicolor/",
    os.path.expanduser("~/.local/share/icons"),
    os.path.expanduser("~/.local/share/icons/hicolor"),
]

ICON_SIZES = ["256x256", "192x192", "128x128", "96x96", "64x64", "48x48", "32x32", "24x24", "16x16", "scalable"]
ICON_EXTS = ["png", "svg", "xpm"]

ICON_CACHE_FILE = os.path.join(SCRIPT_DIR, "icon_cache.json")

FUZZY = False

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

def fuzzy_match(query, target, fuzzy = True):
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

    if FUZZY and fuzzy:
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
    if max_consecutive < len(query) / 2:
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

def scan_apps(icon = True):
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
    if icon:
        save_icon_cache([{"name": app["name"], "icon": resolve_icon(app["icon"])} for app in apps])
    return apps

def search_apps(apps, query):
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
        "label": app["name"],
        "description": app["genericName"] or app["description"],
        "icon": app["icon"],
        "value": app["exec"],
        "type": "exec"
    } for _, app in scored]

def select_app(app_id):
    apps = scan_apps()
    app = next((a for a in apps if a["id"] == app_id), None)
    if not app:
        return
    increment_frequency(app_id)
    exec_cmd = re.sub(r"%[a-zA-Z]", "", app["exec"]).strip()
    subprocess.Popen(exec_cmd.split(), start_new_session=True)

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

import math

def calculate(expr):
    try:
        # 1. Define the functions you want to support
        safe_methods = {
            "sqrt": math.sqrt,
            "sin": math.sin,
            "cos": math.cos,
            "tan": math.tan,
            "log": math.log,
            "pi": math.pi,
            "e": math.e,
            "pow": pow,
            "abs": abs
        }

        allowed = set("0123456789+-*/().% abcdefghijklmnopqrstuvwxyz")

        clean_expr = expr.lower().strip()

        if not all(c in allowed for c in clean_expr):
            return [{"label": "Invalid characters", "type": "info"}]

        # 3. Use restricted eval
        # __builtins__: {} blocks access to dangerous system functions
        result = eval(clean_expr, {"__builtins__": {}}, safe_methods)

        # Round result for cleaner UI (optional)
        if isinstance(result, float):
            result = round(result, 4)

        return [
            {
                "label": "= " + str(result),
                "description": str(result),
                "type": "exec",
                "value": ["bash", "-c", f"echo \"{str(result)}\" | wl-copy"],
            }
        ]
    except Exception as e:
        return [
            {
                "label": "No result",
                "description": str(e),
                "type": "exec",
                "value": [""],
            }
        ]

# ─── Icons ───────────────────────────────────────────────────────────────────

import glob
from pathlib import Path

def resolve_icon(query):

    icon_name = query

    if Path(icon_name).exists():
        return icon_name

    if not icon_name:
        return None  # app exists but no icon

    # search for icon file
    for directory in ICON_DIRS:
        for size in ICON_SIZES:
            for ext in ICON_EXTS:
                pattern = f"{directory}/{size}/apps/{icon_name}.{ext}"
                matches = glob.glob(pattern)
                if matches:
                    return matches[0]
        for ext in ICON_EXTS:
            path = f"{directory}/{icon_name}.{ext}"
            if os.path.exists(path):
                return path

    for ext in ICON_EXTS:
        path = f"/usr/share/pixmaps/{icon_name}.{ext}"
        if os.path.exists(path):
            return path

    # fuzzy fallback on icon files
    all_icons = glob.glob("/usr/share/icons/hicolor/**/apps/*", recursive=True)
    all_icons += glob.glob("/usr/share/pixmaps/*")

    best_icon_score = 0
    best_icon_path = ""
    for path in all_icons:
        filename = os.path.splitext(os.path.basename(path))[0]
        score = fuzzy_match(icon_name.lower(), filename.lower())
        if score > best_icon_score:
            best_icon_score = score
            best_icon_path = path

    if best_icon_score > 30:
        return best_icon_path

    return ""  # app found but no icon anywhere

def load_icon_cache():
    try:
        with open(ICON_CACHE_FILE) as f:
            return json.load(f)
    except:
        return []

def save_icon_cache(cache):
    with open(ICON_CACHE_FILE, "w") as f:
        json.dump(cache, f, indent=2)

# ─── Settings ────────────────────────────────────────────────────────────────

def search_settings(data, query):
    results = []

    def recurse(items):
        for item in items:
            # Calculate scores for both label and description
            label_score = fuzzy_match(query, item.get("label", ""))
            desc_score = fuzzy_match(query, item.get("description", ""))
            
            # Take the best score of the two
            final_score = max(label_score, desc_score)

            # If it's a menu, keep digging regardless of whether the menu itself matched
            if item.get("type") == "menu" and isinstance(item.get("value"), list):
                recurse(item["value"])
                continue

            if final_score > 0:
                # Store a copy of the item with its score for sorting later
                match = item.copy()
                match["search_score"] = final_score
                results.append(match)

    recurse(data)

    # Sort results: Highest score first
    results.sort(key=lambda x: x["search_score"], reverse=True)

    for r in results: r.pop("search_score", None)
    
    return results

# ─── Input ───────────────────────────────────────────────────────────────────

def parse_input(input):
    tags = re.findall(r"(?<!\S)-[a-zA-Z]+\b",input)
    tags = [char for tag in tags for char in tag]
    paths = re.findall(r"--(\w+)",input)
    query = " ".join(re.sub(r"(?<!\S)-[a-zA-Z]+\b","",input).strip().split())
    query = " ".join(re.sub(r"--(\w+)","",query).strip().split())
    return tags, query, paths

# ─── Main ────────────────────────────────────────────────────────────────────

def main():

    global FUZZY

    apps = scan_apps() 
    icons = []

    for app in apps:
        icons.append({
            "name": app["id"],
            "icon": resolve_icon(app["icon"]),
        })

    init = []

    init.extend([{
        "id": app["id"],
        "label": app["name"],
        "description": app["genericName"] or app["description"],
        "icon": app["icon"],
        "value": ["bash", "-c", app["exec"]],
        "type": "exec"
    } for app in apps])

    init.extend(SETTINGS)

    print(json.dumps(init))

    while True:
        result = []

        tags, query, paths = parse_input(input())

        settings = SETTINGS

        if paths:
            for path in paths:
                for setting in settings:
                    if "id" in setting:
                        if setting["id"] == path and setting["type"] == "menu":
                            settings = setting["value"]
                            break

        if not tags:
            print("Error: Please add at least a tag!", file=sys.stderr)
            continue

        if "f" in tags:
            FUZZY = True
        else:
            FUZZY = False

        if "a" in tags:
            if query:
                result.extend(search_apps(apps, query))
            else:
                result.extend([{
                    "id": app["id"],
                    "label": app["name"],
                    "description": app["genericName"] or app["description"],
                    "icon": app["icon"],
                    "value": ["bash", "-c", app["exec"]],
                    "type": "exec"
                } for app in apps])

        if "s" in tags:
            if query:
                result.extend(search_settings(settings, query))
            else:
                result.extend(settings)

        if "c" in tags:
            if query:
                result = [*calculate(query), *CALC]
            else:
                result = CALC

        if "t" in tags:
            result = COLORS

        result = search_settings(result, query)

        print(json.dumps(result))


main()
