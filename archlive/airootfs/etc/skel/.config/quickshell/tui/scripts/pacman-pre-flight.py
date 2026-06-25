#!/usr/bin/env python3
"""
pacman-preflight.py — Compute the pre-flight transaction plan for one or
more packages.

Reads the pacman-filter.py cache, runs `pacman -S --print` for the
authoritative to-install list, cross-references the cache for
replaces/conflicts/installed-sizes, and uses `vercmp` for version
constraint checking.

Input:  one or more package names as argv[1:]
Output: one indented JSON document on stdout (for easy debugging),
        OR an error object if anything fails.

Usage:
  python pacman-preflight.py <package1> [<package2> [<package3> ...]]

Examples:
  python pacman-preflight.py firefox
  python pacman-preflight.py vlc firefox
  python pacman-preflight.py base-devel gcc make

Exits 0 on success, 1 on error (error details in the JSON output).
"""

from __future__ import annotations

import json
import math
import os
import re
import subprocess
import sys
from pathlib import Path

# ─── Paths ────────────────────────────────────────────────────────────────────

CACHE_FILE = Path.home() / ".cache" / "pacman-ui" / "cache.json"

# ─── vercmp ───────────────────────────────────────────────────────────────────

try:
    import pyalpm
    def vercmp(a: str, b: str) -> int:
        return pyalpm.vercmp(a, b)
except ImportError:
    def vercmp(a: str, b: str) -> int:
        try:
            r = subprocess.run(
                ["vercmp", a, b],
                capture_output=True, text=True, timeout=5,
            )
            return int(r.stdout.strip() or "0")
        except (subprocess.SubprocessError, ValueError):
            return 0


# ─── Helpers ──────────────────────────────────────────────────────────────────

def load_cache() -> dict:
    if not CACHE_FILE.exists():
        return {"packages": []}
    try:
        with open(CACHE_FILE) as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return {"packages": []}


def run_pacman_print(targets: list[str]) -> tuple[list[dict] | None, str]:
    """Run `pacman -S --print --print-format "%n|%v|%s" <targets...>`.

    pacman accepts multiple package names in a single -S invocation and
    resolves them as one combined transaction. This is the authoritative
    to-install list — includes transitive deps, version resolution,
    provides handling, etc.

    Returns (list_of_entries, error_message). On success, error_message
    is empty. On failure, list_of_entries is None.

    Each entry: {name, version, downloadBytes}
    """
    cmd = ["pacman", "-S", "--print", "--print-format", "%n|%v|%s"] + targets
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    except subprocess.TimeoutExpired:
        return None, "pacman -S --print timed out"
    except FileNotFoundError:
        return None, "pacman binary not found"

    if proc.returncode != 0:
        return None, proc.stderr.strip() or f"pacman exited with code {proc.returncode}"

    out: list[dict] = []
    for line in proc.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split("|")
        if len(parts) < 3:
            continue
        name, version, size_str = parts[0], parts[1], parts[2]
        try:
            size_bytes = int(size_str)
        except ValueError:
            size_bytes = 0
        out.append({
            "name": name,
            "version": version,
            "downloadBytes": size_bytes,
        })
    return out, ""


# ─── Version constraint parsing ───────────────────────────────────────────────

_OPS_ORDERED = ["<=", ">=", "<", ">", "="]


def split_name_version(s: str) -> tuple[str, str, str]:
    for op in _OPS_ORDERED:
        idx = s.find(op)
        if idx >= 0:
            return s[:idx], op, s[idx + len(op):]
    return s, "", ""


def version_satisfies(installed_version: str, op: str, required_version: str) -> bool:
    if not op or not required_version:
        return True
    if not installed_version:
        return False
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


# ─── Size formatting ─────────────────────────────────────────────────────────

_SIZE_RE = re.compile(r"^([\d.]+)\s*(b|kib|kb|k|mib|mb|m|gib|gb|g|tib|tb|t|pib|pb|p)?$", re.I)
_SIZE_MULTIPLIERS = {
    "b": 1,
    "k": 1024, "kib": 1024, "kb": 1024,
    "m": 1024**2, "mib": 1024**2, "mb": 1024**2,
    "g": 1024**3, "gib": 1024**3, "gb": 1024**3,
    "t": 1024**4, "tib": 1024**4, "tb": 1024**4,
    "p": 1024**5, "pib": 1024**5, "pb": 1024**5,
}
_SIZE_UNITS = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]


def parse_size_to_bytes(s: str) -> int:
    if not s:
        return 0
    m = _SIZE_RE.match(s.strip())
    if not m:
        return 0
    try:
        value = float(m.group(1))
    except ValueError:
        return 0
    unit = (m.group(2) or "b").lower()
    return int(value * _SIZE_MULTIPLIERS.get(unit, 1))


def format_bytes(b: int) -> str:
    if b == 0:
        return "0 B"
    if b < 0:
        return ""
    k = 1024
    i = min(int(math.log(b) / math.log(k)), len(_SIZE_UNITS) - 1)
    if i == 0:
        return f"{b} B"
    return f"{b / k**i:.1f} {_SIZE_UNITS[i]}"


# ─── Pre-flight plan builder ─────────────────────────────────────────────────

def build_preflight(
    targets: set[str],
    cache_packages: list[dict],
    print_output: list[dict],
) -> dict:
    """Build the pre-flight plan for one or more target packages.

    Args:
        targets: set of package names the user requested to install.
                 Used to mark isTarget on the matching entries in toInstall.
        cache_packages: list of package dicts from pacman-filter.py cache.
        print_output: list of {name, version, downloadBytes} from
                      `pacman -S --print`.

    Returns:
        {
            toInstall:        [{name, version, downloadBytes, downloadSize,
                                installedBytes, installedSize, isTarget}],
            willReplace:      [{name, version, installed}],
            conflictsWith:    [{name, version, installed, conflictsWith}],
            totalDownload:    "10.3 MiB",
            totalInstalled:   "43.9 MiB",
        }
    """
    packages_by_name: dict[str, dict] = {
        p["name"]: p for p in cache_packages if "name" in p
    }

    # ── toInstall ──
    to_install: list[dict] = []
    total_download_bytes = 0
    total_installed_bytes = 0

    for entry in print_output:
        name = entry["name"]
        version = entry["version"]
        download_bytes = entry["downloadBytes"]
        total_download_bytes += download_bytes

        cached = packages_by_name.get(name)
        if cached:
            installed_size_str = cached.get("installed_size", "")
            installed_bytes = parse_size_to_bytes(installed_size_str)
        else:
            installed_bytes = 0
        total_installed_bytes += installed_bytes

        to_install.append({
            "name": name,
            "version": version,
            "downloadBytes": download_bytes,
            "downloadSize": format_bytes(download_bytes),
            "installedBytes": installed_bytes,
            "installedSize": format_bytes(installed_bytes) if cached else "—",
            # isTarget is true for ANY package the user explicitly requested.
            # Dependencies pulled in by pacman are NOT targets.
            "isTarget": name in targets,
        })

    # ── willReplace ──
    will_replace: list[dict] = []
    seen_replaces: set[str] = set()

    for entry in print_output:
        pkg_name = entry["name"]
        cached = packages_by_name.get(pkg_name)
        if not cached:
            continue

        for rep in cached.get("replaces", []) or []:
            rep_name, op, req_version = split_name_version(rep)
            if rep_name in seen_replaces:
                continue

            rep_cached = packages_by_name.get(rep_name)
            if not rep_cached or not rep_cached.get("installed"):
                continue

            installed_version = rep_cached.get("version", "")
            if not version_satisfies(installed_version, op, req_version):
                continue

            will_replace.append({
                "name": rep_name,
                "version": installed_version,
                "installed": True,
            })
            seen_replaces.add(rep_name)

    # ── conflictsWith ──
    conflicts_with: list[dict] = []
    seen_conflicts: set[str] = set()

    to_install_names = {e["name"] for e in print_output}
    to_install_versions = {e["name"]: e["version"] for e in print_output}

    # Direction 1: to-install packages declare conflicts
    for entry in print_output:
        pkg_name = entry["name"]
        cached = packages_by_name.get(pkg_name)
        if not cached:
            continue

        for con in cached.get("conflicts_with", []) or []:
            con_name, op, req_version = split_name_version(con)
            if con_name in seen_conflicts or con_name in seen_replaces:
                continue

            con_cached = packages_by_name.get(con_name)
            if not con_cached or not con_cached.get("installed"):
                continue

            installed_version = con_cached.get("version", "")
            if not version_satisfies(installed_version, op, req_version):
                continue

            conflicts_with.append({
                "name": con_name,
                "version": installed_version,
                "installed": True,
                "conflictsWith": pkg_name,
            })
            seen_conflicts.add(con_name)

    # Direction 2: installed packages declare conflicts targeting our to-install set
    for pkg in cache_packages:
        if not pkg.get("installed"):
            continue
        pkg_name = pkg.get("name", "")
        if pkg_name in seen_conflicts or pkg_name in seen_replaces:
            continue

        for con in pkg.get("conflicts_with", []) or []:
            con_name, op, req_version = split_name_version(con)
            if con_name not in to_install_names:
                continue

            to_install_version = to_install_versions.get(con_name, "")
            if not version_satisfies(to_install_version, op, req_version):
                continue

            conflicts_with.append({
                "name": pkg_name,
                "version": pkg.get("version", ""),
                "installed": True,
                "conflictsWith": con_name,
            })
            seen_conflicts.add(pkg_name)
            break

    return {
        "toInstall": to_install,
        "willReplace": will_replace,
        "conflictsWith": conflicts_with,
        "totalDownload": format_bytes(total_download_bytes),
        "totalInstalled": format_bytes(total_installed_bytes),
    }


# ─── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    targets_list = [arg.strip() for arg in sys.argv[1:] if arg.strip()]

    if not targets_list:
        print(json.dumps({"error": "missing package name(s)"}, indent=2))
        sys.exit(1)

    targets_set = set(targets_list)

    cache = load_cache()
    cache_packages = cache.get("packages", [])
    if isinstance(cache_packages, dict):
        cache_packages = list(cache_packages.values())

    if not cache_packages:
        print(json.dumps({
            "error": "cache is empty — run refresh first",
        }, indent=2))
        sys.exit(1)

    print_output, err = run_pacman_print(targets_list)
    if print_output is None:
        print(json.dumps({
            "error": f"pacman -S --print failed: {err}",
            "targets": targets_list,
        }, indent=2))
        sys.exit(1)

    if not print_output:
        print(json.dumps({
            "error": f"no transaction for {', '.join(targets_list)} (already installed or not found)",
            "targets": targets_list,
        }, indent=2))
        sys.exit(1)

    plan = build_preflight(targets_set, cache_packages, print_output)

    print(json.dumps(plan, indent=2))


if __name__ == "__main__":
    main()

