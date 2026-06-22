#!/usr/bin/env python3
"""
pacman-preflight.py — Compute the pre-flight transaction plan for a package.

Reads the pacman-filter.py cache, runs `pacman -S --print` for the
authoritative to-install list, cross-references the cache for
replaces/conflicts/installed-sizes, and uses `vercmp` for version
constraint checking.

Input:  package name as argv[1]
Output: one indented JSON document on stdout (for easy debugging),
        OR an error object if anything fails.

Usage:  python pacman-preflight.py <package_name>

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
#
# Use pyalpm if available (no process spawn per comparison). Fall back
# to the `vercmp` binary that ships with pacman.

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
    """Load the pacman-filter.py cache. Returns {} on missing/corrupt."""
    if not CACHE_FILE.exists():
        return {"packages": []}
    try:
        with open(CACHE_FILE) as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return {"packages": []}


def run_pacman_print(pkg: str) -> tuple[list[dict] | None, str]:
    """Run `pacman -S --print --print-format "%n|%v|%s" <pkg>`.

    Returns (list_of_entries, error_message). On success, error_message
    is empty. On failure, list_of_entries is None.

    Each entry: {name, version, downloadBytes}
    """
    cmd = ["pacman", "-S", "--print", "--print-format", "%n|%v|%s", pkg]
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
    """Split 'plasma-integration<=5.27.0' → ('plasma-integration', '<=', '5.27.0').

    Operator order matters: check '<=' before '<' (since '<' is a prefix of '<='),
    and '>=' before '>'. '=' is checked last because it's a single char and the
    others would never match if '=' came first.

    Returns (name, op, version). If no operator, returns (s, "", "").
    """
    for op in _OPS_ORDERED:
        idx = s.find(op)
        if idx >= 0:
            return s[:idx], op, s[idx + len(op):]
    return s, "", ""


def version_satisfies(installed_version: str, op: str, required_version: str) -> bool:
    """Check if installed_version satisfies the (op, required_version) constraint.

    If op is empty (no constraint), always returns True.
    If installed_version is empty (unknown), returns False — better to
    under-report a replace/conflict than to fire it incorrectly.
    """
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
#
# Parse "22.29 MiB" → bytes (int), and format bytes → "22.3 MiB".
# Uses 1024-based binary prefixes to match pacman's convention.
#
# IMPORTANT: We always format sizes ourselves via format_bytes() rather
# than passing through the raw string from the cache. Pacman is
# inconsistent about which unit it uses (KiB vs MiB vs GiB) — some
# packages show "15675.04 KiB" when they should show "15.3 MiB".
# By formatting from the byte count, we ensure consistent unit selection.

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
    """Parse '22.29 MiB' → 23343390 (int). Returns 0 on parse failure."""
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
    """Format 23343390 → '22.3 MiB'. Returns '0 B' for zero, '' for negative.

    Always picks the most appropriate unit based on the byte count,
    regardless of what unit the source data used. This ensures
    consistent formatting — no '15675.04 KiB' when it should be '15.3 MiB'.
    """
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
    target: str,
    cache_packages: list[dict],
    print_output: list[dict],
) -> dict:
    """Build the pre-flight plan.

    Args:
        target: the package the user is installing
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

    # ─────────────────────────────────────────────────────────────────
    # toInstall — from --print (authoritative)
    # ─────────────────────────────────────────────────────────────────
    to_install: list[dict] = []
    total_download_bytes = 0
    total_installed_bytes = 0

    for entry in print_output:
        name = entry["name"]
        version = entry["version"]
        download_bytes = entry["downloadBytes"]
        total_download_bytes += download_bytes

        # Look up installed size from cache. If the package isn't in the
        # cache (brand-new, not yet cached), fall back to 0 bytes / "—".
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
            # Format installed size ourselves — don't pass through the
            # raw cache string. Pacman is inconsistent about units
            # (sometimes KiB when it should be MiB), so we always
            # format from the byte count for consistency.
            "installedSize": format_bytes(installed_bytes) if cached else "—",
            "isTarget": name == target,
        })

    # ─────────────────────────────────────────────────────────────────
    # willReplace — from each to-install package's `replaces` field,
    # checked against installed packages with version constraints.
    # ─────────────────────────────────────────────────────────────────
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

            # Version constraint check
            installed_version = rep_cached.get("version", "")
            if not version_satisfies(installed_version, op, req_version):
                continue

            will_replace.append({
                "name": rep_name,
                "version": installed_version,
                "installed": True,
            })
            seen_replaces.add(rep_name)

    # ─────────────────────────────────────────────────────────────────
    # conflictsWith — two directions:
    #   1. Each to-install package's `conflicts_with` against installed.
    #   2. Each installed package's `conflicts_with` against to-install.
    # Skip any that are already in will_replace (replaces takes precedence).
    # ─────────────────────────────────────────────────────────────────
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

            # Constraint is on the INSTALLED package's version
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

            # Constraint is on the TO-INSTALL package's version
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
            break  # this installed package is already counted; move on

    return {
        "toInstall": to_install,
        "willReplace": will_replace,
        "conflictsWith": conflicts_with,
        "totalDownload": format_bytes(total_download_bytes),
        "totalInstalled": format_bytes(total_installed_bytes),
    }


# ─── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print(json.dumps({"error": "missing package name argument"}, indent=2))
        sys.exit(1)

    target = sys.argv[1].strip()
    if not target:
        print(json.dumps({"error": "empty package name"}, indent=2))
        sys.exit(1)

    cache = load_cache()
    cache_packages = cache.get("packages", [])
    if isinstance(cache_packages, dict):
        cache_packages = list(cache_packages.values())

    if not cache_packages:
        print(json.dumps({
            "error": "cache is empty — run refresh first",
        }, indent=2))
        sys.exit(1)

    print_output, err = run_pacman_print(target)
    if print_output is None:
        print(json.dumps({
            "error": f"pacman -S --print failed: {err}",
            "target": target,
        }, indent=2))
        sys.exit(1)

    if not print_output:
        print(json.dumps({
            "error": f"no transaction for {target} (already installed or not found)",
            "target": target,
        }, indent=2))
        sys.exit(1)

    plan = build_preflight(target, cache_packages, print_output)

    # Indented JSON for easier debugging from the command line.
    print(json.dumps(plan, indent=2))


if __name__ == "__main__":
    main()

