#!/usr/bin/env python3
import os
import sys
import json
import hashlib
import socket
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
SOCKET_PATH = CACHE_DIR / "watcher.sock"

CACHE_DIR.mkdir(parents=True, exist_ok=True)
IMAGES_DIR.mkdir(parents=True, exist_ok=True)

MAX_ITEMS = 200
CLEAN_EVERY_N_WRITES = 20  # only sweep IMAGES_DIR every N copies, not every single one

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

# Global lock so history read-modify-write from multiple connection threads
# doesn't race and clobber the JSON file.
history_lock = threading.Lock()
write_counter = 0

# Used to suppress "ghost" text events (e.g. an image URL) that browsers
# fire alongside a real image copy.
suppress_lock = threading.Lock()
last_image_ts = [0.0]
TEXT_SUPPRESS_WINDOW = 0.4  # seconds - tweak if too aggressive/lenient


def get_image_ext(data: bytes) -> str:
    """Detect image extension based on magic bytes."""
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    elif data.startswith(b"\xff\xd8"):
        return "jpg"
    elif data.startswith(b"GIF87a") or data.startswith(b"GIF89a"):
        return "gif"
    elif data.startswith(b"RIFF") and data[8:12] == b"WEBP":
        return "webp"
    elif data.startswith(b"BM"):
        return "bmp"
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
    """Delete any cached image files no longer referenced in the history."""
    valid_paths = {item["data"] for item in history if item["type"].startswith("image/")}
    for img_file in IMAGES_DIR.glob("*"):
        if str(img_file) not in valid_paths:
            try:
                img_file.unlink()
            except OSError:
                pass


def process_clipboard_item(item_type: str, raw_data: bytes):
    """Processes, dedups, and saves incoming text or image data."""
    global write_counter

    if not raw_data:
        return

    if item_type == "text":
        # Wait a beat, then check whether an image landed right around now.
        # Browsers fire a text/plain "metadata" event (e.g. the image URL)
        # alongside the real image event - this catches it either way round.
        check_time = time.time()
        time.sleep(TEXT_SUPPRESS_WINDOW)
        with suppress_lock:
            if last_image_ts[0] >= check_time - TEXT_SUPPRESS_WINDOW:
                return  # this text was just image metadata, discard it
    elif item_type == "image":
        with suppress_lock:
            last_image_ts[0] = time.time()

    sha256 = hashlib.sha256(raw_data).hexdigest()

    # Do the slow work (disk write for images) BEFORE taking the lock,
    # so we hold the lock for as short a time as possible.
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

            # Browsers often hand over an HTML snippet (e.g. <img src="...">)
            # as the "text" representation when you copy an image. Detect
            # that and store the clean source link instead of raw HTML.
            match = IMG_SRC_RE.search(full_text)
            if match and ("<img" in full_text.lower()):
                source_url = match.group(1)
                new_item = {
                    "value": source_url,
                    "type": "link",
                    "data": source_url,
                    "hash": sha256
                }
            else:
                dedented_text = textwrap.dedent(full_text).strip()
                flattened = dedented_text.replace('\n', ' ')
                truncated = flattened[:40] + '...' if len(flattened) > 40 else flattened
                new_item = {
                    "value": truncated,
                    "type": "text",
                    "data": full_text,
                    "hash": sha256
                }
        except UnicodeDecodeError:
            return
    else:
        return

    with history_lock:
        history = load_history()

        # Ignore if it's already the most recent item (stops startup double-trigger)
        if history and history[0].get("hash") == sha256:
            return

        # Deduplicate against the rest of history
        history = [item for item in history if item["hash"] != sha256]
        history.insert(0, new_item)

        if len(history) > MAX_ITEMS:
            history = history[:MAX_ITEMS]

        save_history(history)

        write_counter += 1
        should_clean = (write_counter % CLEAN_EVERY_N_WRITES == 0)

    # Run the expensive directory sweep OUTSIDE the lock and only every
    # CLEAN_EVERY_N_WRITES copies, so a fast burst of copies (or a big
    # image from a browser) never gets stuck behind a full glob() scan.
    if should_clean:
        threading.Thread(target=clean_excess_images, args=(history,), daemon=True).start()

    print("Copied")
    sys.stdout.flush()


def handle_connection(conn):
    """Handles a single wl-paste client connection. Runs in its own thread
    so one slow/stuck client can never block accept() for the others."""
    try:
        data = b""
        while True:
            chunk = conn.recv(4096)
            if not chunk:
                break
            data += chunk
    except Exception as e:
        print(f"[watcher] connection read error: {e}", file=sys.stderr)
        return
    finally:
        conn.close()

    if len(data) > 1:
        item_type = "text" if data[0] == ord("t") else "image"
        payload = data[1:]
        try:
            process_clipboard_item(item_type, payload)
        except Exception as e:
            print(f"[watcher] error processing clipboard item: {e}", file=sys.stderr)


def socket_server_worker():
    """Listens on a local UNIX socket to receive data from wl-paste watchers."""
    if SOCKET_PATH.exists():
        SOCKET_PATH.unlink()

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(SOCKET_PATH))
    server.listen(5)

    while True:
        try:
            conn, _ = server.accept()
        except Exception as e:
            # Don't die on a bad accept - log it and keep listening.
            print(f"[watcher] accept() error: {e}", file=sys.stderr)
            continue

        # Hand off to a worker thread immediately so accept() loop is
        # never blocked by a slow client or a slow process_clipboard_item.
        threading.Thread(target=handle_connection, args=(conn,), daemon=True).start()


def start_watchers():
    text_cmd = [
        "wl-paste", "--type", "text", "--watch", "python3", "-c",
        f"import sys, socket; s=socket.socket(socket.AF_UNIX); s.connect('{SOCKET_PATH}'); s.sendall(b't' + sys.stdin.buffer.read())"
    ]
    image_cmd = [
        "wl-paste", "--type", "image", "--watch", "python3", "-c",
        f"import sys, socket; s=socket.socket(socket.AF_UNIX); s.connect('{SOCKET_PATH}'); s.sendall(b'i' + sys.stdin.buffer.read())"
    ]

    p_text = subprocess.Popen(text_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    p_image = subprocess.Popen(image_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return p_text, p_image


def watchdog_worker(get_procs, set_procs, stop_event):
    """Periodically checks if the wl-paste watcher processes have died
    (e.g. after a compositor reload) and restarts them if so."""
    while not stop_event.is_set():
        time.sleep(5)
        p_text, p_image = get_procs()
        text_dead = p_text.poll() is not None
        image_dead = p_image.poll() is not None
        if text_dead or image_dead:
            print("[watcher] a wl-paste watcher died, restarting watchers...", file=sys.stderr)
            try:
                p_text.terminate()
            except Exception:
                pass
            try:
                p_image.terminate()
            except Exception:
                pass
            new_p_text, new_p_image = start_watchers()
            set_procs(new_p_text, new_p_image)


def main():
    server_thread = threading.Thread(target=socket_server_worker, daemon=True)
    server_thread.start()

    time.sleep(0.1)

    procs = list(start_watchers())  # [p_text, p_image], mutable via closures below
    procs_lock = threading.Lock()

    def get_procs():
        with procs_lock:
            return procs[0], procs[1]

    def set_procs(p_text, p_image):
        with procs_lock:
            procs[0], procs[1] = p_text, p_image

    stop_event = threading.Event()
    watchdog_thread = threading.Thread(
        target=watchdog_worker, args=(get_procs, set_procs, stop_event), daemon=True
    )
    watchdog_thread.start()

    def cleanup(signum, frame):
        stop_event.set()
        p_text, p_image = get_procs()
        p_text.terminate()
        p_image.terminate()
        try:
            subprocess.run(["wl-copy", "--clear"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass
        if SOCKET_PATH.exists():
            SOCKET_PATH.unlink()
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    # Initial dump so the listening UI knows the baseline history state on startup
    print(json.dumps(load_history(), indent=2, ensure_ascii=False))
    sys.stdout.flush()

    while True:
        time.sleep(1)


if __name__ == "__main__":
    main()
