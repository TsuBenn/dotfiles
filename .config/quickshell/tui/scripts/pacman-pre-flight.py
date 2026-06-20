#!/usr/bin/env python3
"""
pacman-preflight.py — Compute the pre-flight transaction plan for a package.

Input:  package name as argv[1]
Output: one JSON line on stdout with the plan, OR an error object

Usage:  python pacman-preflight.py <package_name>
"""
import json
import os
import subprocess
import sys
from pathlib import Path

# Optional: use pyalpm for vercmp if available, fall back to vercmp binary
try:
    import pyalpm
    def vercmp(a, b):
        return pyalpm.vercmp(a, b)
except ImportError:
    def vercmp(a, b):
        result = subprocess.run(["vercmp", a, b], capture_output=True, text=True)
        return int(result.stdout.strip() or "0")

CACHE_FILE = Path.home() / ".cache" / "pacman-ui" / "cache.json"

def load_cache():
    if not CACHE_FILE.exists():
        return {"packages": {}}
    with open(CACHE_FILE) as f:
        return json.load(f)

def run_pacman_print(pkg):
    """Run pacman -S --print, return list of (name, version, size_bytes) tuples."""
    cmd = ["pacman", "-S", "--print", "--print-format", "%n|%v|%s", pkg]
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if proc.returncode != 0:
        return None, proc.stderr.strip()
    out = []
    for line in proc.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split("|")
        if len(parts) < 3:
            continue
        out.append({
            "name": parts[0],
            "version": parts[1],
            "downloadBytes": int(parts[2]) if parts[2].isdigit() else 0,
        })
    return out, None

def split_name_version(s):
    """Split 'gcc-libs>=12.1.0' into ('gcc-libs', '>=', '12.1.0')."""
    for op in ["<=", ">=", "<", ">", "="]:
        if op in s:
            name, _, version = s.partition(op)
            return name, op, version
    return s, "", ""

def version_satisfies(installed_version, op, required_version):
    """Check if installed_version satisfies the op/version constraint."""
    if not op or not required_version:
        return True  # no constraint
    cmp = vercmp(installed_version, required_version)
    if op == "=":
        return cmp == 0
    if op == "<=":
        return cmp <= 0
    if op == ">=":
        return cmp >= 0
    if op == "<":
        return cmp < 0
    if op == ">":
        return cmp > 0
    return False

def build_preflight(target, cache_packages, print_output):
    """Build the pre-flight plan from --print output + cache cross-reference."""
    packages_by_name = {p["name"]: p for p in cache_packages}

    # ── toInstall ──
    to_install = []
    total_download_bytes = 0
    total_installed_bytes = 0

    for entry in print_output:
        name = entry["name"]
        version = entry["version"]
        download_bytes = entry["downloadBytes"]
        total_download_bytes += download_bytes

        cached = packages_by_name.get(name)
        installed_bytes = 0
        installed_size_str = ""
        if cached:
            installed_size_str = cached.get("installed_size", "")
            # Parse "22.29 MiB" → bytes
            installed_bytes = parse_size_to_bytes(installed_size_str)

        total_installed_bytes += installed_bytes

        to_install.append({
            "name": name,
            "version": version,
            "downloadBytes": download_bytes,
            "downloadSize": format_bytes(download_bytes),
            "installedBytes": installed_bytes,
            "installedSize": installed_size_str or "—",
            "isTarget": name == target,
        })

    # ── willReplace + conflictsWith ──
    will_replace = []
    conflicts_with = []
    seen_replaces = set()
    seen_conflicts = set()

    target_cached = packages_by_name.get(target)

    # Direct replaces/conflicts from the target and all to-install packages
    for entry in print_output:
        pkg_name = entry["name"]
        cached = packages_by_name.get(pkg_name)
        if not cached:
            continue

        # Replaces
        for rep in cached.get("replaces", []):
            rep_name, _, _ = split_name_version(rep)
            if rep_name in seen_replaces:
                continue
            rep_cached = packages_by_name.get(rep_name)
            if rep_cached and rep_cached.get("installed"):
                will_replace.append({
                    "name": rep_name,
                    "version": rep_cached.get("version", ""),
                    "installed": True,
                })
                seen_replaces.add(rep_name)

        # Conflicts
        for con in cached.get("conflicts_with", []):
            con_name, _, _ = split_name_version(con)
            if con_name in seen_conflicts or con_name in seen_replaces:
                continue
            con_cached = packages_by_name.get(con_name)
            if con_cached and con_cached.get("installed"):
                conflicts_with.append({
                    "name": con_name,
                    "version": con_cached.get("version", ""),
                    "installed": True,
                })
                seen_conflicts.add(con_name)

    # Reverse conflicts: any installed package that conflicts with a to-install pkg
    for pkg in cache_packages:
        if not pkg.get("installed"):
            continue
        for con in pkg.get("conflicts_with", []):
            con_name, _, _ = split_name_version(con)
            # Is this conflict targeting one of our to-install packages?
            to_install_names = {e["name"] for e in print_output}
            if con_name in to_install_names and con_name not in seen_conflicts:
                conflicts_with.append({
                    "name": pkg["name"],
                    "version": pkg.get("version", ""),
                    "installed": True,
                })
                seen_conflicts.add(pkg["name"])

    return {
        "toInstall": to_install,
        "willReplace": will_replace,
        "conflictsWith": conflicts_with,
        "totalDownload": format_bytes(total_download_bytes),
        "totalInstalled": format_bytes(total_installed_bytes),
    }

def parse_size_to_bytes(s):
    """Parse '22.29 MiB' → bytes (int)."""
    if not s:
        return 0
    s = s.strip().lower()
    try:
        import re
        m = re.match(r"^([\d.]+)\s*(b|kib|kb|k|mib|mb|m|gib|gb|g|tib|tb|t)?$", s)
        if not m:
            return 0
        value = float(m.group(1))
        unit = m.group(2) or "b"
        multipliers = {
            "b": 1,
            "k": 1024, "kib": 1024, "kb": 1024,
            "m": 1024**2, "mib": 1024**2, "mb": 1024**2,
            "g": 1024**3, "gib": 1024**3, "gb": 1024**3,
            "t": 1024**4, "tib": 1024**4, "tb": 1024**4,
        }
        return int(value * multipliers.get(unit, 1))
    except (ValueError, AttributeError):
        0
        return 0

def format_bytes(b):
    """Format bytes → '5.4 KiB' etc."""
    if b == 0:
        return "0 B"
    if b < 0:
        return ""
    units = ["B", "KiB", "MiB", "GiB", "TiB"]
    k = 1024
    i = min(int(math.log(b) / math.log(k)), len(units) - 1) if b > 0 else 0
    if i == 0:
        return f"{b} B"
    return f"{b / k**i:.2f} {units[i]}"

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "missing package name"}))
        sys.exit(1)

    target = sys.argv[1]
    cache = load_cache()
    cache_packages = cache.get("packages", [])
    if isinstance(cache_packages, dict):
        # Some cache formats use a dict keyed by name
        cache_packages = list(cache_packages.values())

    print_output, err = run_pacman_print(target)
    if print_output is None:
        print(json.dumps({"error": f"pacman -S --print failed: {err}"}))
        sys.exit(1)

    if not print_output:
        print(json.dumps({"error": f"no transaction for {target} (already installed?)"}))
        sys.exit(1)

    plan = build_preflight(target, cache_packages, print_output)
    print(json.dumps(plan))

if __name__ == "__main__":
    import math
    main()
