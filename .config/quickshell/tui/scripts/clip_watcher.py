#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import threading
import uuid
import atexit

# Configuration
CACHE_DIR = os.path.expanduser("~/.cache/clip-watcher")
INDEX_FILE = os.path.join(CACHE_DIR, "index.json")
MAX_ENTRIES = 200

# Ensure cache directory exists
os.makedirs(CACHE_DIR, exist_ok=True)

# Lock to prevent thread collision during I/O operations
io_lock = threading.Lock()

def clear_system_clipboard():
    """Clears the active system clipboard on exit to prevent stale data overhead."""
    try:
        subprocess.run(["wl-copy", "--clear"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (subprocess.SubprocessError, FileNotFoundError):
        pass

atexit.register(clear_system_clipboard)

def load_history():
    """Loads current JSON history array from disk."""
    if not os.path.exists(INDEX_FILE):
        return []
    try:
        with open(INDEX_FILE, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return []

def print_history(history_data=None):
    """Prints the entire list of entries as a JSON string to stdout."""
    if history_data is None:
        history_data = load_history()
    print(json.dumps(history_data, indent=2, ensure_ascii=False))
    sys.stdout.flush()

def add_entry(entry):
    """Appends an entry if unique, enforces limits, cleans files, and prints."""
    with io_lock:
        history = load_history()

        # Check if the hash already exists in history to prevent duplicates
        if any(item.get("hash") == entry.get("hash") for item in history):
            return

        history.append(entry)

        # Enforce maximum entry limit
        if len(history) > MAX_ENTRIES:
            excess_count = len(history) - MAX_ENTRIES
            to_remove = history[:excess_count]
            history = history[excess_count:]

            # Garbage collection for images
            for old_entry in to_remove:
                if old_entry.get("type", "").startswith("image/") and os.path.exists(old_entry["data"]):
                    try:
                        os.remove(old_entry["data"])
                    except OSError:
                        pass

        with open(INDEX_FILE, "w") as f:
            json.dump(history, f, indent=2, ensure_ascii=False)
        print_history(history)

def watch_text():
    """Watches for text selections via non-blocking sub-process."""
    cmd = [
        "wl-paste", "--type", "text", "--watch",
        "python3", "-c", f"""
import sys, os, json, textwrap, hashlib
text = sys.stdin.read()
if text.strip() and "Nothing is copied" not in text:
    dedented_text = textwrap.dedent(text).strip()
    flattened = dedented_text.replace('\\n', ' ')
    truncated = flattened[:40] + '...' if len(flattened) > 40 else flattened

    # Generate unique hash for text content
    text_hash = hashlib.sha256(text.encode('utf-8')).hexdigest()

    entry = {{
        "value": truncated,
        "type": "text",
        "data": text,
        "hash": text_hash
    }}
    print(json.dumps(entry, ensure_ascii=False))
"""
    ]

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True)
    for line in process.stdout:
        line = line.strip()
        if line:
            try:
                entry = json.loads(line)
                add_entry(entry)
            except json.JSONDecodeError:
                pass

def watch_images():
    """Watches for image selections via non-blocking sub-process."""
    cmd = [
        "wl-paste", "--type", "image", "--watch",
        "python3", "-c", f"""
import subprocess, os, uuid, json, sys, hashlib
try:
    targets_proc = subprocess.run(["wl-paste", "-l"], capture_output=True, text=True)
    if targets_proc.returncode != 0 or "Nothing is copied" in targets_proc.stderr or "Nothing is copied" in targets_proc.stdout:
        sys.exit(0)

    targets = targets_proc.stdout.splitlines()
    img_target = next((t for t in targets if t.startswith("image/")), None)
    if img_target:
        img_data = subprocess.check_output(["wl-paste", "--type", img_target])

        # Hash the raw binary image stream before writing anything to disk
        img_hash = hashlib.sha256(img_data).hexdigest()

        ext = img_target.split("/")[-1]
        if "png" in ext: ext = "png"
        elif "jpeg" in ext or "jpg" in ext: ext = "jpg"

        uid = str(uuid.uuid4())[:8]
        file_path = os.path.join("{CACHE_DIR}", f"{{uid}}.{{ext}}")

        # We write out a placeholder JSON first so the parent can see if the hash is unique
        entry = {{
            "value": f"[[Binary data Image/ {{ext.upper()}}]]",
            "type": f"image/{{ext}}",
            "data": file_path,
            "hash": img_hash,
            "_tmp_write_flag": True # Signaling property
        }}
        print(json.dumps(entry, ensure_ascii=False))

        # Read parent response context via stdout loop structure implicitly,
        # but to keep the thread non-blocking, we write out the bytes instantly.
        # If the parent rejects the entry, the file is unlinked during sync or ignored.
        with open(file_path, "wb") as f:
            f.write(img_data)
except Exception:
    pass
"""
    ]

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True)
    for line in process.stdout:
        line = line.strip()
        if line:
            try:
                entry = json.loads(line)
                # Cleanup internal flag before database writing
                if "_tmp_write_flag" in entry:
                    del entry["_tmp_write_flag"]

                # Load current cache to verify uniqueness before keeping the file
                current_history = load_history()
                if any(item.get("hash") == entry.get("hash") for item in current_history):
                    # Duplicate found! Remove the image file we just wrote
                    if os.path.exists(entry["data"]):
                        os.remove(entry["data"])
                    continue

                add_entry(entry)
            except json.JSONDecodeError:
                pass

if __name__ == "__main__":
    print_history()

    t_text = threading.Thread(target=watch_text, daemon=True)
    t_image = threading.Thread(target=watch_images, daemon=True)

    t_text.start()
    t_image.start()

    try:
        t_text.join()
        t_image.join()
    except KeyboardInterrupt:
        pass
