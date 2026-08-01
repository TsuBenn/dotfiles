#!/usr/bin/env python3
import os
import sys
import json
import hashlib
import threading
import subprocess
import signal
import textwrap
import time
import re
from pathlib import Path

# Matches the first src="..." inside an <img> tag in HTML clipboard data
IMG_SRC_RE = re.compile(r'<img[^>]+src=["\']([^"\']+)["\']', re.IGNORECASE)

# Paths
CACHE_DIR = Path.home() / ".cache" / "clip-watcher"
IMAGES_DIR = CACHE_DIR / "images"
JSON_PATH = CACHE_DIR / "clipboard_history.json"

CACHE_DIR.mkdir(parents=True, exist_ok=True)
IMAGES_DIR.mkdir(parents=True, exist_ok=True)

MAX_ITEMS = 200
CLEAN_EVERY_N_WRITES = 20

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

history_lock = threading.Lock()
write_counter = 0

suppress_lock = threading.Lock()
last_image_ts = [0.0]
TEXT_SUPPRESS_WINDOW = 0.4

active_procs = []
procs_lock = threading.Lock()

def get_image_ext(data: bytes) -> str:
    if data.startswith(b"\x89PNG\r\n\x1a\n"): return "png"
    elif data.startswith(b"\xff\xd8"): return "jpg"
    elif data.startswith(b"GIF87a") or data.startswith(b"GIF89a"): return "gif"
    elif data.startswith(b"RIFF") and data[8:12] == b"WEBP": return "webp"
    elif data.startswith(b"BM"): return "bmp"
    return "bin"

def load_history():
    if JSON_PATH.exists():
        try:
            with open(JSON_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except json.JSONDecodeError:
            pass
    return []

def save_history(history):
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(history, f, indent=2, ensure_ascii=False)

def clean_excess_images(history):
    valid_paths = {item["data"] for item in history if item["type"].startswith("image/")}
    for img_file in IMAGES_DIR.glob("*"):
        if str(img_file) not in valid_paths:
            try:
                img_file.unlink()
            except OSError:
                pass

def process_clipboard_item(item_type: str, raw_data: bytes):
    global write_counter
    if not raw_data: return

    if item_type == "text":
        check_time = time.time()
        time.sleep(TEXT_SUPPRESS_WINDOW)
        with suppress_lock:
            if last_image_ts[0] >= check_time - TEXT_SUPPRESS_WINDOW:
                return
    elif item_type == "image":
        with suppress_lock:
            last_image_ts[0] = time.time()

    sha256 = hashlib.sha256(raw_data).hexdigest()

    if item_type == "image":
        ext = get_image_ext(raw_data)
        img_path = IMAGES_DIR / f"{sha256}.{ext}"
        if not img_path.exists():
            img_path.write_bytes(raw_data)
        new_item = {
            "value": f"[[Binary data Image/ {ext.upper()}]]",
            "type": f"image/{ext}",
            "data": str(img_path),
            "hash": sha256
        }
    elif item_type == "text":
        try:
            full_text = raw_data.decode("utf-8")
            if not full_text.strip() or "Nothing is copied" in full_text:
                return
            match = IMG_SRC_RE.search(full_text)
            if match and ("<img" in full_text.lower()):
                source_url = match.group(1)
                new_item = {
                    "value": source_url, "type": "link", "data": source_url, "hash": sha256
                }
            else:
                dedented_text = textwrap.dedent(full_text).strip()
                flattened = dedented_text.replace('\n', ' ')
                truncated = flattened[:40] + '...' if len(flattened) > 40 else flattened
                new_item = {
                    "value": truncated, "type": "text", "data": full_text, "hash": sha256
                }
        except UnicodeDecodeError:
            return
    else:
        return

    with history_lock:
        history = load_history()
        if history and history[0].get("hash") == sha256:
            return
        history = [item for item in history if item["hash"] != sha256]
        history.insert(0, new_item)
        if len(history) > MAX_ITEMS:
            history = history[:MAX_ITEMS]

        save_history(history)
        write_counter += 1
        should_clean = (write_counter % CLEAN_EVERY_N_WRITES == 0)

    if should_clean:
        threading.Thread(target=clean_excess_images, args=(history,), daemon=True).start()

    print("Copied")
    sys.stdout.flush()

def watch_worker(item_type: str):
    """Watches the clipboard and triggers fetches when changes occur."""
    while True:
        # Instead of launching Python, we launch the ultra-light 'echo' command
        cmd = ["wl-paste", "--type", item_type, "--watch", "echo", "change"]
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True)

        with procs_lock:
            active_procs.append(p)

        # 'echo' will print "change\n" to p.stdout whenever the clipboard updates
        for line in p.stdout:
            # Now we fetch the data ourselves without blocking the Wayland compositor
            res = subprocess.run(["wl-paste", "--type", item_type], capture_output=True)
            if res.returncode == 0:
                threading.Thread(
                    target=process_clipboard_item,
                    args=(item_type, res.stdout),
                    daemon=True
                ).start()

        with procs_lock:
            if p in active_procs:
                active_procs.remove(p)

        print(f"[watcher] {item_type} watcher died, restarting in 5s...", file=sys.stderr)
        time.sleep(5)

def main():
    print(json.dumps(load_history(), indent=2, ensure_ascii=False))
    sys.stdout.flush()

    # Two simple threads completely replace the socket server and complex watchdog
    threading.Thread(target=watch_worker, args=("text",), daemon=True).start()
    threading.Thread(target=watch_worker, args=("image",), daemon=True).start()

    def cleanup(signum, frame):
        with procs_lock:
            for p in active_procs:
                try: p.terminate()
                except Exception: pass
        try:
            subprocess.run(["wl-copy", "--clear"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    while True:
        time.sleep(1)

if __name__ == "__main__":
    main()
