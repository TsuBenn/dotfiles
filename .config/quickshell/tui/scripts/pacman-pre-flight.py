#!/usr/bin/env python3
"""
pacman-pre-flight.py — Compute the pre-flight transaction plan for one or
more packages, for either install or remove operations.

Install mode (default):
  python pacman-pre-flight.py <pkg1> [<pkg2> ...]

Remove mode:
  python pacman-pre-flight.py --remove <pkg1> [<pkg2> ...]
  python pacman-pre-flight.py --remove --cascade <pkg1> [<pkg2> ...]

Output: one indented JSON document on stdout (for easy debugging),
        OR an error object if anything fails.

Exits 0 on success, 1 on error (error details in the JSON output).

═══════════════════════════════════════════════════════════════════════════
INSTALL MODE
═══════════════════════════════════════════════════════════════════════════

Reads the pacman-filter.py cache, runs `pacman -S --print` for the
authoritative to-install list, cross-references the cache for
replaces/conflicts/installed-sizes, and uses `vercmp` for version
constraint checking.

Output shape:
  {
    "toInstall":      [{name, version, downloadBytes, downloadSize,
                        installedBytes, installedSize, isTarget}],
    "willReplace":    [{name, version, installed}],
    "conflictsWith":  [{name, version, installed, conflictsWith}],
    "totalDownload":  "10.3 MiB",
    "totalInstalled": "43.9 MiB",
  }

═══════════════════════════════════════════════════════════════════════════
REMOVE MODE
═══════════════════════════════════════════════════════════════════════════

Three layers of dependency-breakage protection:

  Layer 1 — System-critical blacklist.
            Refuses to remove glibc, bash, pacman, filesystem, etc.
            even with cascade. The user can extend the list via
            ~/.config/pacman-protect.conf (one package per line,
            # comments allowed).

  Layer 2 — `pacman -Rs --print` (authoritative transaction preview).
            Default mode. Removes targets + deps no longer needed.
            Fails if a non-target installed package still depends on
            one of the targets — that's the "would break dependents"
            signal.

  Layer 3 — `pactree -r <target>` (reverse dependency tree).
            When -Rs fails, we enumerate the broken dependents so the
            UI can show them and offer cascade as an opt-in. Falls
            back to the cache's required_by field (direct only) if
            pactree is unavailable.

Cascade mode (--cascade):
            Runs `pacman -Rsc --print`, which force-removes the broken
            dependents too. The extra packages are returned as
            `cascadeDependents` so the UI can show the user what
            they're getting into.

Output shape (remove, success):
  {
    "toRemove":          [{name, version, freedBytes, freedSize,
                           isTarget, installReason}],
    "cascadeDependents": [{name, version, installReason, dependsOn}],
                           # only when cascade=true; packages force-
                           # removed because they depend on targets
    "brokenDependents":  [{target, dependents: [str]}],
                           # only when cascade=false and -Rs failed;
                           # lists what would break, for UI to offer
                           # cascade as an opt-in
    "freedTotal":        "78.3 MiB",
    "error":             null,
  }

Output shape (remove, error):
  { "toRemove": [], "cascadeDependents": [], "brokenDependents": [],
    "freedTotal": "0 B", "error": "error: ..." }

Note on error message format: error strings are prefixed with "error: "
to match pacman's own convention, so the existing QML error handler
(which regexes /error:\\s+(.*)/) extracts them cleanly.
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

# ─── System-critical package blacklist ────────────────────────────────────────
#
# These packages will NOT be removed via the UI, even with cascade. This is
# defensive — the dependency checks in layer 2 should already catch most
# disasters. This catches the "I uninstalled glibc because I didn't think I
# needed it" class of error.
#
# Users can extend this list by creating ~/.config/pacman-protect.conf
# (one package name per line, # comments allowed).

SYSTEM_CRITICAL_DEFAULT = {
    # Core C library & runtime
    "glibc", "gcc-libs", "libstdc++5",
    # Shell & core utils
    "bash", "coreutils", "findutils", "grep", "sed", "gawk",
    # Package manager itself
    "pacman", "pacman-mirrorlist", "archlinux-keyring",
    # Init system
    "systemd", "systemd-sysvcompat", "dbus",
    # Kernel
    "linux", "linux-headers", "linux-firmware",
    # Filesystem hierarchy
    "filesystem", "base", "base-devel",
    # Bootloader (common ones)
    "grub", "systemd-boot",
    # Network (basic)
    "iproute2", "iputils",
    # Crypto (many things link to these)
    "openssl", "openssl-1.1", "gnutls",
    # Compression (many things link to these)
    "zlib", "bzip2", "xz", "zstd", "lz4",
}


def load_protect_list() -> set[str]:
    """Load the system-critical blacklist, merged with user overrides."""
    protect = set(SYSTEM_CRITICAL_DEFAULT)
    xdg_config = os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
    user_conf = Path(xdg_config) / "pacman-protect.conf"
    if user_conf.exists():
        try:
            with open(user_conf) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        protect.add(line)
        except OSError:
            pass
    return protect


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


# ─── Shared helpers ───────────────────────────────────────────────────────────

def load_cache() -> dict:
    if not CACHE_FILE.exists():
        return {"packages": []}
    try:
        with open(CACHE_FILE) as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return {"packages": []}


def run(cmd: list[str], timeout: int = 30) -> tuple[int, str, str]:
    """Run a command, return (returncode, stdout, stderr)."""
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired:
        return -1, "", f"command timed out: {' '.join(cmd)}"
    except FileNotFoundError:
        return -2, "", f"command not found: {cmd[0]}"


# ─── Version constraint parsing (shared) ──────────────────────────────────────

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


# ─── Size formatting (shared) ─────────────────────────────────────────────────

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


def parse_print_line(line: str) -> dict | None:
    """Parse one line of `pacman --print --print-format "%n|%v|%s"` output.
    
    Returns {name, version, sizeBytes} or None if the line is malformed.
    """
    if not line:
        return None
    parts = line.split("|")
    if len(parts) < 3:
        return None
    name, version, size_str = parts[0], parts[1], parts[2]
    try:
        size_bytes = int(size_str)
    except ValueError:
        size_bytes = 0
    return {
        "name": name,
        "version": version,
        "sizeBytes": size_bytes,
    }


# ═══════════════════════════════════════════════════════════════════════════
# INSTALL PRE-FLIGHT
# ═══════════════════════════════════════════════════════════════════════════

def run_pacman_install_print(targets: list[str]) -> tuple[list[dict] | None, str]:
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
    rc, stdout, stderr = run(cmd)
    if rc != 0:
        return None, stderr.strip() or f"pacman exited with code {rc}"

    out: list[dict] = []
    for line in stdout.strip().split("\n"):
        parsed = parse_print_line(line)
        if parsed is None:
            continue
        out.append({
            "name": parsed["name"],
            "version": parsed["version"],
            "downloadBytes": parsed["sizeBytes"],
        })
    return out, ""


def build_install_preflight(
    targets: set[str],
    cache_packages: list[dict],
    print_output: list[dict],
) -> dict:
    """Build the install pre-flight plan for one or more target packages.

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


# ═══════════════════════════════════════════════════════════════════════════
# REMOVE PRE-FLIGHT
# ═══════════════════════════════════════════════════════════════════════════

def get_dependents(target: str, packages_by_name: dict[str, dict]) -> list[str]:
    """Find packages that depend on `target`, transitively.

    Tries `pactree -rl <target>` first (authoritative, transitive, linear
    output — one package name per line, target itself is the first line).
    Falls back to the cache's required_by field (direct dependents only,
    not transitive) if pactree is unavailable.

    Returns a list of package names, excluding `target` itself.
    """
    rc, stdout, _ = run(["pactree", "-rl", target], timeout=15)
    if rc == 0:
        deps: list[str] = []
        seen: set[str] = set()
        for line in stdout.strip().split("\n"):
            name = line.strip()
            if not name or name == target or name in seen:
                continue
            seen.add(name)
            deps.append(name)
        return deps

    # Fallback: direct dependents from cache (not transitive)
    target_pkg = packages_by_name.get(target)
    if not target_pkg:
        return []
    return list(target_pkg.get("required_by", []) or [])


def run_pacman_remove_print(targets: list[str], cascade: bool) -> tuple[list[dict] | None, str]:
    """Run `pacman -Rs --print` (or `-Rsc` with cascade).

    Returns (list_of_entries, error_message). On success, each entry is
    {name, version, freedBytes}. On failure, list_of_entries is None and
    error_message contains pacman's stderr (which usually names the
    broken dependents).
    """
    flags = ["-Rsc"] if cascade else ["-Rs"]
    cmd = ["pacman"] + flags + ["--print", "--print-format", "%n|%v|%s"] + targets
    rc, stdout, stderr = run(cmd)
    if rc != 0:
        return None, stderr.strip() or f"pacman exited with code {rc}"

    out: list[dict] = []
    for line in stdout.strip().split("\n"):
        parsed = parse_print_line(line)
        if parsed is None:
            continue
        out.append({
            "name": parsed["name"],
            "version": parsed["version"],
            "freedBytes": parsed["sizeBytes"],
        })
    return out, ""


def build_remove_preflight(
    targets: list[str],
    cache_packages: list[dict],
    cascade: bool,
) -> dict:
    """Build the remove pre-flight plan.

    See module docstring for the three-layer protection model.

    Returns:
        {
            toRemove:          [{name, version, freedBytes, freedSize,
                                 isTarget, installReason}],
            cascadeDependents: [{name, version, installReason, dependsOn}],
                                 # only when cascade=true; packages force-
                                 # removed because they depend on targets
            brokenDependents:  [{target, dependents: [str]}],
                                 # only when cascade=false and -Rs failed;
                                 # lists what would break, for UI to offer
                                 # cascade as an opt-in
            freedTotal:        "78.3 MiB",
            error:             str | None,
        }
    """
    packages_by_name: dict[str, dict] = {
        p["name"]: p for p in cache_packages if "name" in p
    }

    targets_set = set(targets)

    # ── Layer 1: system-critical blacklist ──────────────────────────────
    protect = load_protect_list()
    critical_hits = [t for t in targets if t in protect]
    if critical_hits:
        return {
            "toRemove": [],
            "cascadeDependents": [],
            "brokenDependents": [],
            "freedTotal": "0 B",
            "error": (
                f"error: Refusing to remove system-critical package(s): "
                f"{', '.join(critical_hits)}. These packages are required "
                f"for the system to function. If you really need to remove "
                f"one, use pacman directly from a terminal."
            ),
        }

    # ── Layer 1b: verify all targets are actually installed ────────────
    not_installed = [t for t in targets if not packages_by_name.get(t, {}).get("installed")]
    if not_installed:
        return {
            "toRemove": [],
            "cascadeDependents": [],
            "brokenDependents": [],
            "freedTotal": "0 B",
            "error": (
                f"error: Not installed: {', '.join(not_installed)}. "
                f"Nothing to remove."
            ),
        }

    # ── Layer 2: ask pacman for the authoritative removal list ─────────
    print_output, err = run_pacman_remove_print(targets, cascade)

    if print_output is None:
        # `-Rs` failed. Two common reasons:
        #   (a) A non-target package still depends on one of our targets
        #       (the common case — user needs to either keep the package
        #       or opt into cascade).
        #   (b) Some other pacman error (database locked, etc.).
        #
        # Distinguish by running pactree -r for each target. If pactree
        # finds dependents, this is case (a) — return them as broken-
        # dependents so the UI can offer cascade. Otherwise, surface the
        # raw pacman error.
        if cascade:
            # Cascade already attempted and still failed — surface the
            # raw error, no point enumerating broken dependents.
            return {
                "toRemove": [],
                "cascadeDependents": [],
                "brokenDependents": [],
                "freedTotal": "0 B",
                "error": f"error: pacman -Rsc --print failed: {err}",
            }

        broken: list[dict] = []
        any_broken = False
        for t in targets:
            deps = get_dependents(t, packages_by_name)
            if deps:
                any_broken = True
                broken.append({
                    "target": t,
                    "dependents": deps,
                })

        if any_broken:
            # This is the "would break dependents" case — don't return
            # an error, return a structured brokenDependents list so the
            # UI can offer cascade as an opt-in.
            return {
                "toRemove": [],
                "cascadeDependents": [],
                "brokenDependents": broken,
                "freedTotal": "0 B",
                "error": None,
            }

        # No dependents found, but pacman still failed. Surface the error.
        return {
            "toRemove": [],
            "cascadeDependents": [],
            "brokenDependents": [],
            "freedTotal": "0 B",
            "error": f"error: pacman -Rs --print failed: {err}",
        }

    # ── Build the toRemove list ────────────────────────────────────────
    to_remove: list[dict] = []
    total_freed_bytes = 0

    for entry in print_output:
        name = entry["name"]
        version = entry["version"]
        freed_bytes = entry["freedBytes"]
        total_freed_bytes += freed_bytes

        cached = packages_by_name.get(name)
        install_reason = cached.get("install_reason", "") if cached else ""

        to_remove.append({
            "name": name,
            "version": version,
            "freedBytes": freed_bytes,
            "freedSize": format_bytes(freed_bytes),
            "isTarget": name in targets_set,
            "installReason": install_reason,
        })

    # ── Identify cascadeDependents ─────────────────────────────────────
    #
    # In cascade mode, the print_output includes:
    #   - the user's targets (isTarget=true)
    #   - unneeded deps of the targets (isTarget=false, installReason
    #     starts with "installed as a dependency")
    #   - broken dependents that the cascade force-removes
    #
    # The first two categories also appear in a non-cascade -Rs print
    # (when -Rs succeeds). The third category is cascade-only.
    #
    # We identify cascadeDependents as: non-target packages whose
    # required_by overlaps with the removed set. These are packages
    # that depended on something we're removing, and got force-removed
    # by the cascade. The `dependsOn` field tells the user which
    # removed package each cascadeDependent depended on.

    cascade_dependents: list[dict] = []
    if cascade:
        removed_names = {e["name"] for e in print_output}
        for entry in to_remove:
            if entry["isTarget"]:
                continue
            cached = packages_by_name.get(entry["name"])
            if not cached:
                continue
            req_by = set(cached.get("required_by", []) or [])
            depends_on_removed = req_by & removed_names
            if depends_on_removed:
                cascade_dependents.append({
                    "name": entry["name"],
                    "version": entry["version"],
                    "installReason": entry["installReason"],
                    "dependsOn": sorted(depends_on_removed),
                })

    return {
        "toRemove": to_remove,
        "cascadeDependents": cascade_dependents,
        "brokenDependents": [],
        "freedTotal": format_bytes(total_freed_bytes),
        "error": None,
    }


# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

def parse_args(argv: list[str]) -> tuple[bool, bool, list[str]]:
    """Parse argv. Returns (remove_mode, cascade, targets)."""
    remove_mode = False
    cascade = False
    targets: list[str] = []
    past_double_dash = False

    for arg in argv:
        if past_double_dash:
            targets.append(arg.strip())
            continue
        if arg == "--":
            past_double_dash = True
            continue
        if arg == "--remove":
            remove_mode = True
        elif arg == "--cascade":
            cascade = True
        elif arg.startswith("--"):
            # Unknown long flag — ignore for forward compat.
            continue
        else:
            targets.append(arg.strip())

    return remove_mode, cascade, targets


def main() -> None:
    remove_mode, cascade, targets = parse_args(sys.argv[1:])

    if not targets:
        print(json.dumps({"error": "error: missing package name(s)"}, indent=2))
        sys.exit(1)

    if cascade and not remove_mode:
        print(json.dumps({
            "error": "error: --cascade can only be used with --remove",
        }, indent=2))
        sys.exit(1)

    cache = load_cache()
    cache_packages = cache.get("packages", [])
    if isinstance(cache_packages, dict):
        cache_packages = list(cache_packages.values())

    if not cache_packages:
        print(json.dumps({
            "error": "error: cache is empty — run refresh first",
        }, indent=2))
        sys.exit(1)

    # ── Remove mode ────────────────────────────────────────────────────
    if remove_mode:
        plan = build_remove_preflight(targets, cache_packages, cascade)
        print(json.dumps(plan, indent=2))
        # Exit 1 if there was an error, so callers can detect failure
        # via exit code too (the JSON always has the full picture).
        if plan.get("error"):
            sys.exit(1)
        return

    # ── Install mode (original logic, preserved for backward compat) ───
    targets_set = set(targets)
    print_output, err = run_pacman_install_print(targets)
    if print_output is None:
        print(json.dumps({
            "error": f"pacman -S --print failed: {err}",
            "targets": targets,
        }, indent=2))
        sys.exit(1)

    if not print_output:
        print(json.dumps({
            "error": f"no transaction for {', '.join(targets)} (already installed or not found)",
            "targets": targets,
        }, indent=2))
        sys.exit(1)

    plan = build_install_preflight(targets_set, cache_packages, print_output)
    print(json.dumps(plan, indent=2))


if __name__ == "__main__":
    main()
