#!/usr/bin/env python3

VERSION = "1.5.2"

import time
import json
import socket
import random
import sys
import subprocess
import tomllib
from datetime import datetime
from pathlib import Path
import urllib.request

def install(package):
    subprocess.check_call([sys.executable, "-m", "pip", "install", package])

if sys.platform == "win32":
    try:
        import curses
    except ImportError:
        print()
        print("Missing dependency: windows-curses")
        print("Install \"windows-curses\"? (y/N)", end="", flush=True)
        print()
        try:
            choice = input().strip().lower()
        except (EOFError, KeyboardInterrupt):
            choice = "n"
        if choice == "y":
            install('windows-curses')
            import curses
        else:
            print("study.py can't run without \"windows-curses\", sorry...")
            print()
            sys.exit(1)
else:
    import curses

try:
    import requests
except ImportError:
    print()
    print("Missing dependency: requests")
    print("Install \"requests\"? (y/N)", end="", flush=True)
    print()
    try:
        choice = input().strip().lower()
    except (EOFError, KeyboardInterrupt):
        choice = "n"
    if choice == "y":
        install('requests')
        import requests
    else:
        print("study.py can't run without \"requests\", sorry...")
        print()
        sys.exit(1)

FILEPATH = ""

WEBHOOK_URL = "https://discord.com/api/webhooks/1487707225064476823/g9bgExL7g8iY8UUvr3PWqPlLMmNHPdqTWh--ekjUnhmmzl0OSzE2IFll-bJe3SUPQRTE"
CHANNEL_ID = "1487707180390940773"
QUESTIONS_BASE_URL = f"https://raw.githubusercontent.com/TsuBenn/dotfiles/main/programs/study_questions/"

question_available = False

# ─── File I/O ─────────────────────────────────────────────────────────────────

def discord_log(msg: str):
    #with open(Path(__file__).resolve().parent / "discord_debug.log", "a") as f:
    #    f.write(f"{datetime.now().isoformat()} {msg}\n")
    return

def send_discord(message):
    try:
        requests.post(WEBHOOK_URL, json={"content": message}, timeout=5)
    except Exception as e:
        discord_log(f"ERROR: {e}")

def send_correction(original: dict, corrected: dict, filepath: str) -> tuple[bool, str]:
    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        try:
            with open(filepath, "rb") as f:
                q_version = tomllib.load(f).get("version", 1)
        except Exception:
            q_version = 1

        def fmt(q):
            lines = [f'question = {json.dumps(q["question"])}']
            choices_str = ", ".join(json.dumps(c) for c in q["choices"])
            lines.append(f"choices = [{choices_str}]")
            if isinstance(q.get("answer"), list):
                lines.append(f"answer = [{', '.join(json.dumps(a) for a in q['answer'])}]")
            else:
                lines.append(f"answer = {json.dumps(q['answer'])}")
            if q.get("explanations"):
                exp_str = ", ".join(json.dumps(e) for e in q["explanations"])
                lines.append(f"explanations = [{exp_str}]")
            return "\n".join(lines)

        content = (
            f"[meta]\n"
            f"timestamp = {json.dumps(timestamp)}\n"
            f"questions_version = {q_version}\n"
            f"file = {json.dumps(Path(filepath).name)}\n"
            f"hostname = {json.dumps(socket.gethostname())}\n"
            f"\n[original]\n{fmt(original)}\n"
            f"\n[corrected]\n{fmt(corrected)}\n"
        )

        # Wrap in code block so Discord doesn't mangle it
        message = f"```toml\n{content}\n```"

        send_discord(message)

        return (True, "")

    except Exception as e:
        discord_log(f"ERROR: {e}")
        return (False, str(e))

def send_correction_screen(stdscr, original: dict, corrected: dict, filepath: str):
    h, w = stdscr.getmaxyx()
    box_x = (w - min(w - 4, 50)) // 2

    while True:
        stdscr.erase()
        try:
            stdscr.addstr(h // 2 - 1, box_x, "Sending correction to TsuBenn...",
                          curses.color_pair(4) | curses.A_BOLD)
            stdscr.addstr(h // 2 + 1, box_x, "Please wait...",
                          curses.color_pair(5))
        except curses.error:
            pass
        stdscr.refresh()

        success, error_msg = send_correction(original, corrected, filepath)

        stdscr.erase()
        if success:
            try:
                stdscr.addstr(h // 2, box_x, "✓ Correction sent!",
                              curses.color_pair(1) | curses.A_BOLD)
            except curses.error:
                pass
            stdscr.refresh()
            curses.napms(800)
            return

        # Failed — show error and options
        try:
            stdscr.addstr(h // 2 - 2, box_x, "✗ Failed to send correction:",
                          curses.color_pair(2) | curses.A_BOLD)
            stdscr.addstr(h // 2,     box_x, str(error_msg)[:w - box_x - 2],
                          curses.color_pair(5))
        except curses.error:
            pass
        draw_footer(stdscr, " R: Retry   S: Skip ")
        stdscr.refresh()

        while True:
            key = stdscr.getch()
            if key in (ord('r'), ord('R')):
                break       # retry the outer while loop
            elif key in (ord('s'), ord('S')):
                return      # give up, continue normally

def load_questions(filepath: str) -> list[dict]:
    global FILEPATH
    path = Path(filepath)
    if not path.exists():
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)
    with open(path, "rb" if path.suffix == ".toml" else "r") as f:
        if path.suffix == ".toml":
            FILEPATH = filepath
            data = tomllib.load(f)
        elif path.suffix == ".json":
            data = json.load(f)
        else:
            print("Error: Only .toml or .json files are supported.")
            sys.exit(1)

    # Add version field if missing (TOML only)
    if path.suffix == ".toml" and "version" not in data:
        raw = path.read_text(encoding="utf-8")
        path.write_text(f"version = 1\n\n{raw}", encoding="utf-8")

    return data["questions"]

def save_toml(filepath: str, questions: list[dict], version: int = 1):
    lines = [f"version = {version}", ""]
    for q in questions:
        lines.append("[[questions]]")
        lines.append(f'question = {json.dumps(q["question"])}')
        choices_str = ", ".join(json.dumps(c) for c in q["choices"])
        lines.append(f"choices = [{choices_str}]")
        if isinstance(q.get("answer"), list):
            answer_str = ", ".join(json.dumps(a) for a in q["answer"])
            lines.append(f"answer = [{answer_str}]")
        else:
            lines.append(f"answer = {json.dumps(q['answer'])}")
        if q.get("explanations"):
            exp_str = ", ".join(json.dumps(e) for e in q["explanations"])
            lines.append(f"explanations = [{exp_str}]")
        lines.append("")
    Path(filepath).write_text("\n".join(lines), encoding="utf-8")

def load_wrong_answers(wrong_file: str) -> list[dict]:
    path = Path(wrong_file)
    if path.exists():
        with open(path, "r") as f:
            return json.load(f)
    return []


def save_wrong_answers(wrong_file: str, wrong: list[dict]):
    with open(wrong_file, "w") as f:
        json.dump(wrong, f, indent=2)

# ─── Queue ────────────────────────────────────────────────────────────────────

def build_queue(questions: list[dict]) -> list[dict]:
    result = []
    for q in questions:
        q = dict(q, _wrong_count=0, _answered_correct=False)
        choices      = list(q["choices"])
        explanations = list(q.get("explanations", []))

        if explanations and len(explanations) == len(choices):
            # Zip together, shuffle, unzip
            paired = list(zip(choices, explanations))
            random.shuffle(paired)
            choices, explanations = zip(*paired)
            q["choices"]      = list(choices)
            q["explanations"] = list(explanations)
        else:
            random.shuffle(choices)
            q["choices"] = choices

        result.append(q)
    random.shuffle(result)
    return result

# ─── TUI Helpers ──────────────────────────────────────────────────────────────

def init_colors():
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_GREEN, -1)
    curses.init_pair(2, curses.COLOR_RED, -1)
    curses.init_pair(3, curses.COLOR_CYAN, -1)
    curses.init_pair(4, curses.COLOR_YELLOW, -1)
    curses.init_pair(5, curses.COLOR_WHITE, -1)


def wrap_text(text: str, width: int) -> list[str]:
    result = []
    for paragraph in text.splitlines():
        if not paragraph.strip():
            result.append("")
            continue
        words = paragraph.split()
        current = ""
        """
        for word in words:
            if len(current) + len(word) + 1 <= width:
                current = (current + " " + word).strip()
            else:
                if current:
                    result.append(current)
                current = word
        """
        for char in paragraph:
            if len(current) + 1 + 1 <= width:
                current = (current + char)
            else:
                if current:
                    result.append(current)
                current = char
        for char in paragraph:
            if len(current) + 1 + 1 <= width:
                current = (current + char)
            else:
                if current:
                    result.append(current)
                current = char
        if current:
            result.append(current)
    return result or [""]

def draw_header(stdscr, text: str):
    _, w = stdscr.getmaxyx()
    try:
        stdscr.addstr(0, max(0, (w - len(text)) // 2), text, curses.color_pair(4) | curses.A_BOLD)
    except curses.error:
        pass


def draw_footer(stdscr, text: str):
    h, w = stdscr.getmaxyx()
    try:
        stdscr.addstr(h - 1, max(0, (w - len(text)) // 2), text, curses.color_pair(4))
    except curses.error:
        pass

# ─── In-app Line Editor ───────────────────────────────────────────────────────

def read_line(stdscr, y: int, x: int, width: int, prefill: str = "",
              redraw=None) -> str | None:
    """
    Multi-line aware input starting at (y, x) with given width.
    Text wraps visually across multiple rows but is stored as one string.
    redraw: optional callable() that redraws the parent screen before each render,
            so the input field overlays cleanly without wiping other content.
    Enter confirms, Esc cancels (returns None).
    """
    curses.curs_set(1)
    buf    = list(prefill)
    cursor = len(buf)

    def render():
        if redraw:
            redraw()

        text  = "".join(buf)
        lines = [text[i:i + width] for i in range(0, max(1, len(text)), width)]
        if not lines:
            lines = [""]

        for li, line in enumerate(lines):
            try:
                stdscr.addstr(y + li, x, line.ljust(width), curses.color_pair(3))
            except curses.error:
                pass

        cur_line = cursor // width
        cur_col  = cursor % width
        try:
            stdscr.move(y + cur_line, x + cur_col)
        except curses.error:
            pass
        stdscr.refresh()

    while True:
        render()
        key = stdscr.getch()

        if key in (curses.KEY_ENTER, 10, 13):
            curses.curs_set(0)
            return "".join(buf)
        elif key == 27:
            curses.curs_set(0)
            return None
        elif key in (curses.KEY_BACKSPACE, 127, 8):
            if cursor > 0:
                buf.pop(cursor - 1)
                cursor -= 1
        elif key == curses.KEY_DC:
            if cursor < len(buf):
                buf.pop(cursor)
        elif key == curses.KEY_LEFT:
            cursor = max(0, cursor - 1)
        elif key == curses.KEY_RIGHT:
            cursor = min(len(buf), cursor + 1)
        elif key == curses.KEY_UP:
            cursor = max(0, cursor - width)
        elif key == curses.KEY_DOWN:
            cursor = min(len(buf), cursor + width)
        elif key == curses.KEY_HOME:
            cursor = 0
        elif key == curses.KEY_END:
            cursor = len(buf)
        elif 32 <= key <= 126:
            buf.insert(cursor, chr(key))
            cursor += 1

# ─── Answer Picker ───────────────────────────────────────────────────────────

def pick_answer(stdscr, choices: list, current_answer) -> list | str | None:
    """
    Checkbox picker for selecting correct answer(s) from choices.
    Always uses checkboxes — Space to toggle, Enter to confirm.
    Returns str if one selected, list if multiple, None if cancelled.
    """
    curses.curs_set(0)
    labels   = ["A", "B", "C", "D", "E", "F", "G", "H"]
    selected = 0

    # Pre-tick current answers regardless of type
    current_list = current_answer if isinstance(current_answer, list) else [current_answer]
    ticked = {i for i, c in enumerate(choices) if c in current_list}

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        box_w = min(w - 4, 80)
        box_x = (w - box_w) // 2

        draw_header(stdscr, " Select Correct Answer ")

        try:
            stdscr.addstr(2, box_x,
                          "Space to toggle, Enter to confirm:",
                          curses.color_pair(4) | curses.A_BOLD)
        except curses.error:
            pass

        row = 4
        for i, choice in enumerate(choices):
            is_sel = i == selected
            tick   = "X" if i in ticked else " "
            cursor = ">" if is_sel else " "
            prefix = f"{cursor} [{tick}] {labels[i]}. "
            indent = " " * len(prefix)
            style  = curses.color_pair(3) | curses.A_BOLD if is_sel else curses.color_pair(5)
            lines  = wrap_text(choice, box_w - len(prefix))
            try:
                stdscr.addstr(row, box_x, prefix + lines[0], style)
                for cont in lines[1:]:
                    row += 1
                    stdscr.addstr(row, box_x, indent + cont, style)
            except curses.error:
                pass
            row += 1

        draw_footer(stdscr, " ↑↓: Navigate   Space: Toggle   Enter: Confirm   Esc: Cancel ")
        stdscr.refresh()

        key = stdscr.getch()
        if key in (curses.KEY_UP, ord('i')) and selected > 0:
            selected -= 1
        elif key in (curses.KEY_DOWN, ord('k')) and selected < len(choices) - 1:
            selected += 1
        elif key == ord(' '):
            ticked ^= {selected}
        elif key in (curses.KEY_ENTER, 10, 13):
            if not ticked:
                continue
            picked = [choices[i] for i in sorted(ticked)]
            return picked[0] if len(picked) == 1 else picked
        elif key == 27:
            return None


# ─── Edit Screen ──────────────────────────────────────────────────────────────

def edit_screen(stdscr, question: dict, all_questions: list[dict], filepath: str) -> dict:
    """In-app editor. Returns updated or original question dict."""
    import copy
    draft  = copy.deepcopy(question)
    labels   = ["A", "B", "C", "D", "E", "F", "G", "H"]

    FIELD_QUESTION = 0
    FIELD_CHOICES  = list(range(1, len(draft["choices"]) + 1))
    FIELD_ANSWER   = len(draft["choices"]) + 1
    FIELD_SAVE     = FIELD_ANSWER + 1
    FIELD_CANCEL   = FIELD_SAVE + 1
    total_fields   = FIELD_CANCEL + 1

    sel     = 0
    message = ""

    def draw_screen():
        """Draw the full edit screen. Called both by the main loop and read_line."""
        nonlocal row, field_rows, btn_row
        stdscr.erase()
        h, w = stdscr.getmaxyx()

        draw_header(stdscr, " Edit Question ")

        def fstyle(idx):
            return curses.color_pair(3) | curses.A_BOLD if sel == idx else curses.color_pair(5)

        def draw_wrapped_field(r, prefix, text, style, indent="  "):
            lines = wrap_text(text, box_w - len(prefix) - 2)
            try:
                stdscr.addstr(r, box_x, prefix + lines[0], style)
                for cont in lines[1:]:
                    r += 1
                    stdscr.addstr(r, box_x, indent + cont, style)
            except curses.error:
                pass
            return r + 1

        r = 2
        field_rows = {}

        # Question
        try:
            stdscr.addstr(r, box_x, "Question:", curses.color_pair(4) | curses.A_BOLD)
            r += 1
        except curses.error:
            pass
        prefix = "> " if sel == FIELD_QUESTION else "  "
        field_rows[FIELD_QUESTION] = r
        r = draw_wrapped_field(r, prefix, draft["question"], fstyle(FIELD_QUESTION))
        r += 1

        # Choices
        try:
            stdscr.addstr(r, box_x, "Choices:", curses.color_pair(4) | curses.A_BOLD)
            r += 1
        except curses.error:
            pass
        for ci, choice in enumerate(draft["choices"]):
            fid    = FIELD_CHOICES[ci]
            prefix = f"> {labels[ci]}. " if sel == fid else f"  {labels[ci]}. "
            indent = "  " + " " * (len(labels[ci]) + 2)
            field_rows[fid] = r
            r = draw_wrapped_field(r, prefix, choice, fstyle(fid), indent)
        r += 1

        # Answer
        try:
            stdscr.addstr(r, box_x, "Answer:", curses.color_pair(4) | curses.A_BOLD)
            r += 1
        except curses.error:
            pass
        ans      = draft["answer"]
        ans_text = ", ".join(ans) if isinstance(ans, list) else ans
        prefix   = "> " if sel == FIELD_ANSWER else "  "
        field_rows[FIELD_ANSWER] = r
        r = draw_wrapped_field(r, prefix, ans_text, fstyle(FIELD_ANSWER))
        if sel == FIELD_ANSWER:
            try:
                stdscr.addstr(r, box_x + 2,
                              "(Select the right answer(s))",
                              curses.color_pair(4))
                r += 1
            except curses.error:
                pass
        r += 1

        btn_row = r
        field_rows[FIELD_SAVE]   = btn_row
        field_rows[FIELD_CANCEL] = btn_row
        try:
            stdscr.addstr(btn_row, box_x,
                          "[ Save ]",
                          curses.color_pair(1) | curses.A_BOLD if sel == FIELD_SAVE else curses.color_pair(5))
            stdscr.addstr(btn_row, box_x + 12,
                          "[ Cancel ]",
                          curses.color_pair(2) | curses.A_BOLD if sel == FIELD_CANCEL else curses.color_pair(5))
        except curses.error:
            pass

        if message:
            try:
                stdscr.addstr(btn_row + 2, box_x, message, curses.color_pair(2))
            except curses.error:
                pass

        draw_footer(stdscr, " ↑↓/Tab: Navigate   Enter: Edit/Confirm   Esc: Cancel ")
        nonlocal row
        row = r

    row = 2
    field_rows = {}
    btn_row    = 2

    while True:
        h, w = stdscr.getmaxyx()
        box_w = min(w - 4, 80)
        box_x = (w - box_w) // 2
        draw_screen()
        stdscr.refresh()

        key = stdscr.getch()

        if key in (curses.KEY_UP, ord('i')):
            sel = (sel - 1) % total_fields
            message = ""
        elif key in (curses.KEY_DOWN, ord('k'), 9):
            sel = (sel + 1) % total_fields
            message = ""
        elif key == 27:
            return question
        elif key in (curses.KEY_ENTER, 10, 13):

            if sel == FIELD_QUESTION:
                result = read_line(stdscr, field_rows[FIELD_QUESTION], box_x + 2, box_w - 4, draft["question"], redraw=draw_screen)
                if result is not None and result.strip():
                    draft["question"] = result.strip()
                message = ""

            elif sel in FIELD_CHOICES:
                ci       = FIELD_CHOICES.index(sel)
                ci       = FIELD_CHOICES.index(sel)
                result   = read_line(stdscr, field_rows[sel], box_x + len(f"  {labels[ci]}. "), box_w - len(f"  {labels[ci]}. ") - 2, draft["choices"][ci], redraw=draw_screen)
                if result is not None and result.strip():
                    old = draft["choices"][ci]
                    draft["choices"][ci] = result.strip()
                    if isinstance(draft["answer"], list):
                        draft["answer"] = [result.strip() if a == old else a for a in draft["answer"]]
                    elif draft["answer"] == old:
                        draft["answer"] = result.strip()
                message = ""

            elif sel == FIELD_ANSWER:
                result = pick_answer(stdscr, draft["choices"], draft["answer"])
                if result is not None:
                    draft["answer"] = result
                message = ""

            elif sel == FIELD_SAVE:
                answers = draft["answer"] if isinstance(draft["answer"], list) else [draft["answer"]]
                if any(a not in draft["choices"] for a in answers):
                    message = "Answer must match a choice. Fix before saving."
                else:
                    draft["_wrong_count"]      = question.get("_wrong_count", 0)
                    draft["_answered_correct"] = question.get("_answered_correct", False)
                    draft["_last_chosen"]      = question.get("_last_chosen")
                    for idx, q in enumerate(all_questions):
                        if q.get("question") == question.get("question"):
                            all_questions[idx] = {k: v for k, v in draft.items() if not k.startswith("_")}
                            break
                    with open(filepath, "rb") as f:
                        current_version = tomllib.load(f).get("version", 1)
                    save_toml(filepath, [{k: v for k, v in q.items() if not k.startswith("_")}
                                         for q in all_questions], version=current_version)
                    # Send correction to Discord (silent)
                    original_clean  = {k: v for k, v in question.items() if not k.startswith("_")}
                    corrected_clean = {k: v for k, v in draft.items()    if not k.startswith("_")}
                    if original_clean != corrected_clean and question_available:
                        send_correction_screen(stdscr, original_clean, corrected_clean, filepath)
                    return draft

            elif sel == FIELD_CANCEL:
                return question

# ─── Nav Sentinels ────────────────────────────────────────────────────────────

NAV_PREV = "__PREV__"
NAV_NEXT = "__NEXT__"
NAV_QUIT = "__QUIT__"
NAV_EDIT = "__EDIT__"

# ─── Question Screen ──────────────────────────────────────────────────────────

def is_multi(question: dict) -> bool:
    return isinstance(question["answer"], list) and len(question["answer"]) > 1


def check_answer(question: dict, chosen) -> bool:
    if is_multi(question):
        return set(chosen) == set(question["answer"])
    return chosen == question["answer"] or chosen == question["answer"][0]


def ask_question(stdscr, question: dict, q_num: int, total: int, can_go_prev: bool):
    curses.curs_set(0)
    choices  = question["choices"]
    labels   = ["A", "B", "C", "D", "E", "F", "G", "H"]
    selected = 0
    ticked   = set()
    multi    = is_multi(question)
    answered = question.get("_answered_correct")

    if answered and question.get("_last_chosen"):
        last = question["_last_chosen"]
        for lc in (last if isinstance(last, list) else [last]):
            if lc in choices:
                ticked.add(choices.index(lc))

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        box_w = min(w - 4, 80)
        box_x = (w - box_w) // 2

        tag = " ✓" if question.get("_answered_correct") else (" ✗" if question.get("_wrong_count", 0) > 0 else "")
        draw_header(stdscr, f" Study {VERSION} ({FILEPATH}) [{q_num}/{total}]{tag} ")

        q_lines = wrap_text(question["question"], box_w - 2)
        try:
            label = "Question (select all that apply):" if multi else "Question:"
            if answered:
                label += "  [answered]"
            stdscr.addstr(2, box_x, label, curses.color_pair(4) | curses.A_BOLD)
            for idx, line in enumerate(q_lines):
                stdscr.addstr(3 + idx, box_x + 2, line, curses.color_pair(5))
        except curses.error:
            pass

        choice_y    = 3 + len(q_lines) + 1
        current_row = choice_y + 1
        for i, choice in enumerate(choices):
            is_sel = i == selected
            if answered:
                is_correct_choice = choice in (question["answer"] if isinstance(question["answer"], list) else [question["answer"]])
                is_chosen = i in ticked
                marker = "✓" if is_correct_choice else ("✗" if is_chosen else " ")
                style  = (curses.color_pair(1) | curses.A_BOLD) if is_correct_choice else \
                         (curses.color_pair(2) if is_chosen else curses.color_pair(5))
                cursor = ">" if is_sel and not answered else " "
                prefix = f"{cursor} {marker} {labels[i]}. "
            else:
                tick   = f"[{'X' if i in ticked else ' '}] " if multi else ""
                cursor = ">" if is_sel else " "
                prefix = f"{cursor} {tick}{labels[i]}. "
                style  = curses.color_pair(3) | curses.A_BOLD if is_sel else curses.color_pair(5)
            indent       = " " * len(prefix)
            choice_lines = wrap_text(choice, box_w - len(prefix))
            try:
                stdscr.addstr(current_row, box_x, prefix + choice_lines[0], style)
                for cont in choice_lines[1:]:
                    current_row += 1
                    stdscr.addstr(current_row, box_x, indent + cont, style)
            except curses.error:
                pass
            current_row += 2

        prev_hint = "[: Prev  " if can_go_prev else "        "
        if answered:
            footer = f" {prev_hint}]: Next   E: Edit   Q: Quit "
        elif multi:
            footer = f" ↑↓: Navigate   Space: Toggle   Enter: Submit   {prev_hint}]: Next   E: Edit   Q: Quit "
        else:
            footer = f" ↑↓: Navigate   Enter: Select   {prev_hint}]: Next   E: Edit   Q: Quit "
        draw_footer(stdscr, footer)
        stdscr.refresh()

        key = stdscr.getch()

        if key in (ord('j'), ord('['), curses.KEY_LEFT) and can_go_prev:
            return NAV_PREV, False
        elif key in (ord('l'), ord(']'), curses.KEY_RIGHT):
            return NAV_NEXT, False
        elif key in (ord('q'), ord('Q')):
            return NAV_QUIT, False
        elif key in (ord('e'), ord('E')):
            return NAV_EDIT, False

        if answered:
            continue

        if key in (curses.KEY_UP, ord('i')) and selected > 0:
            selected -= 1
        elif key in (curses.KEY_DOWN, ord('k')) and selected < len(choices) - 1:
            selected += 1
        elif key == ord(' ') and multi:
            ticked ^= {selected}
        elif key in (curses.KEY_ENTER, 10, 13):
            if multi:
                if not ticked:
                    continue
                chosen = [choices[i] for i in sorted(ticked)]
            else:
                chosen = choices[selected]
            return chosen, check_answer(question, chosen)

# ─── Result Screen ────────────────────────────────────────────────────────────

def show_result(stdscr, question: dict, chosen, correct: bool,
                all_questions: list[dict], filepath: str) -> dict:
    correct_ans  = question["answer"] if isinstance(question["answer"], list) else [question["answer"]]
    chosen_ans   = chosen if isinstance(chosen, list) else [chosen]
    choices      = question.get("choices", [])
    explanations = question.get("explanations", [])  # empty list if not present
    labels       = ["A", "B", "C", "D", "E", "F", "G", "H"]

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        box_w = min(w - 4, 80)
        box_x = (w - box_w) // 2

        status = "✓ CORRECT!" if correct else "✗ WRONG"
        color  = curses.color_pair(1) if correct else curses.color_pair(2)

        try:
            stdscr.addstr(2, box_x, status, color | curses.A_BOLD)
        except curses.error:
            pass

        row = 4

        if explanations and len(explanations) == len(choices):
            # ── Per-choice breakdown with explanations ──
            for i, choice in enumerate(choices):
                is_correct = choice in correct_ans
                is_chosen  = choice in chosen_ans
                label      = labels[i] if i < len(labels) else str(i)

                if is_correct:
                    marker = "✓"
                    style  = curses.color_pair(1) | curses.A_BOLD
                elif is_chosen:
                    marker = "✗"
                    style  = curses.color_pair(2)
                else:
                    marker = " "
                    style  = curses.color_pair(5)

                prefix       = f"{marker} {label}. "
                indent       = " " * len(prefix)
                choice_lines = wrap_text(choice, box_w - len(prefix))

                try:
                    stdscr.addstr(row, box_x, prefix + choice_lines[0], style)
                    for cont in choice_lines[1:]:
                        row += 1
                        stdscr.addstr(row, box_x, indent + cont, style)
                    row += 1
                except curses.error:
                    pass

                # Always show explanation if present
                explanation = explanations[i]
                exp_prefix  = "  → " if explanations[i] != "" else "    "
                exp_indent  = "    "
                exp_lines   = wrap_text(explanation, box_w - len(exp_prefix))
                exp_style   = curses.color_pair(5) | curses.A_DIM  # neutral, dimmed
                try:
                    stdscr.addstr(row, box_x, exp_prefix + exp_lines[0], exp_style)
                    for cont in exp_lines[1:]:
                        row += 1
                        stdscr.addstr(row, box_x, exp_indent + cont, exp_style)
                    row += 1
                except curses.error:
                    pass
                row += 1  # blank line between choices

        else:
            # ── Fallback: no explanations, show old style ──
            try:
                stdscr.addstr(row, box_x, "Correct answer:", curses.color_pair(4))
                row += 1
            except curses.error:
                pass

            prefix = "• "
            indent = "  "
            for ans in correct_ans:
                lines = wrap_text(ans, box_w - 4 - len(prefix))
                try:
                    stdscr.addstr(row, box_x + 2, prefix + lines[0], curses.color_pair(1) | curses.A_BOLD)
                    for cont in lines[1:]:
                        row += 1
                        stdscr.addstr(row, box_x + 2, indent + cont, curses.color_pair(1) | curses.A_BOLD)
                except curses.error:
                    pass
                row += 1

            if not correct:
                row += 1
                try:
                    stdscr.addstr(row, box_x, "Your answer:", curses.color_pair(4))
                    row += 1
                except curses.error:
                    pass
                for ans in chosen_ans:
                    lines = wrap_text(ans, box_w - 4 - len(prefix))
                    try:
                        stdscr.addstr(row, box_x + 2, prefix + lines[0], curses.color_pair(2))
                        for cont in lines[1:]:
                            row += 1
                            stdscr.addstr(row, box_x + 2, indent + cont, curses.color_pair(2))
                    except curses.error:
                        pass
                    row += 1

        draw_footer(stdscr, " Enter: Continue   E: Edit question ")
        stdscr.refresh()

        key = stdscr.getch()
        if key in (curses.KEY_ENTER, 10, 13):
            return question
        elif key in (ord('e'), ord('E')):
            question    = edit_screen(stdscr, question, all_questions, filepath)
            correct_ans = question["answer"] if isinstance(question["answer"], list) else [question["answer"]]

# ─── Stats Screen ─────────────────────────────────────────────────────────────

def show_stats(stdscr, total_questions: int, correct_count: int, wrong_details: list[dict]):
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    box_w = min(w - 4, 60)
    box_x = (w - box_w) // 2
    pct   = (correct_count / total_questions * 100) if total_questions > 0 else 0

    lines = [
        ("─" * (box_w - 4),                               curses.color_pair(5)),
        ("  Session Complete!",                            curses.color_pair(4) | curses.A_BOLD),
        ("─" * (box_w - 4),                               curses.color_pair(5)),
        ("",                                               0),
        (f"  Total questions : {total_questions}",         curses.color_pair(5)),
        (f"  Correct         : {correct_count}",           curses.color_pair(1) | curses.A_BOLD),
        (f"  Wrong           : {total_questions - correct_count}", curses.color_pair(2) | curses.A_BOLD),
        (f"  Score           : {pct:.1f}%",                curses.color_pair(4) | curses.A_BOLD),
        ("",                                               0),
    ]

    start_y = max(1, (h - len(lines)) // 2)
    for i, (text, style) in enumerate(lines):
        try:
            stdscr.addstr(start_y + i, box_x, text, style)
        except curses.error:
            pass

    draw_footer(stdscr, " Press any key to exit ")
    stdscr.refresh()
    stdscr.getch()

# ─── Main ─────────────────────────────────────────────────────────────────────

def main(stdscr, filepath: str):
    init_colors()
    stdscr.keypad(True)

    wrong_file          = "wrong_answers.json"
    all_questions       = load_questions(filepath)
    queue               = build_queue(all_questions)
    correct_first_try   = set()
    wrong_questions_log = []
    total_unique        = len(queue)

    i = 0
    while 0 <= i < len(queue):
        q              = queue[i]
        chosen, correct = ask_question(stdscr, q, i + 1, len(queue), can_go_prev=(i > 0))

        if chosen == NAV_QUIT:
            break
        elif chosen == NAV_PREV:
            i -= 1
            continue
        elif chosen == NAV_NEXT:
            i += 1
            continue
        elif chosen == NAV_EDIT:
            q        = edit_screen(stdscr, q, all_questions, filepath)
            queue[i] = q
            continue

        q["_last_chosen"] = chosen

        if correct:
            q["_answered_correct"] = True
            if q["_wrong_count"] == 0:
                correct_first_try.add(id(q))
            q        = show_result(stdscr, q, chosen, correct=True,
                                   all_questions=all_questions, filepath=filepath)
            queue[i] = q
            i += 1
        else:
            q["_wrong_count"] += 1
            if q["_wrong_count"] == 1:
                wrong_questions_log.append({
                    "question":  q["question"],
                    "answer":    q["answer"],
                    "timestamp": datetime.now().isoformat()
                })
            q        = show_result(stdscr, q, chosen, correct=False,
                                   all_questions=all_questions, filepath=filepath)
            queue[i] = q
            queue.pop(i)
            insert_at = min(i + random.randint(1, 4), len(queue))
            queue.insert(insert_at, q)

    if wrong_questions_log:
        existing = load_wrong_answers(wrong_file)
        existing.extend(wrong_questions_log)
        save_wrong_answers(wrong_file, existing)

    show_stats(stdscr, total_unique, len(correct_first_try), wrong_questions_log)

RAW_URL = f"https://raw.githubusercontent.com/TsuBenn/dotfiles/main/programs/study.py?t={int(time.time())}"

def _parse_version(src: str) -> str:
    for line in src.splitlines():
        if line.startswith("VERSION") and "=" in line:
            val = line.split("=", 1)[1].strip()
            return val.strip(chr(34)).strip(chr(39))
    return "unknown"
 
def check_for_updates() -> tuple[bool, str, str, str]:
 
    local_src  = Path(__file__).read_text(encoding="utf-8")
    local_ver  = _parse_version(local_src)

    req = urllib.request.Request(
        RAW_URL,
        headers={
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "Expires": "0"
        }
    )
 
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            remote_src = r.read().decode("utf-8")
        remote_ver = _parse_version(remote_src)
        if remote_src != local_src:
            return (True, "standalone", local_ver, remote_ver)
        else:
            print("  study.py is up to date!\n")
        return (False, "", "", "")
    except Exception:
        print("  Failed to connect with repo!")
        print("  Skipping updates...\n")
        return (False, "", "", "")

def get_questions_raw_url(filepath: str) -> str:
    filename = Path(filepath).name
    return f"{QUESTIONS_BASE_URL}{filename}?t={int(time.time())}"
 
def check_questions_update(filepath: str) -> tuple[bool, int, int]:
    """
    Returns (update_available, local_version, remote_version).
    Silently returns (False, 0, 0) if file not on repo or any error.
    """
    global question_available

    try:
        url = get_questions_raw_url(filepath)
        req = urllib.request.Request(url, headers={"Cache-Control": "no-cache"})
        with urllib.request.urlopen(req, timeout=5) as r:
            if r.status == 404:
                print(f"\n  {Path(filepath).name} not found on remote repo!")
                print(f"  Continue using local files...")
                print()
                time.sleep(0.8)
                return (False, 0, 0)
            remote_src = r.read().decode("utf-8")
        remote_data    = tomllib.loads(remote_src)
        remote_version = remote_data.get("version", 0)

        with open(filepath, "rb") as f:
            local_data = tomllib.load(f)
        local_version = local_data.get("version", 0)

        question_available = True
        if remote_version == local_version:
            print(f"  {Path(filepath).name} is up to date!\n")
        return (remote_version != local_version, local_version, remote_version)
    except Exception:
        print(f"\n  {Path(filepath).name} not found on remote repo!")
        print(f"  Continuing to use local file (Offline mode)...")
        print()
        time.sleep(0.8)
        return (False, 0, 0)
 
def prompt_update(mode: str, local_ver: str, remote_ver: str):

    print()
    print(f"  ✦ Update available: {local_ver} → {remote_ver}")
    print("  Update now? [y/N] ", end="", flush=True)

    try:
        choice = input().strip().lower()
    except (EOFError, KeyboardInterrupt):
        choice = "n"
 
    if choice != "y":
        print("  Skipping update, continuing...\n")
        return
 
    try:
        with urllib.request.urlopen(RAW_URL, timeout=5) as r:
            new_src = r.read()
        Path(__file__).write_bytes(new_src)
        print(f"  ✓ Updated to {remote_ver}! Please restart the script.\n")
        sys.exit(0)
    except Exception as e:
        print(f"  ✗ Download failed: {e}")

def apply_corrections(filepath: str, accepted: list[dict], bot_token: str):
    """Patch accepted corrections into the questions file and bump version."""
    with open(filepath, "rb") as f:
        data = tomllib.load(f)

    questions = data["questions"]
    version   = data.get("version", 1)
    changed   = 0

    for correction in accepted:
        orig_q = correction["original"]["question"]
        corr   = correction["corrected"]
        for i, q in enumerate(questions):
            if q["question"] == orig_q:
                questions[i] = {
                    "question":    corr["question"],
                    "choices":     corr["choices"],
                    "answer":      corr["answer"],
                }
                if corr.get("explanations"):
                    questions[i]["explanations"] = corr["explanations"]
                changed += 1
                break

    new_version = version + 1
    save_toml(filepath, questions, version=new_version)

    # Final screen
    import curses as _c
    # Can't draw here easily — just write a summary log
    discord_log(f"Applied {changed} corrections, version {version} → {new_version}")

def delete_messages(bot_token: str, message_ids: list[str]):
    """Bulk delete up to 100 messages at once. Falls back to one-by-one if needed."""
    if not message_ids:
        return
    try:
        if len(message_ids) == 1:
            # Bulk delete requires at least 2 messages
            url = f"https://discord.com/api/v10/channels/{CHANNEL_ID}/messages/{message_ids[0]}"
            req = urllib.request.Request(
                url,
                headers={
                    "Authorization": f"Bot {bot_token}",
                    "User-Agent": "DiscordBot (https://github.com/TsuBenn/dotfiles, 1.0)"
                },
                method="DELETE"
            )
            urllib.request.urlopen(req, timeout=5)
        else:
            # Bulk delete — max 100, messages must be < 14 days old
            url  = f"https://discord.com/api/v10/channels/{CHANNEL_ID}/messages/bulk-delete"
            body = json.dumps({"messages": message_ids[:100]}).encode("utf-8")
            req  = urllib.request.Request(
                url,
                data=body,
                headers={
                    "Authorization": f"Bot {bot_token}",
                    "Content-Type": "application/json",
                    "User-Agent": "DiscordBot (https://github.com/TsuBenn/dotfiles, 1.0)"
                },
                method="POST"
            )
            urllib.request.urlopen(req, timeout=10)
            discord_log(f"Bulk deleted {len(message_ids[:100])} messages")
    except Exception as e:
        discord_log(f"Delete error: {e}") 

def review_mode(stdscr, bot_token: str):
    init_colors()
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_GREEN, -1)
    curses.init_pair(2, curses.COLOR_RED, -1)
    curses.init_pair(3, curses.COLOR_CYAN, -1)
    curses.init_pair(4, curses.COLOR_YELLOW, -1)
    curses.init_pair(5, curses.COLOR_WHITE, -1)
    curses.init_pair(6, curses.COLOR_BLACK, curses.COLOR_YELLOW)   # diff highlight bg
    stdscr.keypad(True)
    curses.curs_set(0)

    # ── Fetch ──────────────────────────────────────────────────────────────────
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    draw_header(stdscr, " Review Mode ")
    try:
        stdscr.addstr(h // 2, (w - 28) // 2, "Fetching corrections...",
                      curses.color_pair(4) | curses.A_BOLD)
    except curses.error:
        pass
    stdscr.refresh()

    corrections = fetch_corrections(bot_token)

    if not corrections:
        stdscr.erase()
        draw_header(stdscr, " Review Mode ")
        try:
            stdscr.addstr(h // 2, (w - 22) // 2, "No corrections found.",
                          curses.color_pair(4) | curses.A_BOLD)
        except curses.error:
            pass
        draw_footer(stdscr, " Press any key to exit ")
        stdscr.refresh()
        stdscr.getch()
        return

    accepted = {}   # message_id -> correction
    declined = {}   # message_id -> correction
    idx      = 0

    # ── Review loop ────────────────────────────────────────────────────────────
    while True:
        if idx < 0:
            idx = 0
        if idx >= len(corrections):
            idx = len(corrections) - 1

        c    = corrections[idx]
        orig = c["original"]
        corr = c["corrected"]
        meta = c["meta"]
        mid  = c["message_id"]

        stdscr.erase()
        h, w = stdscr.getmaxyx()
        box_w = min(w - 4, 100)
        box_x = (w - box_w) // 2

        # Status tag
        if mid in accepted:
            status_str   = " ✓ ACCEPTED "
            status_color = curses.color_pair(1) | curses.A_BOLD
        elif mid in declined:
            status_str   = " ✗ DECLINED "
            status_color = curses.color_pair(2) | curses.A_BOLD
        else:
            status_str   = " ? PENDING  "
            status_color = curses.color_pair(4) | curses.A_BOLD

        pending_count  = len(corrections) - len(accepted) - len(declined)
        hostname       = meta.get("hostname", "unknown")
        header_text    = f" Review [{idx + 1}/{len(corrections)}]  from: {hostname}  file: {meta.get('file', '?')} "
        draw_header(stdscr, header_text)
        try:
            stdscr.addstr(0, box_x + box_w - len(status_str), status_str, status_color)
        except curses.error:
            pass

        row = 2

        def draw_section(title, q, color, start_row):
            r = start_row
            try:
                stdscr.addstr(r, box_x, title, color | curses.A_BOLD)
                r += 1
                stdscr.addstr(r, box_x, "─" * box_w, curses.color_pair(5))
                r += 1
            except curses.error:
                pass

            def draw_field(label, old_val, new_val, is_after):
                nonlocal r
                val     = new_val if is_after else old_val
                changed = old_val != new_val

                try:
                    stdscr.addstr(r, box_x, f"  {label}:", curses.color_pair(4) | curses.A_BOLD)
                    r += 1
                except curses.error:
                    pass

                if isinstance(val, list):
                    text = ", ".join(val)
                else:
                    text = str(val)

                # Diff highlight: if changed, highlight in yellow on after section
                # on before section show in red, after section show in green
                if changed:
                    style = (curses.color_pair(1) | curses.A_BOLD) if is_after else curses.color_pair(2)
                else:
                    style = curses.color_pair(5)

                for line in wrap_text(text, box_w - 6):
                    try:
                        stdscr.addstr(r, box_x + 4, line, style)
                        r += 1
                    except curses.error:
                        pass
                r += 1  # blank line between fields

            draw_field("Question", orig.get("question", ""), corr.get("question", ""), is_after=(title == "AFTER"))
            draw_field("Choices",
                       ", ".join(orig.get("choices", [])),
                       ", ".join(corr.get("choices", [])),
                       is_after=(title == "AFTER"))
            draw_field("Answer",
                       orig.get("answer", "") if not isinstance(orig.get("answer"), list) else ", ".join(orig.get("answer", [])),
                       corr.get("answer", "") if not isinstance(corr.get("answer"), list) else ", ".join(corr.get("answer", [])),
                       is_after=(title == "AFTER"))
            return r

        row = draw_section("BEFORE", orig, curses.color_pair(2), row)
        row += 1
        row = draw_section("AFTER",  corr, curses.color_pair(1), row)

        # Pending count hint
        try:
            stdscr.addstr(row + 1, box_x,
                          f"  {pending_count} pending  |  {len(accepted)} accepted  |  {len(declined)} declined",
                          curses.color_pair(4))
        except curses.error:
            pass

        prev_hint = "[ Prev   " if idx > 0 else "         "
        next_hint = "] Next   " if idx < len(corrections) - 1 else "] Finish "
        draw_footer(stdscr, f" A: Accept   D: Decline   {prev_hint}{next_hint}  Q: Apply & Quit ")
        stdscr.refresh()

        key = stdscr.getch()

        if key in (ord('a'), ord('A')):
            declined.pop(mid, None)
            accepted[mid] = c
            if idx < len(corrections) - 1:
                idx += 1
        elif key in (ord('d'), ord('D')):
            accepted.pop(mid, None)
            declined[mid] = c
            if idx < len(corrections) - 1:
                idx += 1
        elif key in (ord('l'), ord(']'), curses.KEY_RIGHT):
            if idx < len(corrections) - 1:
                idx += 1
        elif key in (ord('j'), ord('['), curses.KEY_LEFT):
            if idx > 0:
                idx -= 1
        elif key in (ord('q'), ord('Q')):
            break

    # ── Apply & Delete ─────────────────────────────────────────────────────────
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    draw_header(stdscr, " Applying Changes ")
    try:
        stdscr.addstr(h // 2 - 1, (w - 50) // 2,
                      f"Applying {len(accepted)} correction(s), deleting {len(accepted) + len(declined)} message(s)...",
                      curses.color_pair(4) | curses.A_BOLD)
    except curses.error:
        pass
    stdscr.refresh()

    # Group accepted by filename
    from collections import defaultdict
    by_file = defaultdict(list)
    for c in accepted.values():
        fname = c["meta"].get("file", "")
        if fname:
            by_file[fname].append(c)

    script_dir    = Path(__file__).resolve().parent
    questions_dir = script_dir / "study_questions"
    applied       = 0

    for filename, file_corrections in by_file.items():
        filepath = questions_dir / filename
        if not filepath.exists():
            discord_log(f"File not found, skipping: {filepath}")
            continue
        apply_corrections(str(filepath), file_corrections, bot_token)
        applied += len(file_corrections)

    # Delete all accepted + declined messages from Discord
    all_ids = [c["message_id"] for c in list(accepted.values()) + list(declined.values())]
    delete_messages(bot_token, all_ids)

    # Done
    stdscr.erase()
    draw_header(stdscr, " Review Complete ")
    try:
        stdscr.addstr(h // 2 - 2, (w - 40) // 2,
                      f"✓ Applied {applied} correction(s).",
                      curses.color_pair(1) | curses.A_BOLD)
        stdscr.addstr(h // 2,     (w - 40) // 2,
                      f"✓ Deleted {len(accepted) + len(declined)} Discord message(s).",
                      curses.color_pair(1) | curses.A_BOLD)
        if applied > 0:
            stdscr.addstr(h // 2 + 2, (w - 40) // 2,
                          "Don't forget to git push!",
                          curses.color_pair(4) | curses.A_BOLD)
    except curses.error:
        pass
    draw_footer(stdscr, " Press any key to exit ")
    stdscr.refresh()
    stdscr.getch()

def fetch_corrections(bot_token: str) -> list[dict]:
    import urllib.request
    corrections = []
    try:
        url = f"https://discord.com/api/v10/channels/{CHANNEL_ID}/messages?limit=100"
        req = urllib.request.Request(
            url,
            headers={
                "Authorization": f"Bot {bot_token}",
                "User-Agent": "DiscordBot (https://github.com/TsuBenn/dotfiles, 1.0)"
            }

        )
        discord_log(f"Fetching from channel {CHANNEL_ID}...")
        with urllib.request.urlopen(req, timeout=10) as r:
            raw      = r.read().decode("utf-8")
            messages = json.loads(raw)
        discord_log(f"Got {len(messages)} messages")

        for msg in messages:
            content = msg.get("content", "")
            content = content.strip()
            if content.startswith("```"):
                content = "\n".join(content.splitlines()[1:])
            if content.endswith("```"):
                content = "\n".join(content.splitlines()[:-1])
            content = content.strip()

            try:
                data = tomllib.loads(content)
                if "meta" in data and "original" in data and "corrected" in data:
                    corrections.append({
                        "message_id": msg["id"],
                        "meta":       data["meta"],
                        "original":   data["original"],
                        "corrected":  data["corrected"],
                    })
                    discord_log(f"Parsed correction from message {msg['id']}")
            except Exception as e:
                discord_log(f"Skipped message {msg['id']}: {e}")
                continue

    except Exception as e:
        discord_log(f"Fetch error: {e}")

    discord_log(f"Total corrections parsed: {len(corrections)}")
    return corrections

 
def run():
    if len(sys.argv) < 2:
        print("Usage: python study.py <questions.toml or questions.json>")
        sys.exit(1)

    if sys.argv[1] == "--review":
        if len(sys.argv) < 3:
            print("Usage: python study.py --review <bot_token>")
            sys.exit(1)
        bot_token = sys.argv[2]
        curses.wrapper(lambda stdscr: review_mode(stdscr, bot_token))
        return

    # Check study.py update
    print(f"\n  Checking study.py updates...")
    update_available, mode, local_ver, remote_ver = check_for_updates()
    if update_available:
        prompt_update(mode, local_ver, remote_ver)

    # Check questions file update
    filepath = sys.argv[1]
    if not Path(filepath).exists():
        print(f"  {Path(filepath).name} doesn't exist...")
        print()
        sys.exit(1)

    print(f"  Checking {Path(filepath).name} for updates...")
    q_update, q_local, q_remote = check_questions_update(filepath)
    if q_update:
        print(f"\n  ✦ \"{Path(filepath).name}\" update available: v{q_local} → v{q_remote}")
        print("  Update now? [y/N] ", end="", flush=True)
        try:
            choice = input().strip().lower()
        except (EOFError, KeyboardInterrupt):
            choice = "n"
        if choice == "y":
            try:
                url = get_questions_raw_url(filepath)
                with urllib.request.urlopen(url, timeout=10) as r:
                    new_src = r.read()
                Path(filepath).write_bytes(new_src)
                print(f"  ✓ Questions updated to v{q_remote}!\n")
            except Exception as e:
                print(f"  ✗ Update failed: {e}\n")
        else:
            print("  Skipping, continuing...\n")

    time.sleep(0.8)

    curses.wrapper(lambda stdscr: main(stdscr, filepath)) 

 
if __name__ == "__main__":
    run()
