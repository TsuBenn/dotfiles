#!/usr/bin/env python3
import argparse
import subprocess
import json
import os
import sys
from datetime import datetime

CACHE_DIR = os.path.expanduser("~/.cache/pacman-filter")
CACHE_FILE = os.path.join(CACHE_DIR, "packages.json")

def ensure_cache_dir():
    if not os.path.exists(CACHE_DIR):
        os.makedirs(CACHE_DIR)

def parse_user_input():
    parser = argparse.ArgumentParser(description="pacman-filter: Fast unified JSON cache engine.")
    action_group = parser.add_mutually_exclusive_group(required=True)
    action_group.add_argument('-l', '--list', action='store_true', help="List installed packages from cache")
    action_group.add_argument('-s', '--search', type=str, metavar='QUERY', help="Instant search across all repositories")
    action_group.add_argument('-i', '--info', type=str, metavar='PACKAGE', help="Get detailed package information")
    
    parser.add_argument('-r', '--refresh', action='store_true', help="Force rebuild the master cache index")
    return parser.parse_args()

def parse_pacman_qi_output(raw_text):
    """Parses raw pacman -Qi text into structured dictionaries."""
    packages = {}
    current_pkg = {}
    last_key = None 

    for line in raw_text.splitlines():
        if not line.strip():
            if current_pkg and "name" in current_pkg:
                packages[current_pkg["name"]] = current_pkg
                current_pkg = {}
            last_key = None
            continue
            
        if " : " in line:
            key, val = line.split(" : ", 1)
            key, val = key.strip(), val.strip()
            last_key = key 
            
            if key == "Name":
                current_pkg["name"] = val
            elif key == "Version":
                current_pkg["version"] = val
            elif key == "Description":
                current_pkg["description"] = val
            elif key == "Depends On":
                current_pkg["dependencies_raw"] = []
                for d in val.split():
                    dep = d.split('>=')[0].split('<=')[0].split('=')[0].split('>')[0].split('<')[0]
                    if dep != "None":
                        current_pkg["dependencies_raw"].append(dep)
            elif key == "Optional Deps":
                current_pkg["optional_dependencies_raw"] = []
                if val and val != "None":
                    current_pkg["optional_dependencies_raw"].append(val.split(":")[0].strip())
        else:
            if last_key == "Optional Deps" and "optional_dependencies_raw" in current_pkg:
                val = line.strip()
                if val and ":" in val:
                    current_pkg["optional_dependencies_raw"].append(val.split(":")[0].strip())

    if current_pkg and "name" in current_pkg:
        packages[current_pkg["name"]] = current_pkg
        
    return packages

def generate_and_cache_data():
    """Builds a complete unified index of both installed and uninstalled repo packages."""
    ensure_cache_dir()
    
    try:
        # 1. Get detailed profiles of everything installed locally
        qi_result = subprocess.run(['pacman', '-Qei'], capture_output=True, text=True, check=True)
        local_profiles = parse_pacman_qi_output(qi_result.stdout)
        
        # 2. Get clean checklist of all installed packages (explicit + implicit dependencies)
        all_installed_result = subprocess.run(['pacman', '-Qq'], capture_output=True, text=True, check=True)
        installed_set = set(all_installed_result.stdout.strip().split('\n'))
        
        # 3. Get master list of every single package available in online repos via pacman -Sl
        sl_result = subprocess.run(['pacman', '-Sl'], capture_output=True, text=True, check=True)
        
        master_packages = []
        seen_packages = set()

        # 4. First pass: Populate all installed packages with full details
        for name, pkg in local_profiles.items():
            resolved_deps = [{"name": d, "installed": d in installed_set} for d in pkg.get("dependencies_raw", [])]
            resolved_opt_deps = [{"name": d, "installed": d in installed_set} for d in pkg.get("optional_dependencies_raw", [])]
            
            master_packages.append({
                "name": pkg["name"],
                "version": pkg["version"],
                "description": pkg["description"],
                "installed": True,
                "dependencies": resolved_deps,
                "optional_dependencies": resolved_opt_deps
            })
            seen_packages.add(pkg["name"])

        # 5. Second pass: Add uninstalled repository packages cleanly using low overhead
        for line in sl_result.stdout.splitlines():
            parts = line.split()
            if len(parts) >= 2:
                pkg_name = parts[1]
                pkg_version = parts[2] if len(parts) > 2 else ""
                
                # Skip if we already added it during the local profiles pass
                if pkg_name in seen_packages:
                    continue
                    
                master_packages.append({
                    "name": pkg_name,
                    "version": pkg_version,
                    "description": "[Remote Package] Re-run with --refresh -i <name> for full description details.",
                    "installed": False,
                    "dependencies": [],
                    "optional_dependencies": []
                })

        cache_data = {
            "last_updated": datetime.now().isoformat(),
            "packages": master_packages
        }
        
        with open(CACHE_FILE, 'w') as f:
            json.dump(cache_data, f, indent=2)
            
        return cache_data
    except subprocess.CalledProcessError as e:
        print(json.dumps({"error": f"Failed running pacman backend: {e.stderr}"}))
        sys.exit(1)

def load_data(force_refresh=False):
    if force_refresh or not os.path.exists(CACHE_FILE):
        return generate_and_cache_data()
    try:
        with open(CACHE_FILE, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return generate_and_cache_data()

def main():
    args = parse_user_input()
    
    # Load our custom cache database instantly
    cache_data = load_data(force_refresh=args.refresh)
    packages = cache_data.get("packages", [])
    
    if args.list:
        # Filter down to display only locally installed items
        installed_only = [p for p in packages if p["installed"]]
        print(json.dumps(installed_only, indent=2))
        
    elif args.search:
        query = args.search.lower()
        results = []
        for p in packages:
            if query in p["name"].lower() or query in p["description"].lower():
                results.append(p)
        print(json.dumps(results, indent=2))
        
    elif args.info:
        matched = [p for p in packages if p["name"] == args.info]
        if matched:
            pkg = matched[0]
            # Edge Case: If it's a remote package block, it lacks deep metadata.
            # We fetch its real-time info using sync databases directly.
            if not pkg["installed"] and "[Remote Package]" in pkg["description"]:
                try:
                    si_result = subprocess.run(['pacman', '-Si', args.info], capture_output=True, text=True)
                    remote_profile = parse_pacman_qi_output(si_result.stdout)
                    if args.info in remote_profile:
                        r_pkg = remote_profile[args.info]
                        # Track setup status loops
                        all_installed = subprocess.run(['pacman', '-Qq'], capture_output=True, text=True)
                        installed_set = set(all_installed.stdout.strip().split('\n'))
                        
                        pkg = {
                            "name": r_pkg["name"],
                            "version": r_pkg["version"],
                            "description": r_pkg["description"],
                            "installed": False,
                            "dependencies": [{"name": d, "installed": d in installed_set} for d in r_pkg.get("dependencies_raw", [])],
                            "optional_dependencies": [{"name": d, "installed": d in installed_set} for d in r_pkg.get("optional_dependencies_raw", [])]
                        }
                except:
                    pass
            print(json.dumps(pkg, indent=2))
        else:
            print(json.dumps({"error": "Package not found in cache registry."}))

if __name__ == '__main__':
    main()
