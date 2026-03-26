#!/usr/bin/env python3

import curses
import json
import random
import sys
import os
import tomllib
from datetime import datetime
from pathlib import Path

# ─── File Loading ─────────────────────────────────────────────────────────────

def load_questions(filepath: str) -> list[dict]:
    path = Path(filepath)
    if not path.exists():
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)

    with open(path, "rb" if path.suffix == ".toml" else "r") as f:
        if path.suffix == ".toml":
            data = tomllib.load(f)
        elif path.suffix == ".json":
            data = json.load(f)
        else:
            print("Error: Only .toml or .json files are supported.")
            sys.exit(1)

    return data["questions"]


def load_wrong_answers(wrong_file: str) -> list[dict]:
    path = Path(wrong_file)
    if path.exists():
        with open(path, "r") as f:
            return json.load(f)
    return []


def save_wrong_answers(wrong_file: str, wrong: list[dict]):
    with open(wrong_file, "w") as f:
        json.dump(wrong, f, indent=2)

# ─── Queue Builder ────────────────────────────────────────────────────────────

def build_queue(questions: list[dict]) -> list[dict]:
    """Shuffle questions and tag each with metadata."""
    q = [dict(q, _wrong_count=0, _answered_correct=False) for q in questions]
    random.shuffle(q)
    return q

# ─── TUI Helpers ──────────────────────────────────────────────────────────────

def init_colors():
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_GREEN, -1)   # Correct
    curses.init_pair(2, curses.COLOR_RED, -1)     # Wrong
    curses.init_pair(3, curses.COLOR_CYAN, -1)    # Selected
    curses.init_pair(4, curses.COLOR_YELLOW, -1)  # Highlight/info
    curses.init_pair(5, curses.COLOR_WHITE, -1)   # Normal


def draw_box(win, title=""):
    win.box()
    if title:
        h, w = win.getmaxyx()
        win.addstr(0, (w - len(title) - 2) // 2, f" {title} ", curses.A_BOLD)


def wrap_text(text: str, width: int) -> list[str]:
    """Wrap text to fit within a given width."""
    words = text.split()
    lines = []
    current = ""
    for word in words:
        if len(current) + len(word) + 1 <= width:
            current = (current + " " + word).strip()
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines

# ─── Screens ──────────────────────────────────────────────────────────────────

def is_multi(question: dict) -> bool:
    return isinstance(question["answer"], list)


def check_answer(question: dict, chosen) -> bool:
    if is_multi(question):
        return set(chosen) == set(question["answer"])
    return chosen == question["answer"]


def ask_question(stdscr, question: dict, q_num: int, total: int):
    """
    Show a question and let the user pick an answer with arrow keys.
    Single: Enter to confirm.
    Multi:  Space to toggle, Enter to submit.
    Returns (chosen, is_correct) or (None, False) if quit.
    """
    curses.curs_set(0)
    choices = question["choices"]
    labels = ["A", "B", "C", "D", "E", "F"]
    selected = 0
    ticked = set()
    multi = is_multi(question)

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()

        # ── Header ──
        header = f" Study Session  [{q_num}/{total}] "
        stdscr.addstr(0, (w - len(header)) // 2, header,
                      curses.color_pair(4) | curses.A_BOLD)

        # ── Question ──
        box_w = min(w - 4, 80)
        box_x = (w - box_w) // 2
        q_lines = wrap_text(question["question"], box_w - 2)
        try:
            label = "Question (select all that apply):" if multi else "Question:"
            stdscr.addstr(2, box_x, label, curses.color_pair(4) | curses.A_BOLD)
            for idx, line in enumerate(q_lines):
                stdscr.addstr(3 + idx, box_x + 2, line, curses.color_pair(5))
        except curses.error:
            pass

        # ── Choices ──
        choice_y = 3 + len(q_lines) + 1
        for i, choice in enumerate(choices):
            is_sel = i == selected
            if multi:
                tick = "[X]" if i in ticked else "[ ]"
                cursor = ">" if is_sel else " "
                line = f"{cursor} {tick} {labels[i]}. {choice}"
            else:
                cursor = ">" if is_sel else " "
                line = f"{cursor} {labels[i]}. {choice}"

            style = curses.color_pair(3) | curses.A_BOLD if is_sel else curses.color_pair(5)
            try:
                stdscr.addstr(choice_y + i, box_x, line, style)
            except curses.error:
                pass

        # ── Footer ──
        if multi:
            footer = " ↑↓ Navigate   Space Toggle   Enter Submit   Q Quit "
        else:
            footer = " ↑↓ Navigate   Enter Select   Q Quit "
        try:
            stdscr.addstr(h - 1, (w - len(footer)) // 2, footer, curses.color_pair(4))
        except curses.error:
            pass

        stdscr.refresh()

        key = stdscr.getch()
        if key in (curses.KEY_UP, ord('k')) and selected > 0:
            selected -= 1
        elif key in (curses.KEY_DOWN, ord('j')) and selected < len(choices) - 1:
            selected += 1
        elif key == ord(' ') and multi:
            if selected in ticked:
                ticked.remove(selected)
            else:
                ticked.add(selected)
        elif key in (curses.KEY_ENTER, 10, 13):
            if multi:
                if not ticked:
                    continue  # don't allow empty submission
                chosen = [choices[i] for i in sorted(ticked)]
            else:
                chosen = choices[selected]
            correct = check_answer(question, chosen)
            return chosen, correct
        elif key in (ord('q'), ord('Q')):
            return None, False


def show_result(stdscr, question: dict, chosen, correct: bool):
    """Show correct/wrong feedback and wait for Enter."""
    stdscr.erase()
    h, w = stdscr.getmaxyx()

    box_w = min(w - 4, 80)
    box_x = (w - box_w) // 2

    status = "✓ CORRECT!" if correct else "✗ WRONG"
    color = curses.color_pair(1) if correct else curses.color_pair(2)

    # Normalize to list for uniform display
    correct_ans = question["answer"] if isinstance(question["answer"], list) else [question["answer"]]
    chosen_ans = chosen if isinstance(chosen, list) else [chosen]

    try:
        stdscr.addstr(2, box_x, status, color | curses.A_BOLD)
        stdscr.addstr(4, box_x, "Correct answer:", curses.color_pair(4))
        for idx, ans in enumerate(correct_ans):
            stdscr.addstr(5 + idx, box_x + 2, f"• {ans}", curses.color_pair(1) | curses.A_BOLD)

        if not correct:
            row = 5 + len(correct_ans) + 1
            stdscr.addstr(row, box_x, "Your answer:", curses.color_pair(4))
            for idx, ans in enumerate(chosen_ans):
                stdscr.addstr(row + 1 + idx, box_x + 2, f"• {ans}", curses.color_pair(2))

        footer = " Press Enter to continue "
        stdscr.addstr(h - 1, (w - len(footer)) // 2, footer, curses.color_pair(4))
    except curses.error:
        pass

    stdscr.refresh()

    while True:
        key = stdscr.getch()
        if key in (curses.KEY_ENTER, 10, 13):
            break


def show_stats(stdscr, total_questions: int, correct_count: int, wrong_details: list[dict]):
    """Final stats screen."""
    stdscr.erase()
    h, w = stdscr.getmaxyx()

    box_w = min(w - 4, 60)
    box_x = (w - box_w) // 2

    wrong_count = total_questions - correct_count
    pct = (correct_count / total_questions * 100) if total_questions > 0 else 0

    lines = [
        ("─" * (box_w - 4), curses.color_pair(5)),
        (f"  Session Complete!", curses.color_pair(4) | curses.A_BOLD),
        ("─" * (box_w - 4), curses.color_pair(5)),
        ("", 0),
        (f"  Total questions : {total_questions}", curses.color_pair(5)),
        (f"  Correct         : {correct_count}", curses.color_pair(1) | curses.A_BOLD),
        (f"  Wrong           : {wrong_count}", curses.color_pair(2) | curses.A_BOLD),
        (f"  Score           : {pct:.1f}%", curses.color_pair(4) | curses.A_BOLD),
        ("", 0),
    ]

    if wrong_details:
        lines.append(("  Questions you missed:", curses.color_pair(2) | curses.A_BOLD))
        for q in wrong_details:
            wrapped = wrap_text(f"  • {q['question']}", box_w - 2)
            for wl in wrapped:
                lines.append((wl, curses.color_pair(2)))
        lines.append(("", 0))
        lines.append(("  (Saved to wrong_answers.json)", curses.color_pair(4)))

    start_y = max(1, (h - len(lines)) // 2)
    for i, (text, style) in enumerate(lines):
        try:
            stdscr.addstr(start_y + i, box_x, text, style)
        except curses.error:
            pass

    footer = " Press any key to exit "
    try:
        stdscr.addstr(h - 1, (w - len(footer)) // 2, footer, curses.color_pair(4))
    except curses.error:
        pass

    stdscr.refresh()
    stdscr.getch()

# ─── Main Loop ────────────────────────────────────────────────────────────────

def main(stdscr, filepath: str):
    init_colors()
    stdscr.keypad(True)

    wrong_file = "wrong_answers.json"
    questions = load_questions(filepath)

    # Build randomized queue
    queue = build_queue(questions)

    correct_first_try = set()   # indices of questions user got right on first try
    wrong_questions_log = []    # questions user got wrong at least once
    total_unique = len(queue)

    i = 0
    while i < len(queue):
        q = queue[i]
        chosen, correct = ask_question(stdscr, q, i + 1, len(queue))

        # User quit
        if chosen is None:
            break

        if correct:
            q["_answered_correct"] = True
            if q["_wrong_count"] == 0:
                correct_first_try.add(id(q))
            show_result(stdscr, q, chosen, correct=True)
            i += 1
        else:
            q["_wrong_count"] += 1

            # Log to wrong answers if first time getting it wrong
            if q["_wrong_count"] == 1:
                wrong_questions_log.append({
                    "question": q["question"],
                    "answer": q["answer"],
                    "timestamp": datetime.now().isoformat()
                })

            show_result(stdscr, q, chosen, correct=False)

            # Re-insert this question randomly within the next 1–4 questions
            queue.pop(i)
            insert_at = min(i + random.randint(1, 4), len(queue))
            queue.insert(insert_at, q)
            # Don't increment i — next question is already at i

    # Save wrong answers
    if wrong_questions_log:
        existing = load_wrong_answers(wrong_file)
        existing.extend(wrong_questions_log)
        save_wrong_answers(wrong_file, existing)

    correct_count = len(correct_first_try)
    show_stats(stdscr, total_unique, correct_count, wrong_questions_log)


def run():
    if len(sys.argv) < 2:
        print("Usage: python study.py <questions.toml or questions.json>")
        sys.exit(1)
    filepath = sys.argv[1]
    curses.wrapper(lambda stdscr: main(stdscr, filepath))


if __name__ == "__main__":
    run()
