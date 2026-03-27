#!/usr/bin/env python3

import curses
import json
import os
import random
import subprocess
import sys
import tempfile
import tomllib
from datetime import datetime
from pathlib import Path

VERSION = "0.2"

# ─── File I/O ─────────────────────────────────────────────────────────────────

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


def save_toml(filepath: str, questions: list[dict]):
    lines = []
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
    q = [dict(q, _wrong_count=0, _answered_correct=False) for q in questions]
    random.shuffle(q)
    return q

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
    words = text.split()
    lines, current = [], ""
    for word in words:
        if len(current) + len(word) + 1 <= width:
            current = (current + " " + word).strip()
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines or [""]

# ─── Edit in $EDITOR ──────────────────────────────────────────────────────────

def edit_question_in_editor(stdscr, question: dict, all_questions: list[dict], filepath: str) -> dict:
    snippet_lines = [
        "# Edit question, choices, and answer below.",
        "# Save and quit (:wq) to apply. Quit without saving (:q!) to cancel.",
        '# Multi-answer format: answer = ["Option A", "Option B"]',
        "",
        "[[questions]]",
        f'question = {json.dumps(question["question"])}',
    ]
    choices_str = ", ".join(json.dumps(c) for c in question["choices"])
    snippet_lines.append(f"choices = [{choices_str}]")
    if isinstance(question.get("answer"), list):
        answer_str = ", ".join(json.dumps(a) for a in question["answer"])
        snippet_lines.append(f"answer = [{answer_str}]")
    else:
        snippet_lines.append(f"answer = {json.dumps(question['answer'])}")

    with tempfile.NamedTemporaryFile(suffix=".toml", mode="w", delete=False, encoding="utf-8") as tmp:
        tmp.write("\n".join(snippet_lines) + "\n")
        tmp_path = tmp.name

    editor = os.environ.get("EDITOR", "nvim")
    curses.endwin()
    subprocess.call([editor, tmp_path])
    stdscr.refresh()
    curses.doupdate()

    try:
        with open(tmp_path, "rb") as f:
            data = tomllib.load(f)

        updated = data["questions"][0]
        updated["_wrong_count"] = question.get("_wrong_count", 0)
        updated["_answered_correct"] = question.get("_answered_correct", False)

        for idx, q in enumerate(all_questions):
            if q.get("question") == question["question"]:
                all_questions[idx] = {k: v for k, v in updated.items() if not k.startswith("_")}
                break

        if Path(filepath).suffix == ".toml":
            save_toml(filepath, [{k: v for k, v in q.items() if not k.startswith("_")} for q in all_questions])

        return updated

    except Exception as e:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        msg = f" Edit failed: {e} "
        try:
            stdscr.addstr(h // 2, max(0, (w - len(msg)) // 2), msg, curses.color_pair(2) | curses.A_BOLD)
            hint = " keeping original — press any key "
            stdscr.addstr(h // 2 + 1, max(0, (w - len(hint)) // 2), hint, curses.color_pair(4))
        except curses.error:
            pass
        stdscr.refresh()
        stdscr.getch()
        return question
    finally:
        os.unlink(tmp_path)

# ─── Screens ──────────────────────────────────────────────────────────────────

def is_multi(question: dict) -> bool:
    return isinstance(question["answer"], list)


def check_answer(question: dict, chosen) -> bool:
    if is_multi(question):
        return set(chosen) == set(question["answer"])
    return chosen == question["answer"]


def ask_question(stdscr, question: dict, q_num: int, total: int):
    curses.curs_set(0)
    choices = question["choices"]
    labels = ["A", "B", "C", "D", "E", "F", "G", "H"]
    selected = 0
    ticked = set()
    multi = is_multi(question)

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()

        header = f" Study {VERSION} [{q_num}/{total}] "
        stdscr.addstr(0, (w - len(header)) // 2, header, curses.color_pair(4) | curses.A_BOLD)

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

        choice_y = 3 + len(q_lines) + 1
        for i, choice in enumerate(choices):
            is_sel = i == selected
            tick = f"[{'X' if i in ticked else ' '}] " if multi else ""
            cursor = ">" if is_sel else " "
            line = f"{cursor} {tick}{labels[i]}. {choice}"
            style = curses.color_pair(3) | curses.A_BOLD if is_sel else curses.color_pair(5)
            try:
                stdscr.addstr(choice_y + i, box_x, line, style)
            except curses.error:
                pass

        footer = " ↑↓ Navigate   Space Toggle   Enter Submit   Q Quit " if multi else \
                 " ↑↓ Navigate   Enter Select   Q Quit "
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
            ticked ^= {selected}
        elif key in (curses.KEY_ENTER, 10, 13):
            if multi:
                if not ticked:
                    continue
                chosen = [choices[i] for i in sorted(ticked)]
            else:
                chosen = choices[selected]
            return chosen, check_answer(question, chosen)
        elif key in (ord('q'), ord('Q')):
            return None, False


def show_result(stdscr, question: dict, chosen, correct: bool, all_questions: list[dict], filepath: str) -> dict:
    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        box_w = min(w - 4, 80)
        box_x = (w - box_w) // 2

        status = "✓ CORRECT!" if correct else "✗ WRONG"
        color = curses.color_pair(1) if correct else curses.color_pair(2)

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

            footer = " Enter Continue   E Edit Question "
            stdscr.addstr(h - 1, (w - len(footer)) // 2, footer, curses.color_pair(4))
        except curses.error:
            pass

        stdscr.refresh()
        key = stdscr.getch()

        if key in (curses.KEY_ENTER, 10, 13):
            return question
        elif key in (ord('e'), ord('E')):
            question = edit_question_in_editor(stdscr, question, all_questions, filepath)


def show_stats(stdscr, total_questions: int, correct_count: int, wrong_details: list[dict]):
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    box_w = min(w - 4, 60)
    box_x = (w - box_w) // 2

    wrong_count = total_questions - correct_count
    pct = (correct_count / total_questions * 100) if total_questions > 0 else 0

    lines = [
        ("─" * (box_w - 4), curses.color_pair(5)),
        ("  Session Complete!", curses.color_pair(4) | curses.A_BOLD),
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
            for wl in wrap_text(f"  • {q['question']}", box_w - 2):
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

# ─── Main ─────────────────────────────────────────────────────────────────────

def main(stdscr, filepath: str):
    init_colors()
    stdscr.keypad(True)

    wrong_file = "wrong_answers.json"
    all_questions = load_questions(filepath)
    queue = build_queue(all_questions)

    correct_first_try = set()
    wrong_questions_log = []
    total_unique = len(queue)

    i = 0
    while i < len(queue):
        q = queue[i]
        chosen, correct = ask_question(stdscr, q, i + 1, len(queue))

        if chosen is None:
            break

        if correct:
            q["_answered_correct"] = True
            if q["_wrong_count"] == 0:
                correct_first_try.add(id(q))
            q = show_result(stdscr, q, chosen, correct=True, all_questions=all_questions, filepath=filepath)
            queue[i] = q
            i += 1
        else:
            q["_wrong_count"] += 1
            if q["_wrong_count"] == 1:
                wrong_questions_log.append({
                    "question": q["question"],
                    "answer": q["answer"],
                    "timestamp": datetime.now().isoformat()
                })
            q = show_result(stdscr, q, chosen, correct=False, all_questions=all_questions, filepath=filepath)
            queue[i] = q
            queue.pop(i)
            insert_at = min(i + random.randint(1, 4), len(queue))
            queue.insert(insert_at, q)

    if wrong_questions_log:
        existing = load_wrong_answers(wrong_file)
        existing.extend(wrong_questions_log)
        save_wrong_answers(wrong_file, existing)

    show_stats(stdscr, total_unique, len(correct_first_try), wrong_questions_log)


def run():
    if len(sys.argv) < 2:
        print("Usage: python study.py <questions.toml or questions.json>")
        sys.exit(1)
    curses.wrapper(lambda stdscr: main(stdscr, sys.argv[1]))


if __name__ == "__main__":
    run()
