#!/usr/bin/env python3
"""
launcher.py — long-running search backend for the Quickshell launcher UI.

Input protocol
==============

Quickshell writes one request per line to stdin:

    -<tags> [--<path_id> ...] <query>\n

Tags (single characters, case-sensitive):
    a   apps        (parse .desktop files)
    s   settings    (search SETTINGS from config.py)
    h   files       (search cached filesystem index)
    c   calculator
    t   colors      (return COLORS palette from config.py)
    f   fuzzy       (modifier: enables fuzzy matching for this query)
    F   <query> is an app id — increment its frequency, no output
    w   web         (open <query> as URL or Google search)
    r   refresh     (background rescan of apps + files, no output)

Regex mode
----------

If the query starts with `re:`, the rest of the line is treated as a
Python regex pattern. Matches use re.search (substring match). Use
^...$ for exact-match semantics. Flags can be embedded inline:
    re:(?i)firefox       case-insensitive
    re:^fire             name starts with "fire"
    re:chrome|firefox    name contains "chrome" or "firefox"
    re:\\.py$             name ends with ".py"

Regex has a 50ms timeout per match attempt (SIGALRM). Catastrophic
backtracking patterns will be treated as no-match, not crash.

Output protocol
===============

One JSON array per line on stdout, swallowed by Quickshell's SplitParser.
File searches are async: when `h` is in tags, the script emits the
apps+settings result immediately, then emits a second JSON line with
the combined (apps+settings+files) result once the file search finishes.
If the user types a new query before the in-flight file search finishes,
the old search is cancelled via a generation counter.

Refresh behavior
================

When a refresh finishes (either from the `r` tag or the startup
auto-refresh), the launcher re-emits the user's most recent search
with the new data. This way the user doesn't have to retype to see
updated results — they just wait a moment and the UI silently updates.

If the user typed a new query while the refresh was running, the
re-emit uses the NEW query (since _last_search is updated before each
search runs). So the user always sees fresh data for whatever they're
currently searching for.

Concurrency model
=================

* Stdin reader thread: reads stdin line-by-line, puts lines in a queue.
* Main thread: drains the queue with a short timeout, processes
  requests, writes results to stdout. Between requests, checks if a
  refresh just finished and re-emits the last search if so.
* Refresh thread: spawned by `r` tag (and once at startup). Runs `fd`
  + app scan, atomically swaps the new data into place, then signals
  the main thread to re-emit.
* File-search thread: spawned per query that includes `h`. Each search
  has a generation id; before printing, the worker checks that its
  generation is still current — if not, it discards silently.

Data caches
===========

* `apps`         — list of parsed .desktop entries (memory)
* `icon_index`   — dict {icon_name: path} built once at startup
* `file_paths`   — list of strings, atomically swapped on refresh
* `frequency`    — dict {app_id: count}, loaded once, written on increment

All caches support "swap-in-place" refresh: a refresh builds the new
data in local variables, then assigns to the global in one step.
Readers either see the old or new version, never a mix.
"""

from __future__ import annotations

import json
import math
import os
import queue
import re
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path

from config import SETTINGS, CALC, COLORS

# ─── Paths ────────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).resolve().parent
FREQ_FILE = SCRIPT_DIR / "frequency.json"
FILE_CACHE_FILE = SCRIPT_DIR / "file_cache.json"
ICON_CACHE_FILE = SCRIPT_DIR / "icon_cache.json"

DESKTOP_DIRS = [
    "/usr/share/applications",
    "/usr/local/share/applications/",
    "/var/lib/flatpak/exports/share/applications/",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications/"),
    os.path.expanduser("~/.local/share/applications"),
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

ICON_SIZES = [
    "256x256", "192x192", "128x128", "96x96", "64x64",
    "48x48", "32x32", "24x24", "16x16", "scalable",
]
ICON_EXTS = ["png", "svg", "xpm"]

# fd command for the initial filesystem scan.
FD_CMD = [
    "fd", ".",
    "/",
    "-I",
    "--absolute-path",
    "--exclude", ".git",
    "--exclude", ".cache",
    "--exclude", "node_modules",
    "--hidden",
    "--no-follow",
]

# ─── Shared state ─────────────────────────────────────────────────────────────
#
# All of these are written by either the main thread or background threads.
# Python's GIL makes individual assignments atomic, so a reader will see
# either the old reference or the new one — never a corrupted half-state.
# For paired updates we accept a brief window of inconsistency rather than
# taking a lock on every read, because searches are idempotent and the UI
# re-renders on every keystroke anyway.

apps: list[dict] = []
file_paths: list[str] = []
icon_index: dict[str, str] = {}
frequency: dict[str, int] = {}

# File-search generation counter. Each new file search increments this;
# the worker captures the value at start and compares before printing.
# If a newer search has started, the old worker silently discards.
_file_search_lock = threading.Lock()
_file_search_generation = 0

# Lock for frequency.json writes (multiple increments could race).
_freq_lock = threading.Lock()

# ─── Main-loop plumbing: queue + rerun signaling ─────────────────────────────
#
# The main thread can't block on sys.stdin forever, because it also needs
# to react to "refresh finished, please re-emit the last search" signals
# from background threads. So we split stdin reading into its own thread
# that drops lines into a queue, and the main thread polls the queue
# with a short timeout. Between polls, it checks _rerun_requested.

_input_queue: "queue.Queue[str | None]" = queue.Queue()
_rerun_requested = threading.Event()

# Snapshot of the most recent user-issued search. Used by the rerun
# mechanism after a refresh completes. Guarded by _last_search_lock
# because the main thread writes it and the refresh-finished path
# could theoretically read it (though we always read it on the main
# thread, the lock is defensive).
_last_search: tuple[list[str], str, list[str]] | None = None
_last_search_lock = threading.Lock()


# ─── Frequency tracking ───────────────────────────────────────────────────────

def load_frequency() -> dict[str, int]:
    try:
        with open(FREQ_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_frequency(freq: dict[str, int]) -> None:
    # Atomic write: write to temp, rename. Avoids partial-file reads
    # if the script is killed mid-write.
    tmp = FREQ_FILE.with_suffix(".json.tmp")
    with open(tmp, "w") as f:
        json.dump(freq, f)
    tmp.rename(FREQ_FILE)


def increment_frequency(app_id: str) -> None:
    with _freq_lock:
        frequency[app_id] = frequency.get(app_id, 0) + 1
        save_frequency(frequency)


# ─── Regex support ───────────────────────────────────────────────────────────
#
# Query form:  re:<pattern>
# The prefix `re:` triggers regex mode for this query. The rest of the
# line is the Python regex pattern. Flags can be embedded inline:
#   re:(?i)firefox   — case-insensitive
#   re:(?m)^foo      — multiline
#
# Catastrophic backtracking protection: SIGALRM-based 50ms timeout per
# match attempt. If a regex takes longer, the match returns False and
# a warning is logged. The timeout is process-global (SIGALRM is not
# thread-local), so we guard the setitimer call with a lock to ensure
# only one thread is timing out at a time.
#
# In practice this is fine because regex matching only happens on the
# main thread for apps/settings searches; file-search workers use their
# own per-call try/except (without timeout, since they run in threads
# where SIGALRM is unreliable).

class _RegexTimeout(Exception):
    pass


def _regex_timeout_handler(signum, frame):
    raise _RegexTimeout()


try:
    signal.signal(signal.SIGALRM, _regex_timeout_handler)
    _HAS_SIGALRM = True
except (ValueError, AttributeError):
    _HAS_SIGALRM = False


_regex_compile_lock = threading.Lock()
_regex_timeout_lock = threading.Lock()
_REGEX_CACHE: dict[str, re.Pattern] = {}
_REGEX_CACHE_MAX = 32


def compile_regex(pattern: str) -> re.Pattern | None:
    """Compile a regex pattern, with caching. Returns None on syntax error."""
    with _regex_compile_lock:
        cached = _REGEX_CACHE.get(pattern)
        if cached is not None:
            return cached
        try:
            compiled = re.compile(pattern)
        except re.error as e:
            print(f"launcher: invalid regex {pattern!r}: {e}", file=sys.stderr)
            return None
        if len(_REGEX_CACHE) >= _REGEX_CACHE_MAX:
            # Evict ~half (oldest first — dict preserves insertion order).
            keys = list(_REGEX_CACHE.keys())
            for k in keys[:_REGEX_CACHE_MAX // 2]:
                del _REGEX_CACHE[k]
        _REGEX_CACHE[pattern] = compiled
        return compiled


def regex_match(query_re: re.Pattern, target: str) -> int:
    """Return a score if regex matches target, else 0.

    Score = 1000 - match.start(). Earlier matches rank higher.
    50ms timeout per match attempt (SIGALRM, main thread only).
    """
    if not target:
        return 0
    if _HAS_SIGALRM and threading.current_thread() is threading.main_thread():
        with _regex_timeout_lock:
            signal.setitimer(signal.ITIMER_REAL, 0.05)
            try:
                m = query_re.search(target)
            except _RegexTimeout:
                return 0
            finally:
                signal.setitimer(signal.ITIMER_REAL, 0)
    else:
        # Worker thread — SIGALRM is unreliable, just try the match.
        # Catastrophic regexes here are rare; if they happen the worker
        # will be slow but the generation-counter cancellation ensures
        # the old worker's result is discarded when a new search starts.
        try:
            m = query_re.search(target)
        except (re.error, _RegexTimeout):
            return 0
    if m is None:
        return 0
    return max(0, 1000 - m.start())


def parse_regex_query(query: str) -> tuple[re.Pattern | None, str, str | None]:
    """Detect `re:<pattern>` prefix.

    Returns (compiled_regex_or_None, remainder_query, error_message_or_None).
    If the prefix isn't present, returns (None, original_query, None).
    If the prefix is present but the pattern is invalid, returns
    (None, "", "error message") — caller should surface the error.
    """
    if not query.startswith("re:"):
        return None, query, None
    pattern = query[3:]
    compiled = compile_regex(pattern)
    if compiled is None:
        return None, "", f"Invalid regex: /{pattern}/"
    return compiled, "", None


def regex_error_result(error: str) -> list[dict]:
    """Single info entry to surface a regex error in the UI."""
    return [{
        "id": "regex_error",
        "label": error,
        "description": "",
        "category": "info",
        "icon": "",
        "value": [""],
        "type": "info",
    }]


# ─── Fuzzy matching ──────────────────────────────────────────────────────────
#
# Scoring is kept identical to the original script so result ordering
# doesn't shift. `fuzzy` is now a parameter rather than a global, so
# the function is pure and thread-safe.

def fuzzy_match(query: str, target: str, fuzzy: bool = True) -> int:
    if not query or not target:
        return 0
    q = query.lower().strip()
    t = target.lower().strip()
    if not q or not t:
        return 0

    if q == t:
        return 1000
    if t.startswith(q):
        return 500
    if q in t:
        return 300

    qi = 0
    score = 0
    consecutive = 0
    max_consecutive = 0

    if fuzzy:
        for i, ch in enumerate(t):
            if qi < len(q) and ch == q[qi]:
                consecutive += 1
                max_consecutive = max(max_consecutive, consecutive)
                score += consecutive * 10
                if i == 0 or t[i - 1] == " ":
                    score += 20
                qi += 1
            else:
                consecutive = 0

    if qi < len(q):
        return 0

    if max_consecutive < len(q) / 2:
        return 0

    score -= len(t) * 2
    return max(0, score)


# ─── Apps: .desktop file parsing ─────────────────────────────────────────────
#
# Hand-rolled parser instead of ConfigParser. .desktop files are INI-like
# with one section ("Desktop Entry") and key=value lines. The hand parser
# is ~10x faster than ConfigParser and uses far less memory, which matters
# when scanning 500+ files on every refresh.

_DESKTOP_FIELD_RE = re.compile(r"^([A-Za-z][A-Za-z0-9-]*)\s*=\s*(.*)$")


def parse_desktop_file(path: str) -> dict | None:
    entry: dict[str, str] = {}
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            in_desktop_entry = False
            for line in f:
                line = line.rstrip("\n")
                if not line or line.startswith("#"):
                    continue
                if line.startswith("["):
                    in_desktop_entry = (line == "[Desktop Entry]")
                    continue
                if not in_desktop_entry:
                    continue
                m = _DESKTOP_FIELD_RE.match(line)
                if m:
                    entry[m.group(1)] = m.group(2)
    except (OSError, UnicodeDecodeError):
        return None

    if entry.get("Type") != "Application":
        return None
    if entry.get("NoDisplay", "false").lower() == "true":
        return None

    exec_raw = entry.get("Exec", "")
    exec_clean = re.sub(r"%[a-zA-Z]", "", exec_raw).strip()

    keywords_raw = entry.get("Keywords", "").strip(";")
    keywords = [k for k in keywords_raw.split(";") if k]

    return {
        "id": os.path.basename(path).removesuffix(".desktop"),
        "name": entry.get("Name", ""),
        "icon": entry.get("Icon", ""),
        "exec": exec_raw,
        "exec_clean": exec_clean,
        "keywords": keywords,
        "genericName": entry.get("GenericName", ""),
        "description": entry.get("Comment", ""),
    }


def scan_apps() -> list[dict]:
    """Scan all DESKTOP_DIRS, return parsed app entries. Dedup by filename."""
    out: list[dict] = []
    seen: set[str] = set()
    for directory in DESKTOP_DIRS:
        if not os.path.isdir(directory):
            continue
        try:
            for f in os.listdir(directory):
                if not f.endswith(".desktop") or f in seen:
                    continue
                seen.add(f)
                app = parse_desktop_file(os.path.join(directory, f))
                if app:
                    out.append(app)
        except OSError:
            continue
    return out


def _score_app(query_re: re.Pattern | None, query: str, app: dict, fuzzy: bool) -> int:
    """Score one app against either a regex or a fuzzy query."""
    if query_re is not None:
        best = regex_match(query_re, app["name"])
        gn = regex_match(query_re, app["genericName"])
        if gn > best:
            best = gn
        if app["keywords"]:
            for k in app["keywords"]:
                s = regex_match(query_re, k)
                if s > best:
                    best = s
        sid = regex_match(query_re, app["id"])
        if sid > best:
            best = sid
    else:
        best = fuzzy_match(query, app["name"], fuzzy)
        gn = fuzzy_match(query, app["genericName"], fuzzy)
        if gn > best:
            best = gn
        if app["keywords"]:
            for k in app["keywords"]:
                s = fuzzy_match(query, k, fuzzy)
                if s > best:
                    best = s
        sid = fuzzy_match(query, app["id"], fuzzy)
        if sid > best:
            best = sid
    return best


def search_apps(apps_list: list[dict], query: str, fuzzy: bool) -> list[dict]:
    if not query:
        return []

    query_re, query, _err = parse_regex_query(query)
    # Note: caller (handle_request) does early regex validation, so we
    # don't return regex_error_result here — _err should never fire in
    # practice. Defensive only.

    out: list[tuple[int, dict]] = []
    for app in apps_list:
        best = _score_app(query_re, query, app, fuzzy)
        if best <= 0:
            continue
        score = best + frequency.get(app["id"], 0) * 2
        out.append((score, app))

    out.sort(key=lambda x: x[0], reverse=True)
    return [{
        "id": app["id"],
        "label": app["name"],
        "description": app["genericName"] or app["description"],
        "keywords": app["keywords"],
        "category": "app",
        "icon": app["icon"],
        "value": ["bash", "-c", app["exec_clean"]],
        "type": "exec",
    } for _, app in out]


def select_app(app_id: str) -> None:
    """Launch the app and bump its frequency counter."""
    app = next((a for a in apps if a["id"] == app_id), None)
    if not app:
        return
    increment_frequency(app_id)
    try:
        subprocess.Popen(app["exec_clean"].split(), start_new_session=True)
    except OSError as e:
        print(f"launcher: failed to launch {app_id}: {e}", file=sys.stderr)


# ─── Icon resolution ─────────────────────────────────────────────────────────
#
# Build a single in-memory index of {icon_name: path} once at startup.
# PNG is strongly preferred over SVG (QML's Image handles PNGs more
# predictably — SVGs can render blurry or with wrong intrinsic sizes).
# Within PNGs, the largest available size wins.

def _iter_icon_files() -> list[tuple[str, str]]:
    """Return list of (icon_name, full_path) for every icon file."""
    out: list[tuple[str, str]] = []
    for d in ICON_DIRS:
        if not os.path.isdir(d):
            continue
        for root, _dirs, files in os.walk(d):
            for f in files:
                stem, ext = os.path.splitext(f)
                if ext.lstrip(".") in ICON_EXTS:
                    out.append((stem, os.path.join(root, f)))
    if os.path.isdir("/usr/share/pixmaps"):
        for f in os.listdir("/usr/share/pixmaps"):
            stem, ext = os.path.splitext(f)
            if ext.lstrip(".") in ICON_EXTS:
                out.append((stem, os.path.join("/usr/share/pixmaps", f)))
    return out


# Size preference: smaller index = higher priority. When multiple files
# share the same icon_name, we want the largest available PNG.
_SIZE_PRIORITY = {s: i for i, s in enumerate(ICON_SIZES)}


def _icon_path_score(path: str) -> int:
    """Higher = better. Strongly prefer PNG; within PNG, prefer larger sizes.

    Scoring bands:
      PNG  → 1000 + size_bonus   (1000..1090)
      SVG  → 0    + size_bonus   (0..90)
      XPM  → -100 + size_bonus   (rare, last resort)

    A 256x256 PNG (1090) beats any SVG (max 90). An SVG only wins when
    no PNG exists for that icon name.
    """
    lower = path.lower()
    if lower.endswith(".png"):
        score = 1000
    elif lower.endswith(".svg"):
        score = 0
    else:
        score = -100

    for size, prio in _SIZE_PRIORITY.items():
        if f"/{size}/" in path:
            score += (len(_SIZE_PRIORITY) - prio) * 10
            break

    return score


def build_icon_index() -> dict[str, str]:
    """Build {icon_name: best_path} index. Best = PNG, largest size."""
    index: dict[str, str] = {}
    scores: dict[str, int] = {}
    for name, path in _iter_icon_files():
        s = _icon_path_score(path)
        if s > scores.get(name, -1000):
            scores[name] = s
            index[name] = path
    return index


def save_icon_cache(index: dict[str, str]) -> None:
    """Persist icon index for IconInfo.qml.

    IconInfo.qml expects a LIST of {name, icon} objects (it uses
    Array.prototype.find for lookups). We convert the in-memory dict
    to that list shape on write.
    """
    cache_list = [{"name": name, "icon": path} for name, path in index.items()]
    tmp = ICON_CACHE_FILE.with_suffix(".json.tmp")
    with open(tmp, "w") as f:
        json.dump(cache_list, f)
    tmp.rename(ICON_CACHE_FILE)


def load_icon_cache() -> dict[str, str]:
    """Load icon_cache.json into a dict for O(1) in-memory lookups.

    Tolerates either shape — old cache might be a list (which we
    convert), new cache is also a list (per save_icon_cache above).
    """
    try:
        with open(ICON_CACHE_FILE) as f:
            data = json.load(f)
        if isinstance(data, list):
            return {
                item["name"]: item["icon"]
                for item in data
                if isinstance(item, dict) and "name" in item and "icon" in item
            }
        if isinstance(data, dict):
            return data
        return {}
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


# ─── Settings search ─────────────────────────────────────────────────────────
#
# Walks SETTINGS recursively. Each match keeps its score so callers can
# re-sort a combined list (apps + settings) by score.

def _score_setting(query_re: re.Pattern | None, query: str, item: dict, fuzzy: bool) -> int:
    if query_re is not None:
        best = regex_match(query_re, item.get("label", ""))
        d = regex_match(query_re, item.get("description", ""))
        if d > best:
            best = d
        c = regex_match(query_re, item.get("category", ""))
        if c > best:
            best = c
        for k in item.get("keywords", []) or []:
            s = regex_match(query_re, k)
            if s > best:
                best = s
    else:
        best = fuzzy_match(query, item.get("label", ""), fuzzy)
        d = fuzzy_match(query, item.get("description", ""), fuzzy)
        if d > best:
            best = d
        c = fuzzy_match(query, item.get("category", ""), fuzzy)
        if c > best:
            best = c
        for k in item.get("keywords", []) or []:
            s = fuzzy_match(query, k, fuzzy)
            if s > best:
                best = s
    return best


def search_settings(data: list[dict], query: str, fuzzy: bool) -> list[dict]:
    if not query:
        return []

    query_re, query, _err = parse_regex_query(query)

    results: list[tuple[int, dict]] = []

    def recurse(items: list[dict]) -> None:
        for item in items:
            best = _score_setting(query_re, query, item, fuzzy)
            if best > 0:
                m = item.copy()
                m["_score"] = best
                results.append((best, m))
            if item.get("type") == "menu" and isinstance(item.get("value"), list):
                recurse(item["value"])

    recurse(data)

    results.sort(key=lambda x: x[0], reverse=True)
    return [m for _, m in results if m.get("label")]


# ─── Calculator ──────────────────────────────────────────────────────────────

_CALC_ALLOWED_CHARS = set("0123456789+-*/().% abcdefghijklmnopqrstuvwxyz")
_CALC_SAFE_NAMES = {
    "sqrt": math.sqrt,
    "sin": math.sin,
    "cos": math.cos,
    "tan": math.tan,
    "log": math.log,
    "pi": math.pi,
    "e": math.e,
    "pow": pow,
    "abs": abs,
}


def calculate(expr: str) -> list[dict]:
    try:
        clean = expr.lower().strip()
        if not all(c in _CALC_ALLOWED_CHARS for c in clean):
            return [{"label": "Invalid characters", "type": "info"}]
        result = eval(clean, {"__builtins__": {}}, _CALC_SAFE_NAMES)  # noqa: S307
        if isinstance(result, float):
            result = round(result, 4)
        return [{
            "label": "= " + str(result),
            "description": str(result),
            "category": "calc_result",
            "type": "exec",
            "value": ["wl-copy", str(result).strip()],
        }]
    except Exception as e:
        return [{
            "label": "No result",
            "description": str(e),
            "type": "exec",
            "value": [""],
        }]


# ─── Web search ──────────────────────────────────────────────────────────────

_URL_HTTPS_RE = re.compile(r"^(https?://|www\.)")
_URL_BARE_RE = re.compile(r"^[a-z0-9.-]+\.[a-z]{2,6}(/.*)?$")


def is_url(query: str) -> bool:
    q = query.strip().lower()
    return bool(_URL_HTTPS_RE.match(q) or _URL_BARE_RE.match(q))


def select_web(query: str) -> None:
    q = query.strip()
    if is_url(q):
        url = q if q.startswith("http") else "https://" + q
    else:
        url = "https://www.google.com/search?q=" + q.replace(" ", "+")
    subprocess.Popen(["xdg-open", url], start_new_session=True)


# ─── File index (cached filesystem scan) ─────────────────────────────────────
#
# On startup: load the previous file_cache.json into memory, then kick
# off a background `fd` run to refresh. The cache is the fallback while
# the refresh is in flight.
#
# On `r` tag: same thing — kick off a background refresh, swap in place.

def load_file_cache() -> list[str]:
    try:
        with open(FILE_CACHE_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def save_file_cache(paths: list[str]) -> None:
    tmp = FILE_CACHE_FILE.with_suffix(".json.tmp")
    with open(tmp, "w") as f:
        json.dump(paths, f)
    tmp.rename(FILE_CACHE_FILE)


def rescan_files() -> list[str]:
    """Run `fd` and return the new path list. Raises if fd is missing."""
    proc = subprocess.run(FD_CMD, capture_output=True, text=True, timeout=120)
    out = proc.stdout.strip()
    return out.split("\n") if out else []


# ─── Async file search with cancellation ─────────────────────────────────────
#
# Every file search gets a generation id. The worker captures the id at
# start; before emitting its result, it checks if its id is still the
# latest. If a newer search has started, the old worker silently discards.
#
# This is the cancellation mechanism: we don't try to interrupt the
# worker thread (which is hard in Python), we just ignore its result.

def _emit_combined(base_result: list[dict], file_results: list[dict]) -> None:
    """Print the combined result list as a single JSON line."""
    print(json.dumps([*base_result, *file_results]))
    sys.stdout.flush()


def _file_search_worker(
    paths_snapshot: list[str],
    query: str,
    generation: int,
    base_result: list[dict],
) -> None:
    """Runs in a background thread. Discards result if superseded."""
    if not query:
        return

    # Detect regex mode. In worker threads, regex matching has no
    # SIGALRM timeout protection — see compile_regex/regex_match for
    # why. The generation counter ensures a slow worker's output is
    # discarded if the user types again.
    query_re, plain_query, err = parse_regex_query(query)
    if err:
        return  # invalid regex — no file results, just emit base
    plain_query_lower = plain_query.lower() if plain_query else ""

    local_results: list[dict] = []
    for path in paths_snapshot:
        name = os.path.basename(path[:-1] if path.endswith("/") else path)

        if query_re is not None:
            # Regex mode — search() returns None on no match, which is falsy.
            if not query_re.search(name) and not query_re.search(path):
                continue
        else:
            # Plain substring mode — cheap check first.
            if (plain_query_lower not in name.lower()
                    and plain_query_lower not in path.lower()):
                continue

        try:
            is_dir = os.path.isdir(path)
        except OSError:
            is_dir = False
        local_results.append({
            "id": path,
            "label": name,
            "description": path,
            "icon": "",
            "category": "files",
            "value": path,
            "type": "dir" if is_dir else "file",
        })
        if len(local_results) >= 50:
            break

    # Generation check — if a newer search has started, discard.
    with _file_search_lock:
        if generation != _file_search_generation:
            return
    _emit_combined(base_result, local_results)


def start_file_search(
    paths_snapshot: list[str],
    query: str,
    base_result: list[dict],
) -> None:
    """Bump generation, start a fresh worker. Old workers will self-cancel."""
    global _file_search_generation
    with _file_search_lock:
        _file_search_generation += 1
        gen = _file_search_generation
    t = threading.Thread(
        target=_file_search_worker,
        args=(paths_snapshot, query, gen, base_result),
        daemon=True,
    )
    t.start()


# ─── Input parsing ───────────────────────────────────────────────────────────
#
# Input format:  -<tags> [--<path_id> ...] <query>
# Examples:
#   -a firefox            → tags=['a'], query='firefox'
#   -ash matrix           → tags=['a','s','h'], query='matrix'
#   -s --network wifi     → tags=['s'], paths=['network'], query='wifi'
#   -F firefox            → tags=['F'], treat query as app id
#   -a re:^fire           → tags=['a'], query='re:^fire' (regex mode)

_TAG_RE = re.compile(r"(?<!\S)-([a-zA-Z]+)\b")
_PATH_RE = re.compile(r"--(\w+)")


def parse_input(raw: str) -> tuple[list[str], str, list[str]]:
    """Return (tag_chars, query, path_ids)."""
    tag_match = _TAG_RE.search(raw)
    tags: list[str] = list(tag_match.group(1)) if tag_match else []

    paths = _PATH_RE.findall(raw)

    query = _TAG_RE.sub("", raw)
    query = _PATH_RE.sub("", query)
    query = " ".join(query.split())

    return tags, query, paths


# ─── Background refresh ──────────────────────────────────────────────────────
#
# Builds new app list, icon index, and file path list in local variables,
# then swaps them into the globals in one step. Readers see either the
# old set or the new set, never a mix.
#
# After the swap, signals the main loop to re-emit the user's most
# recent search so the UI picks up the new data without the user
# needing to retype.

def refresh_background(initial: bool = False) -> None:
    """Rescan apps + icons + files. Swaps into globals atomically when done."""
    global apps, icon_index, file_paths

    start = time.perf_counter()

    # ── Apps + icons (CPU-bound, fast — ~200ms typical) ──
    new_apps = scan_apps()
    new_icon_index = build_icon_index()
    save_icon_cache(new_icon_index)

    # ── Files (slow — fd can take 5-30s on a big system) ──
    try:
        new_files = rescan_files()
        save_file_cache(new_files)
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        print(f"launcher: file rescan failed: {e}", file=sys.stderr)
        new_files = file_paths  # keep old on failure

    # ── Atomic swap ──
    apps = new_apps
    icon_index = new_icon_index
    file_paths = new_files

    elapsed = time.perf_counter() - start
    print(
        f"launcher: refresh done ({elapsed:.2f}s) "
        f"— {len(apps)} apps, {len(icon_index)} icons, {len(file_paths)} files",
        file=sys.stderr,
    )

    # Signal the main loop to re-emit the last search (if any) with
    # the new data. If no search has been issued yet (e.g. startup
    # refresh), this is a no-op.
    _rerun_requested.set()


def refresh_async(initial: bool = False) -> None:
    """Kick off refresh in a background thread. Non-blocking."""
    t = threading.Thread(target=refresh_background, args=(initial,), daemon=True)
    t.start()


# ─── Initial load ────────────────────────────────────────────────────────────

def initial_load() -> None:
    """Load caches from disk synchronously, then kick off async refresh."""
    global apps, icon_index, file_paths, frequency

    frequency = load_frequency()
    icon_index = load_icon_cache()
    apps = scan_apps()
    file_paths = load_file_cache()
    refresh_async(initial=True)


# ─── Search request handling ─────────────────────────────────────────────────

def handle_request(tags: list[str], query: str, paths: list[str]) -> None:
    """Process one search request. May emit zero, one, or two JSON lines.

    Note: this function does NOT update _last_search. The caller is
    responsible for snapshotting the request before calling, so that
    the rerun mechanism can re-emit it after a refresh.
    """
    if not tags:
        print("Error: Please add at least a tag!", file=sys.stderr)
        return

    fuzzy = "f" in tags

    # ── Action tags (side-effects, no search output) ──
    if "F" in tags:
        increment_frequency(query)
        return
    if "w" in tags:
        select_web(query)
        return
    if "r" in tags:
        print("launcher: refresh requested", file=sys.stderr)
        refresh_async()
        return

    # ── Settings: drill into menu if a path id is specified ──
    settings = SETTINGS
    if paths:
        for path_id in paths:
            for setting in settings:
                if setting.get("id") == path_id and setting.get("type") == "menu":
                    settings = setting["value"]
                    if "s" not in tags:
                        tags.append("s")
                    break

    # ── Calculator (replaces result entirely) ──
    if "c" in tags:
        result = [*calculate(query), *CALC] if query else CALC
        print(json.dumps(result))
        sys.stdout.flush()
        return

    # ── Colors (replaces result entirely) ──
    if "t" in tags:
        print(json.dumps(COLORS))
        sys.stdout.flush()
        return

    # ── Regex validation (single check, all categories) ──
    # If the query is `re:<pattern>` and the pattern is invalid, surface
    # ONE error entry to the UI and skip all category searches. Without
    # this, search_apps and search_settings would each independently
    # detect the error and return their own copy, producing duplicates.
    is_regex = query.startswith("re:")
    if is_regex:
        pattern = query[3:]
        compiled = compile_regex(pattern)
        if compiled is None:
            print(json.dumps(regex_error_result(f"Invalid regex: /{pattern}/")))
            sys.stdout.flush()
            return

    # ── Search categories: apps, settings, files ──
    scored_results: list[tuple[int, dict]] = []

    if "a" in tags:
        if query:
            for item in search_apps(apps, query, fuzzy):
                scored_results.append((1000 + frequency.get(item["id"], 0), item))
        else:
            for app in sorted(apps, key=lambda a: frequency.get(a["id"], 0), reverse=True):
                scored_results.append((frequency.get(app["id"], 0), {
                    "id": app["id"],
                    "label": app["name"],
                    "description": app["genericName"] or app["description"],
                    "category": "app",
                    "icon": app["icon"],
                    "value": ["bash", "-c", app["exec_clean"]],
                    "type": "exec",
                }))

    if "s" in tags:
        if query:
            for item in search_settings(settings, query, fuzzy):
                s = item.pop("_score", 0)
                scored_results.append((s, item))
        else:
            for item in settings:
                if item.get("label"):
                    scored_results.append((0, item))

    # Sort combined apps+settings by score (descending).
    scored_results.sort(key=lambda x: x[0], reverse=True)
    base_result = [item for _, item in scored_results]

    # ── File search: async, non-blocking ──
    if "h" in tags:
        # Emit base result immediately so the UI shows apps+settings now.
        print(json.dumps(base_result))
        sys.stdout.flush()
        if query and file_paths:
            start_file_search(file_paths, query, base_result)
    else:
        print(json.dumps(base_result))
        sys.stdout.flush()


# ─── Main loop ───────────────────────────────────────────────────────────────
#
# Two-thread model:
#   - stdin reader thread: blocks on sys.stdin, puts lines in _input_queue
#   - main thread: drains _input_queue with a 100ms timeout. When the
#     timeout fires (no input), checks _rerun_requested — if a refresh
#     just finished, re-emits the last search so the UI picks up new data.
#
# This lets the main thread react to refresh completion even when the
# user isn't typing, without busy-polling stdin (which would burn CPU).

def _stdin_reader() -> None:
    """Background thread: reads stdin lines, puts them in the queue.

    On EOF (Quickshell closed the pipe), puts None as a sentinel so
    the main loop knows to exit cleanly.
    """
    for line in sys.stdin:
        _input_queue.put(line.rstrip("\n"))
    _input_queue.put(None)


def _snapshot_and_handle(tags: list[str], query: str, paths: list[str]) -> None:
    """Record the request as the most recent search, then handle it.

    The snapshot is taken BEFORE handle_request runs, so by the time
    a refresh-completion rerun fires, _last_search already reflects
    whatever the user's most recent query was — not the stale one
    from before the refresh.
    """
    with _last_search_lock:
        _last_search = (tags, query, paths)
    handle_request(tags, query, paths)


def main() -> None:
    # Start the stdin reader thread before initial_load so we don't
    # miss any early inputs (though in practice Quickshell waits for
    # the "launcher: ready" stderr line before sending).
    threading.Thread(target=_stdin_reader, daemon=True).start()

    initial_load()
    print("launcher: ready", file=sys.stderr)

    global _last_search
    while True:
        try:
            # Short timeout so we can check _rerun_requested between inputs.
            # 100ms is fast enough that refresh-rerun feels instant to the
            # user, but slow enough that we're not burning CPU when idle.
            line = _input_queue.get(timeout=0.1)
        except queue.Empty:
            # No new input this tick. Check if a refresh just finished.
            if _rerun_requested.is_set():
                _rerun_requested.clear()
                with _last_search_lock:
                    last = _last_search
                if last:
                    # Re-emit the most recent search with the new data.
                    # Note: we call handle_request directly, NOT
                    # _snapshot_and_handle, because we don't want to
                    # update _last_search — it's already correct.
                    handle_request(*last)
            continue

        if line is None:
            break  # EOF — Quickshell closed stdin, time to exit

        if not line:
            continue

        try:
            tags, query, paths = parse_input(line)
            _snapshot_and_handle(tags, query, paths)
        except Exception as e:
            print(f"launcher: error handling request: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()

