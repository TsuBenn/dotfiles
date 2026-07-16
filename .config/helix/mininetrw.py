#!/usr/bin/env python3
# MUST be set before importing curses or calling wrapper!
import os
os.environ["ESCDELAY"] = "25"

import sys
import stat
import shutil
import curses
import subprocess
from dataclasses import dataclass, field
from typing import Optional, List

# ─── Constants ────────────────────────────────────────────────────────────────

ESC_KEY = 27
ENTER_KEYS = (10, 13)
BACKSPACE_KEYS = (curses.KEY_BACKSPACE, 127, 8)
QUIT_KEYS = (ord('q'), ESC_KEY)

# ─── State ────────────────────────────────────────────────────────────────────

@dataclass
class ExplorerState:
    current_dir: str
    selected_idx: int = 0
    scroll_offset: int = 0
    search_query: str = ""
    in_search_mode: bool = False
    in_menu_mode: bool = False
    clipboard_path: Optional[str] = None
    clipboard_action: Optional[str] = None
    entries: List[tuple] = field(default_factory=list)
    all_entries: List[tuple] = field(default_factory=list)
    needs_refresh: bool = True
    status_message: str = ""
    status_type: str = ""  # "success", "error", "info"
    should_quit: bool = False
    open_payload: Optional[str] = None

    def set_status(self, msg: str, type: str = "info"):
        self.status_message = msg
        self.status_type = type

# ─── Permission Helpers ───────────────────────────────────────────────────────

def get_file_permissions(path: str) -> dict:
    """Returns a dict of bools indicating if the owner has r, w, x permissions."""
    try:
        current_mode = os.stat(path).st_mode
        return {
            "r": bool(current_mode & stat.S_IRUSR),
            "w": bool(current_mode & stat.S_IWUSR),
            "x": bool(current_mode & stat.S_IXUSR)
        }
    except Exception:
        return {"r": False, "w": False, "x": False}

def toggle_permission(path: str, perm_type: str) -> bool:
    """Toggles a specific owner permission (r, w, or x) using bitwise XOR."""
    try:
        current_mode = os.stat(path).st_mode
        mask_map = {
            "r": stat.S_IRUSR,
            "w": stat.S_IWUSR,
            "x": stat.S_IXUSR
        }
        mask = mask_map.get(perm_type)
        if not mask:
            return False

        new_mode = current_mode ^ mask
        os.chmod(path, new_mode)
        return True
    except Exception:
        return False

# ─── Directory Helpers ────────────────────────────────────────────────────────

def list_directory(path: str) -> List[tuple]:
    try:
        names = os.listdir(path)
        entries = [(name, os.path.isdir(os.path.join(path, name))) for name in names]
        entries.sort(key=lambda e: (not e[1], e[0].lower()))
        return entries
    except PermissionError:
        return [("[Permission Denied]", False)]
    except OSError:
        return [("[Error Reading Directory]", False)]


def filter_entries(entries: List[tuple], query: str) -> List[tuple]:
    if not query:
        return entries
    return [e for e in entries if query.lower() in e[0].lower()]


# ─── Status / Input Helpers ───────────────────────────────────────────────────

def safe_addstr(stdscr, y, x, text, attr=curses.A_NORMAL):
    height, width = stdscr.getmaxyx()
    if y < 0 or y >= height or x >= width:
        return
    try:
        stdscr.addstr(y, x, text[:width - x - 1], attr)
    except curses.error:
        pass


def read_line_input(stdscr, prompt: str, height: int, width: int) -> Optional[str]:
    curses.curs_set(1)
    try:
        stdscr.addstr(height - 2, 1, " " * (width - 3))
        stdscr.addstr(height - 2, 2, prompt[:width - 4], curses.color_pair(3) | curses.A_BOLD)
        stdscr.refresh()
    except curses.error:
        pass

    text = ""
    while True:
        ch = stdscr.getch()
        if ch == ESC_KEY:
            return None
        elif ch in ENTER_KEYS:
            return text
        elif ch in BACKSPACE_KEYS:
            if text:
                text = text[:-1]
                col = min(2 + len(prompt) + len(text), width - 3)
                try:
                    stdscr.addstr(height - 2, col, " ")
                    stdscr.move(height - 2, col)
                    stdscr.refresh()
                except curses.error:
                    pass
        elif 32 <= ch <= 126:
            if 2 + len(prompt) + len(text) < width - 3:
                text += chr(ch)
                try:
                    stdscr.addstr(height - 2, 2 + len(prompt) + len(text) - 1, chr(ch))
                    stdscr.refresh()
                except curses.error:
                    pass


def send_to_tmux(target_pane: str, absolute_path: str):
    try:
        subprocess.run(
            ["tmux", "send-keys", "-t", target_pane, f":o {absolute_path}", "Enter"],
            check=True, capture_output=True, text=True,
        )
        pass
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        print(f"tmux error: {exc}", file=sys.stderr)


# ─── Rendering ────────────────────────────────────────────────────────────────

def render(stdscr, state: ExplorerState):
    stdscr.erase()
    height, width = stdscr.getmaxyx()

    # Draw Outer Border Window Frame
    stdscr.attron(curses.color_pair(4))
    stdscr.border()
    stdscr.attroff(curses.color_pair(4))

    # ── Header ──
    header = f" 📂 {os.path.basename(state.current_dir) or state.current_dir} "
    safe_addstr(stdscr, 0, 2, header, curses.color_pair(4) | curses.A_BOLD)

    # Path tracking subtitle row
    path_sub = f" Path: {state.current_dir} "
    safe_addstr(stdscr, 1, 2, path_sub, curses.A_DIM)

    # ── Scroll adjustment ──
    visible_height = height - 4
    if state.selected_idx < state.scroll_offset:
        state.scroll_offset = state.selected_idx
    elif state.selected_idx >= state.scroll_offset + visible_height:
        state.scroll_offset = state.selected_idx - visible_height + 1

    # ── Entry list ──
    for i, (entry, is_dir) in enumerate(state.entries[state.scroll_offset:]):
        if i >= visible_height:
            break
        row = i + 2
        actual_idx = state.scroll_offset + i

        suffix = "/" if is_dir else ""
        display = f" {entry}{suffix} "

        if actual_idx == state.selected_idx:
            attr = curses.color_pair(5) | curses.A_BOLD
        else:
            if entry.startswith("["):
                attr = curses.color_pair(2)
            elif is_dir:
                attr = curses.color_pair(4) | curses.A_BOLD
            else:
                attr = curses.color_pair(6)

        padded_display = display + " " * (width - len(display) - 3)
        safe_addstr(stdscr, row, 1, padded_display, attr)

    # ── Scroll indicator ──
    if len(state.entries) > visible_height:
        indicator = f" {state.scroll_offset + 1}-{min(state.scroll_offset + visible_height, len(state.entries))}/{len(state.entries)} "
        safe_addstr(stdscr, 0, width - len(indicator) - 2, indicator, curses.color_pair(4))

    # ── Footer ──
    render_footer(stdscr, state, height, width)

    # ── Menu overlay ──
    if state.in_menu_mode:
        render_menu(stdscr, height, width)

    stdscr.refresh()


def render_footer(stdscr, state: ExplorerState, height: int, width: int):
    stdscr.attron(curses.color_pair(4))
    stdscr.hline(height - 3, 1, curses.ACS_HLINE, width - 2)
    stdscr.attroff(curses.color_pair(4))

    if state.in_search_mode:
        curses.curs_set(1)
        text = f" Search: {state.search_query}"
        safe_addstr(stdscr, height - 2, 1, text)
        try:
            stdscr.move(height - 2, min(1 + len(text), width - 2))
        except curses.error:
            pass
        return

    curses.curs_set(0)

    if state.status_message:
        attr = curses.A_DIM
        if state.status_type == "success":
            attr = curses.color_pair(1) | curses.A_BOLD
        elif state.status_type == "error":
            attr = curses.color_pair(2) | curses.A_BOLD
        elif state.status_type == "info":
            attr = curses.color_pair(3) | curses.A_BOLD
        safe_addstr(stdscr, height - 2, 2, state.status_message, attr)
    elif state.search_query:
        safe_addstr(stdscr, height - 2, 2,
                     f"Filtered by: {state.search_query} (Press / to edit, Esc to clear)",
                     curses.A_DIM)
    elif state.clipboard_path:
        status = "Copied" if state.clipboard_action == "copy" else "Cut"
        fname = os.path.basename(state.clipboard_path)
        attr = curses.color_pair(3) | curses.A_BOLD
        safe_addstr(stdscr, height - 2, 2, f"[{status}: {fname}] Press p to paste | Space: Menu", attr)
    else:
        safe_addstr(stdscr, height - 2, 2,
                     "Space: Menu | /: Search | f/d: New | m: Perms | c/x/p: Copy/Cut/Paste | Esc: Quit",
                     curses.A_DIM)


# Menu components updated to include the permissions shortcut
MENU_ITEMS = [
    ("i / k", "Move Up / Down"),
    ("I / K", "Jump Up/Down 3 Items"),
    ("l / Enter", "Open File / Enter Dir"),
    ("j", "Go to Parent Directory"),
    ("f", "Create New File"),
    ("d", "Create New Directory"),
    ("m", "Toggle Owner Permissions"),
    ("D (S-d)", "Delete File or Directory"),
    ("c / x", "Copy / Cut Selected Item"),
    ("p", "Paste Item Here"),
    ("/", "Real-time Search Filter"),
    ("Space", "Close Action Menu"),
    ("Esc / q", "Exit Explorer")
]

def render_menu(stdscr, height: int, width: int):
    menu_h = len(MENU_ITEMS) + 4
    menu_w = 46
    start_y = max(0, (height - menu_h) // 2)
    start_x = max(0, (width - menu_w) // 2)

    menu_win = stdscr.subwin(menu_h, menu_w, start_y, start_x)
    menu_win.erase()

    menu_win.attron(curses.color_pair(4) | curses.A_BOLD)
    menu_win.border()
    menu_win.attroff(curses.color_pair(4) | curses.A_BOLD)

    title = " MININETRW ACTIONS "
    title_x = max(1, (menu_w - len(title)) // 2)
    menu_win.addstr(0, title_x, title, curses.color_pair(4) | curses.A_BOLD)

    for idx, (key_bind, description) in enumerate(MENU_ITEMS):
        row = idx + 2
        menu_win.addstr(row, 3, f"{key_bind:>10}", curses.color_pair(3) | curses.A_BOLD)
        menu_win.addstr(row, 14, " │ ", curses.color_pair(4) | curses.A_DIM)
        menu_win.addstr(row, 17, f"{description:<26}", curses.A_NORMAL)

    menu_win.refresh()


def render_permission_menu(stdscr, filepath: str, height: int, width: int):
    """Renders a styled layout block modal to toggle standard UNIX file owner scopes."""
    menu_h = 9
    menu_w = 46
    start_y = max(0, (height - menu_h) // 2)
    start_x = max(0, (width - menu_w) // 2)

    perm_win = stdscr.subwin(menu_h, menu_w, start_y, start_x)
    perm_win.keypad(True)

    while True:
        perms = get_file_permissions(filepath)
        filename = os.path.basename(filepath)

        perm_win.erase()
        perm_win.attron(curses.color_pair(4) | curses.A_BOLD)
        perm_win.border()
        perm_win.attroff(curses.color_pair(4) | curses.A_BOLD)

        title = f" PERMISSIONS: {filename[:25]} "
        title_x = max(1, (menu_w - len(title)) // 2)
        perm_win.addstr(0, title_x, title, curses.color_pair(4) | curses.A_BOLD)

        # Render current execution state selections
        perm_win.addstr(2, 6, f"[ {'✓' if perms['r'] else ' '} ]   (r) Owner Read", curses.A_NORMAL)
        perm_win.addstr(3, 6, f"[ {'✓' if perms['w'] else ' '} ]   (w) Owner Write", curses.A_NORMAL)
        perm_win.addstr(4, 6, f"[ {'✓' if perms['x'] else ' '} ]   (x) Owner Execute", curses.A_NORMAL)

        perm_win.hline(6, 1, curses.ACS_HLINE, menu_w - 2, curses.color_pair(4) | curses.A_DIM)
        footer_text = "Press [r, w, x] to toggle | Esc/q to exit"
        perm_win.addstr(7, max(1, (menu_w - len(footer_text)) // 2), footer_text, curses.A_DIM)
        perm_win.refresh()

        ch = perm_win.getch()
        if ch in (ord('r'), ord('R')):
            toggle_permission(filepath, "r")
        elif ch in (ord('w'), ord('W')):
            toggle_permission(filepath, "w")
        elif ch in (ord('x'), ord('X')):
            toggle_permission(filepath, "x")
        elif ch in (ord('q'), ord('Q'), ESC_KEY, *ENTER_KEYS):
            break

# ─── Input Handlers ───────────────────────────────────────────────────────────

def handle_search_input(key: int, state: ExplorerState):
    if key == ESC_KEY:
        state.in_search_mode = False
        state.search_query = ""
        state.selected_idx = 0
    elif key in ENTER_KEYS:
        state.in_search_mode = False
    elif key in BACKSPACE_KEYS:
        state.search_query = state.search_query[:-1]
        state.selected_idx = 0
    elif 32 <= key <= 126:
        state.search_query += chr(key)
        state.selected_idx = 0


def handle_menu_input(key: int, state: ExplorerState):
    if key in (ord(' '), ESC_KEY):
        state.in_menu_mode = False
    elif key == ord('q'):
        state.should_quit = True


def handle_normal_input(stdscr, key: int, state: ExplorerState,
                        target_pane: str, height: int, width: int):
    state.status_message = ""
    state.status_type = ""

    if key in QUIT_KEYS:
        if state.search_query:
            state.search_query = ""
            state.selected_idx = 0
        else:
            state.should_quit = True
    elif key == ord(' '):
        state.in_menu_mode = True
    elif key == ord('/'):
        state.in_search_mode = True
    elif key in (ord('i'), curses.KEY_UP):
        state.selected_idx = max(state.selected_idx - 1, 0)
    elif key in (ord('k'), curses.KEY_DOWN):
        state.selected_idx = min(state.selected_idx + 1, len(state.entries) - 1)
    elif key == ord('I'):
        state.selected_idx = max(state.selected_idx - 3, 0)
    elif key == ord('K'):
        state.selected_idx = min(state.selected_idx + 3, len(state.entries) - 1)
    elif key in (ord('j'), curses.KEY_LEFT):
        old_dir = state.current_dir
        parent = os.path.dirname(old_dir)

        # Guard: If we're already at root, don't do anything
        if old_dir == parent:
            return

        # Target the parent directory and drop the search filter
        state.current_dir = parent if parent else "/"
        state.search_query = ""

        # Force an immediate directory read to locate the folder we just left
        state.all_entries = list_directory(state.current_dir)
        state.entries = filter_entries(state.all_entries, state.search_query)
        state.needs_refresh = False  # Main loop won't need to re-read now

        # Match the old folder name and update the selection index
        old_name = os.path.basename(old_dir)
        state.selected_idx = 0  # Fallback to top if not found for some reason
        for idx, (name, is_dir) in enumerate(state.entries):
            if is_dir and name == old_name:
                state.selected_idx = idx
                break
    elif key in (ord('l'),) + ENTER_KEYS:
        _handle_open(state, target_pane)
    elif key in (ord('f'), ord('d')):
        _handle_create(stdscr, key, state, height, width)
    elif key == ord('m'):
        _handle_permissions(stdscr, state, height, width)
    elif key == ord('D'):
        _handle_delete(stdscr, state, height, width)
    elif key in (ord('c'), ord('x')):
        _handle_copy_cut(key, state)
    elif key == ord('p'):
        _handle_paste(stdscr, state, height, width)


def _handle_open(state: ExplorerState, target_pane: str):
    if not state.entries:
        state.set_status("Directory is empty.", "info")
        return
    target, is_dir = state.entries[state.selected_idx]

    if target.startswith("["):
        state.set_status("Cannot open invalid entry.", "error")
        return

    next_path = os.path.join(state.current_dir, target)
    if is_dir:
        state.current_dir = next_path
        state.selected_idx = 0
        state.search_query = ""
        state.needs_refresh = True
    else:
        state.open_payload = os.path.abspath(next_path)
        state.should_quit = True

def _handle_create(stdscr, key: int, state: ExplorerState, height: int, width: int):
    prompt = ("New File: " if key == ord('f') else "New Dir: ")
    item_name = read_line_input(stdscr, prompt, height, width)
    curses.curs_set(0)
    if not item_name:
        state.set_status("Creation cancelled.", "info")
        return

    creation_target = os.path.join(state.current_dir, item_name)
    try:
        if key == ord('f'):
            os.makedirs(os.path.dirname(creation_target) or ".", exist_ok=True)
            with open(creation_target, 'x'):
                pass
        else:
            os.makedirs(creation_target, exist_ok=False)
        state.set_status(f"Created: {item_name}", "success")
        state.needs_refresh = True
    except FileExistsError:
        state.set_status(f"Already exists: {item_name}", "error")
    except OSError as exc:
        state.set_status(f"Error: {exc}", "error")


def _handle_permissions(stdscr, state: ExplorerState, height: int, width: int):
    if not state.entries:
        return
    target, _ = state.entries[state.selected_idx]
    if target.startswith("["):
        return

    target_path = os.path.join(state.current_dir, target)
    render_permission_menu(stdscr, target_path, height, width)


def _handle_delete(stdscr, state: ExplorerState, height: int, width: int):
    if not state.entries:
        return
    target, is_dir = state.entries[state.selected_idx]
    if target.startswith("["):
        return

    delete_target = os.path.join(state.current_dir, target)
    prompt = (f"Delete folder '{target}' recursively? [y/N]: " if is_dir else f"Delete file '{target}'? [y/N]: ")

    safe_addstr(stdscr, height - 2, 1, " " * (width - 3))
    safe_addstr(stdscr, height - 2, 2, prompt, curses.color_pair(2) | curses.A_BOLD)
    stdscr.refresh()

    confirm = stdscr.getch()
    if confirm in (ord('y'), ord('Y')):
        try:
            if is_dir:
                shutil.rmtree(delete_target)
            else:
                os.remove(delete_target)
            if state.clipboard_path == delete_target:
                state.clipboard_path = None
                state.clipboard_action = None
            state.selected_idx = min(state.selected_idx, len(state.entries) - 2)
            state.set_status(f"Deleted: {target}", "success")
            state.needs_refresh = True
        except OSError as exc:
            state.set_status(f"Error: {exc}", "error")
    else:
        state.set_status("Deletion cancelled.", "info")


def _handle_copy_cut(key: int, state: ExplorerState):
    if not state.entries:
        return
    target_name, _ = state.entries[state.selected_idx]
    if target_name.startswith("["):
        return

    state.clipboard_path = os.path.join(state.current_dir, target_name)
    state.clipboard_action = "copy" if key == ord('c') else "cut"
    verb = "Copied" if key == ord('c') else "Cut"
    state.set_status(f"{verb}: {target_name}", "success")


def _handle_paste(stdscr, state: ExplorerState, height: int, width: int):
    if not state.clipboard_path or not os.path.exists(state.clipboard_path):
        state.set_status("Clipboard empty or source missing!", "error")
        return

    src_path = state.clipboard_path
    src_dir = os.path.dirname(src_path)
    basename = os.path.basename(src_path)

    if os.path.abspath(src_dir) == os.path.abspath(state.current_dir):
        if state.clipboard_action == "cut":
            state.set_status("Nothing to paste (source is already here).", "info")
            return

        name, ext = os.path.splitext(basename)
        new_base = f"{name}_copy{ext}"
        counter = 1
        while os.path.exists(os.path.join(state.current_dir, new_base)):
            new_base = f"{name}_copy_{counter}{ext}"
            counter += 1

        destination = os.path.join(state.current_dir, new_base)
        try:
            if os.path.isdir(src_path):
                shutil.copytree(src_path, destination)
            else:
                shutil.copy2(src_path, destination)
            state.set_status(f"Duplicated: {new_base}", "success")
            state.needs_refresh = True
        except (OSError, shutil.Error) as exc:
            state.set_status(f"Duplicate error: {exc}", "error")
        return

    destination = os.path.join(state.current_dir, basename)

    if os.path.exists(destination):
        prompt = f"'{basename}' exists. New name (Esc to cancel): "
        new_name = read_line_input(stdscr, prompt, height, width)
        curses.curs_set(0)

        if new_name is None:
            state.set_status("Paste cancelled.", "info")
            return

        if new_name:
            destination = os.path.join(state.current_dir, new_name)

        if os.path.exists(destination):
            prompt = f"Overwrite '{os.path.basename(destination)}'? [y/N]: "
            safe_addstr(stdscr, height - 2, 1, " " * (width - 3))
            safe_addstr(stdscr, height - 2, 2, prompt, curses.color_pair(2) | curses.A_BOLD)
            stdscr.refresh()

            confirm = stdscr.getch()
            if confirm not in (ord('y'), ord('Y')):
                state.set_status("Paste cancelled.", "info")
                return

            try:
                if os.path.isdir(destination):
                    shutil.rmtree(destination)
                else:
                    os.remove(destination)
            except OSError as exc:
                state.set_status(f"Cannot clear target: {exc}", "error")
                return

    try:
        if state.clipboard_action == "copy":
            if os.path.isdir(src_path):
                shutil.copytree(src_path, destination)
            else:
                shutil.copy2(src_path, destination)
            state.set_status(f"Pasted (copy): {os.path.basename(destination)}", "success")
        elif state.clipboard_action == "cut":
            shutil.move(src_path, destination)
            state.clipboard_path = None
            state.clipboard_action = None
            state.set_status(f"Pasted (move): {os.path.basename(destination)}", "success")
        state.needs_refresh = True
    except (OSError, shutil.Error) as exc:
        state.set_status(f"Paste error: {exc}", "error")


# ─── Main Loop ────────────────────────────────────────────────────────────────

def run_explorer(stdscr, target_pane: str, start_dir: str):
    curses.start_color()
    curses.use_default_colors()  # Clean transparency handling

    # Structural UI Definitions
    curses.init_pair(1, curses.COLOR_GREEN, -1)   # Success Messaging
    curses.init_pair(2, curses.COLOR_RED, -1)     # Error Alerts
    curses.init_pair(3, curses.COLOR_YELLOW, -1)  # Warnings / Prompts
    curses.init_pair(4, curses.COLOR_BLUE, -1)    # Directories & Borders
    curses.init_pair(5, curses.COLOR_BLACK, curses.COLOR_CYAN) # High-contrast Selection Bar
    curses.init_pair(6, -1, -1)                   # Standard Files (Default Term Colors)

    curses.curs_set(0)
    stdscr.keypad(True)

    state = ExplorerState(current_dir=start_dir)

    while not state.should_quit:
        if state.needs_refresh:
            state.all_entries = list_directory(state.current_dir)
            state.needs_refresh = False

        state.entries = filter_entries(state.all_entries, state.search_query)

        if state.selected_idx >= len(state.entries):
            state.selected_idx = max(0, len(state.entries) - 1)

        render(stdscr, state)

        height, width = stdscr.getmaxyx()
        key = stdscr.getch()

        if key == -1:
            continue

        if state.in_menu_mode:
            handle_menu_input(key, state)
        elif state.in_search_mode:
            handle_search_input(key, state)
        else:
            handle_normal_input(stdscr, key, state, target_pane, height, width)

    return state.open_payload

# ─── Entry Point ──────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Usage: mininetrw.py <target_tmux_pane> [current_buffer_path]", file=sys.stderr)
        sys.exit(1)

    pane_id = sys.argv[1]

    # Resolve starting directory from the second argument if provided
    start_dir = os.getcwd()
    if len(sys.argv) >= 3 and sys.argv[2]:
        raw_path = sys.argv[2]

        # Guard against typical Helix scratch or empty buffer strings
        if raw_path not in ("", "*scratch*", "[No Name]", "New file"):
            # Expand ~ if present, then resolve relative elements safely
            expanded_path = os.path.expanduser(raw_path)
            provided_path = os.path.abspath(expanded_path)

            if os.path.isdir(provided_path):
                start_dir = provided_path
            else:
                # If it's a file path, extract its parent directory
                start_dir = os.path.dirname(provided_path)

    chosen_file = None

    try:
        chosen_file = curses.wrapper(run_explorer, pane_id, start_dir)
    except KeyboardInterrupt:
        sys.exit(0)
    except Exception as exc:
        curses.endwin()
        print(f"Fatal error: {exc}", file=sys.stderr)
        sys.exit(1)

    if chosen_file:
        send_to_tmux(pane_id, chosen_file)

    sys.exit(0)

if __name__ == "__main__":
    main()
