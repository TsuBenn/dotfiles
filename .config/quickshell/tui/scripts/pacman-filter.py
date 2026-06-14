#!/usr/bin/env python3
"""
pacman_backend.py — Structured JSON backend for a pacman UI.
Commands: fetch | list | search <query> [--fresh] | info <pkgname>
"""

import json
import subprocess
import sys
import os
import re
from pathlib import Path
from datetime import datetime

CACHE_DIR  = Path.home() / ".cache" / "pacman-ui"
CACHE_FILE = CACHE_DIR / "cache.json"


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout


def parse_pacman_block(block: str) -> dict:
    """
    Parse one pacman -Qi / -Si info block into a dict.
    Each line looks like:  Key             : value
    Multi-line values are indented with spaces (no colon).
    """
    data = {}
    current_key = None

    for line in block.splitlines():
        # A new key=value line
        match = re.match(r'^([A-Za-z][A-Za-z0-9 ()]+?)\s*:\s*(.*)', line)
        if match:
            current_key = match.group(1).strip()
            data[current_key] = match.group(2).strip()
        elif current_key and line.startswith(" "):
            # Continuation of the previous value
            extra = line.strip()
            if extra:
                data[current_key] += " " + extra

    return data


def split_list_field(value: str) -> list[str]:
    """'None' → []  |  'pkg1  pkg2' → ['pkg1', 'pkg2']"""
    if not value or value.lower() == "none":
        return []
    return [v.strip() for v in re.split(r'\s{2,}|\n', value) if v.strip()]


def parse_optdeps(value: str) -> list[dict]:
    """
    Optional deps look like:  'pkgname: reason  pkgname2: reason2'
    Returns list of {name, reason}.
    """
    if not value or value.lower() == "none":
        return []
    items = []
    for entry in re.split(r'\s{2,}|\n', value):
        entry = entry.strip()
        if not entry:
            continue
        if ":" in entry:
            name, _, reason = entry.partition(":")
            items.append({"name": name.strip(), "reason": reason.strip()})
        else:
            items.append({"name": entry, "reason": ""})
    return items


def annotate_with_installed(pkg_list: list[str], installed_set: set[str]) -> list[dict]:
    return [{"name": p, "installed": p in installed_set} for p in pkg_list]


def annotate_optdeps_with_installed(optdeps: list[dict], installed_set: set[str]) -> list[dict]:
    for dep in optdeps:
        dep["installed"] = dep["name"] in installed_set
    return optdeps


def parse_last_sync_from_log(log_path: str = "/var/log/pacman.log") -> dict[str, dict]:
    """
    Scan pacman.log and return the most recent install/upgrade action per package.
    Example line:
      [2026-05-01T14:23:11+0700] [ALPM] upgraded neovim (0.9.5-1 -> 0.10.0-1)
    """
    last_sync = {}
    pattern = re.compile(
        r'^\[(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[^\]]*)\] \[ALPM\] (installed|upgraded|reinstalled|downgraded) ([^\s(]+)'
    )
    try:
        with open(log_path, "r", errors="replace") as f:
            for line in f:
                m = pattern.match(line)
                if m:
                    timestamp, action, name = m.group(1), m.group(2), m.group(3)
                    # Always overwrite — log is chronological so last match = most recent
                    last_sync[name] = {"timestamp": timestamp, "action": action}
    except FileNotFoundError:
        pass
    return last_sync


def build_package_entry(raw: dict, is_installed: bool, installed_set: set[str]) -> dict:
    """Convert a raw parsed block into our structured schema."""
    deps     = split_list_field(raw.get("Depends On", ""))
    optdeps  = parse_optdeps(raw.get("Optional Deps", ""))
    makedeps = split_list_field(raw.get("Make Deps", ""))
    checkdeps= split_list_field(raw.get("Check Deps", ""))

    entry = {
        # Identity
        "name":         raw.get("Name", ""),
        "version":      raw.get("Version", ""),
        "description":  raw.get("Description", ""),
        "url":          raw.get("URL", ""),
        "licenses":     split_list_field(raw.get("Licenses", "")),

        # Source info
        "repository":   raw.get("Repository", ""),
        "groups":       split_list_field(raw.get("Groups", "")),
        "arch":         raw.get("Architecture", ""),

        # Sizes (raw strings from pacman, e.g. "12.34 MiB")
        "download_size":  raw.get("Download Size", ""),
        "installed_size": raw.get("Installed Size", ""),

        # Maintainer
        "packager":     raw.get("Packager", ""),
        "build_date":   raw.get("Build Date", ""),

        # Status
        "installed":    is_installed,

        # Installed-only fields (empty when not installed)
        "install_date":     raw.get("Install Date", ""),
        "install_reason":   raw.get("Install Reason", ""),
        "install_script":   raw.get("Install Script", ""),
        "validated_by":     raw.get("Validated By", ""),

        # Dependencies — each annotated with whether it's currently installed
        "depends":          annotate_with_installed(deps, installed_set),
        "optional_deps":    annotate_optdeps_with_installed(optdeps, installed_set),
        "make_deps":        annotate_with_installed(makedeps, installed_set),
        "check_deps":       annotate_with_installed(checkdeps, installed_set),

        # Reverse deps (installed-only)
        "required_by":      split_list_field(raw.get("Required By", "")),
        "optional_for":     split_list_field(raw.get("Optional For", "")),

        # Conflicts / replaces / provides
        "conflicts_with":   split_list_field(raw.get("Conflicts With", "")),
        "replaces":         split_list_field(raw.get("Replaces", "")),
        "provides":         split_list_field(raw.get("Provides", "")),
    }
    return entry


# ─────────────────────────────────────────────
# FETCH
# ─────────────────────────────────────────────

def cmd_fetch():
    print("→ Getting list of installed packages...", flush=True)
    installed_raw = run(["pacman", "-Qq"])
    installed_set = set(installed_raw.split())

    packages = {}

    # ── Installed packages (pacman -Qi) ──────────────────────────────────
    print("→ Fetching details for installed packages (pacman -Qi)...", flush=True)
    qi_output = run(["pacman", "-Qi"])
    qi_blocks  = re.split(r'\n(?=Name\s+:)', qi_output.strip())

    for block in qi_blocks:
        raw = parse_pacman_block(block)
        name = raw.get("Name", "").strip()
        if not name:
            continue
        packages[name] = build_package_entry(raw, is_installed=True, installed_set=installed_set)

    print(f"   ✓ {len(packages)} installed packages processed.", flush=True)

    # ── Repo packages (pacman -Si) ────────────────────────────────────────
    print("→ Fetching details for all repo packages (pacman -Si)...", flush=True)
    si_output = run(["pacman", "-Si"])
    si_blocks  = re.split(r'\n(?=Repository\s+:)', si_output.strip())

    new_count = 0
    for block in si_blocks:
        raw  = parse_pacman_block(block)
        name = raw.get("Name", "").strip()
        if not name:
            continue
        if name in packages:
            # Already have full -Qi data; just add repo/size fields if missing
            if not packages[name].get("repository"):
                packages[name]["repository"] = raw.get("Repository", "")
            if not packages[name].get("download_size"):
                packages[name]["download_size"] = raw.get("Download Size", "")
        else:
            packages[name] = build_package_entry(raw, is_installed=False, installed_set=installed_set)
            new_count += 1

    print(f"   ✓ {new_count} additional repo packages processed.", flush=True)

    # ── Last sync from pacman.log ─────────────────────────────────────────
    print("→ Parsing pacman.log for last sync times...", flush=True)
    last_sync_map = parse_last_sync_from_log()
    for name, pkg in packages.items():
        pkg["last_sync"] = last_sync_map.get(name)  # None if never touched

    synced = sum(1 for p in packages.values() if p["last_sync"])
    print(f"   ✓ {synced} packages have a recorded sync.", flush=True)

    # ── Write cache ───────────────────────────────────────────────────────
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache = {
        "fetched_at": datetime.now().isoformat(),
        "packages":   packages,
    }
    with open(CACHE_FILE, "w") as f:
        json.dump(cache, f, indent=2)

    total = len(packages)
    inst  = sum(1 for p in packages.values() if p["installed"])
    print(f"✓ Cache saved → {CACHE_FILE}")
    print(f"  Total: {total} packages  |  Installed: {inst}  |  Not installed: {total - inst}")


# ─────────────────────────────────────────────
# LOAD CACHE (shared by list / search / info)
# ─────────────────────────────────────────────

def load_cache() -> dict:
    if not CACHE_FILE.exists():
        print("✗ Cache not found. Run:  pacman_backend.py fetch", file=sys.stderr)
        sys.exit(1)
    with open(CACHE_FILE) as f:
        return json.load(f)


# ─────────────────────────────────────────────
# LIST
# ─────────────────────────────────────────────

def cmd_list():
    cache    = load_cache()
    packages = cache["packages"]

    result = [
        {
            "name":        name,
            "real_name":   pkg["name"],
            "description": pkg["description"],
            "version":     pkg["version"],
            "repository":  pkg["repository"],
            "last_sync":   pkg["last_sync"],
        }
        for name, pkg in packages.items()
        if pkg["installed"]
    ]

    result.sort(key=lambda p: p["name"])
    print(json.dumps(result, indent=2))


# ─────────────────────────────────────────────
# SEARCH
# ─────────────────────────────────────────────

def cmd_search(query: str, fresh: bool = False):
    if fresh:
        print("→ --fresh requested, re-fetching cache...", flush=True)
        cmd_fetch()

    cache    = load_cache()
    packages = cache["packages"]
    q        = query.lower()

    result = [
        {
            "name":        name,
            "real_name":   pkg["name"],
            "description": pkg["description"],
            "version":     pkg["version"],
            "repository":  pkg["repository"],
            "installed":   pkg["installed"],
            "last_sync":   pkg["last_sync"],
        }
        for name, pkg in packages.items()
        if q in name.lower() or q in pkg["description"].lower()
    ]

    result.sort(key=lambda p: (not p["installed"], p["name"]))
    print(json.dumps(result, indent=2))


# ─────────────────────────────────────────────
# INFO
# ─────────────────────────────────────────────

def cmd_info(pkgname: str):
    cache    = load_cache()
    packages = cache["packages"]

    pkg = packages.get(pkgname)
    if not pkg:
        print(json.dumps({"error": f"Package '{pkgname}' not found in cache."}))
        sys.exit(1)

    print(json.dumps(pkg, indent=2))


# ─────────────────────────────────────────────
# Entrypoint
# ─────────────────────────────────────────────

def main():
    args = sys.argv[1:]

    if not args:
        print("Usage:")
        print("  pacman_backend.py fetch")
        print("  pacman_backend.py list")
        print("  pacman_backend.py search <query> [--fresh]")
        print("  pacman_backend.py info <pkgname>")
        sys.exit(0)

    cmd = args[0]

    if cmd == "fetch":
        cmd_fetch()

    elif cmd == "list":
        cmd_list()

    elif cmd == "search":
        if len(args) < 2:
            print("✗ search requires a query.  e.g.  pacman_backend.py search firefox", file=sys.stderr)
            sys.exit(1)
        query = args[1]
        fresh = "--fresh" in args
        cmd_search(query, fresh=fresh)

    elif cmd == "info":
        if len(args) < 2:
            print("✗ info requires a package name.  e.g.  pacman_backend.py info neovim", file=sys.stderr)
            sys.exit(1)
        cmd_info(args[1])

    else:
        print(f"✗ Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
