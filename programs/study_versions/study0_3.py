#!/usr/bin/env python3

import curses
import json
import random
import sys
import tomllib
from datetime import datetime
from pathlib import Path

VERSION = "0.3"

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

def read_line(stdscr, y: int, x: int, width: int, prefill: str = "") -> str | None:
    """Single-line input. Enter confirms, Esc cancels (returns None)."""
    curses.curs_set(1)
    buf    = list(prefill)
    cursor = len(buf)

    while True:
        field = "".join(buf)[:width].ljust(width)
        try:
            stdscr.addstr(y, x, field, curses.color_pair(3))
            stdscr.move(y, x + min(cursor, width - 1))
        except curses.error:
            pass
        stdscr.refresh()

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
        elif key == curses.KEY_HOME:
            cursor = 0
        elif key == curses.KEY_END:
            cursor = len(buf)
        elif 32 <= key <= 126:
            buf.insert(cursor, chr(key))
            cursor += 1

# ─── Edit Screen ──────────────────────────────────────────────────────────────

def edit_screen(stdscr, question: dict, all_questions: list[dict], filepath: str) -> dict:
    """In-app editor. Returns updated or original question dict."""
    import copy
    draft  = copy.deepcopy(question)
    labels = ["A", "B", "C", "D", "E", "F"]

    FIELD_QUESTION = 0
    FIELD_CHOICES  = list(range(1, len(draft["choices"]) + 1))
    FIELD_ANSWER   = len(draft["choices"]) + 1
    FIELD_SAVE     = FIELD_ANSWER + 1
    FIELD_CANCEL   = FIELD_SAVE + 1
    total_fields   = FIELD_CANCEL + 1

    sel     = 0
    message = ""

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        box_w = min(w - 4, 80)
        box_x = (w - box_w) // 2

        draw_header(stdscr, " Edit Question ")

        def fstyle(idx):
            return curses.color_pair(3) | curses.A_BOLD if sel == idx else curses.color_pair(5)

        row = 2

        # Question
        try:
            stdscr.addstr(row, box_x, "Question:", curses.color_pair(4) | curses.A_BOLD)
            row += 1
            prefix = "> " if sel == FIELD_QUESTION else "  "
            stdscr.addstr(row, box_x, prefix + draft["question"][:box_w - 4], fstyle(FIELD_QUESTION))
            row += 2
        except curses.error:
            pass

        q_text_row = row - 2  # save for editing

        # Choices
        choices_start_row = row + 1
        try:
            stdscr.addstr(row, box_x, "Choices:", curses.color_pair(4) | curses.A_BOLD)
            row += 1
            for ci, choice in enumerate(draft["choices"]):
                fid    = FIELD_CHOICES[ci]
                prefix = "> " if sel == fid else "  "
                stdscr.addstr(row, box_x, f"{prefix}{labels[ci]}. {choice[:box_w - 8]}", fstyle(fid))
                row += 1
            row += 1
        except curses.error:
            pass

        # Answer
        ans_row = row + 1
        try:
            stdscr.addstr(row, box_x, "Answer:", curses.color_pair(4) | curses.A_BOLD)
            row += 1
            ans         = draft["answer"]
            ans_display = (", ".join(ans) if isinstance(ans, list) else ans)[:box_w - 4]
            prefix      = "> " if sel == FIELD_ANSWER else "  "
            stdscr.addstr(row, box_x, prefix + ans_display, fstyle(FIELD_ANSWER))
            if sel == FIELD_ANSWER:
                try:
                    stdscr.addstr(row + 1, box_x + 2,
                                  "(must match a choice; comma-separate for multi)",
                                  curses.color_pair(4))
                except curses.error:
                    pass
            row += 3
        except curses.error:
            pass

        # Save / Cancel
        btn_row = row
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

        draw_footer(stdscr, " ↑↓/Tab Navigate   Enter Edit/Confirm   Esc Cancel ")
        stdscr.refresh()

        key = stdscr.getch()

        if key in (curses.KEY_UP, ord('k')):
            sel = (sel - 1) % total_fields
            message = ""
        elif key in (curses.KEY_DOWN, ord('j'), 9):
            sel = (sel + 1) % total_fields
            message = ""
        elif key == 27:
            return question
        elif key in (curses.KEY_ENTER, 10, 13):

            if sel == FIELD_QUESTION:
                result = read_line(stdscr, q_text_row, box_x + 2, box_w - 4, draft["question"])
                if result is not None and result.strip():
                    draft["question"] = result.strip()
                message = ""

            elif sel in FIELD_CHOICES:
                ci       = FIELD_CHOICES.index(sel)
                edit_row = choices_start_row + ci
                result   = read_line(stdscr, edit_row, box_x + 4, box_w - 6, draft["choices"][ci])
                if result is not None and result.strip():
                    old = draft["choices"][ci]
                    draft["choices"][ci] = result.strip()
                    if isinstance(draft["answer"], list):
                        draft["answer"] = [result.strip() if a == old else a for a in draft["answer"]]
                    elif draft["answer"] == old:
                        draft["answer"] = result.strip()
                message = ""

            elif sel == FIELD_ANSWER:
                current = ", ".join(draft["answer"]) if isinstance(draft["answer"], list) else draft["answer"]
                result  = read_line(stdscr, ans_row, box_x + 2, box_w - 4, current)
                if result is not None:
                    parts   = [p.strip() for p in result.split(",") if p.strip()]
                    invalid = [p for p in parts if p not in draft["choices"]]
                    if invalid:
                        message = f"Not in choices: {', '.join(invalid)}"
                    else:
                        draft["answer"] = parts if len(parts) > 1 else parts[0]
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
                    save_toml(filepath, [{k: v for k, v in q.items() if not k.startswith("_")}
                                         for q in all_questions])
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
    return isinstance(question["answer"], list)


def check_answer(question: dict, chosen) -> bool:
    if is_multi(question):
        return set(chosen) == set(question["answer"])
    return chosen == question["answer"]


def ask_question(stdscr, question: dict, q_num: int, total: int, can_go_prev: bool):
    curses.curs_set(0)
    choices  = question["choices"]
    labels   = ["A", "B", "C", "D", "E", "F"]
    selected = 0
    ticked   = set()
    multi    = is_multi(question)
    answered = question.get("_answered_correct") or question.get("_wrong_count", 0) > 0

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
        draw_header(stdscr, f" Study {VERSION} [{q_num}/{total}]{tag} ")

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

        choice_y = 3 + len(q_lines) + 1
        for i, choice in enumerate(choices):
            is_sel = i == selected
            if answered:
                is_correct_choice = choice in (question["answer"] if isinstance(question["answer"], list) else [question["answer"]])
                is_chosen = i in ticked
                marker = "✓" if is_correct_choice else ("✗" if is_chosen else " ")
                style  = (curses.color_pair(1) | curses.A_BOLD) if is_correct_choice else \
                         (curses.color_pair(2) if is_chosen else curses.color_pair(5))
                cursor = ">" if is_sel else " "
                line   = f"{cursor} {marker} {labels[i]}. {choice}"
            else:
                tick   = f"[{'X' if i in ticked else ' '}] " if multi else ""
                cursor = ">" if is_sel else " "
                line   = f"{cursor} {tick}{labels[i]}. {choice}"
                style  = curses.color_pair(3) | curses.A_BOLD if is_sel else curses.color_pair(5)
            try:
                stdscr.addstr(choice_y + i, box_x, line, style)
            except curses.error:
                pass

        prev_hint = "[ Prev  " if can_go_prev else "        "
        if answered:
            footer = f" {prev_hint}] Next   E Edit   Q Quit "
        elif multi:
            footer = f" ↑↓ Navigate   Space Toggle   Enter Submit   {prev_hint}] Next   Q Quit "
        else:
            footer = f" ↑↓ Navigate   Enter Select   {prev_hint}] Next   Q Quit "
        draw_footer(stdscr, footer)
        stdscr.refresh()

        key = stdscr.getch()

        if key in (ord('['), curses.KEY_LEFT) and can_go_prev:
            return NAV_PREV, False
        elif key in (ord(']'), curses.KEY_RIGHT):
            return NAV_NEXT, False
        elif key in (ord('q'), ord('Q')):
            return NAV_QUIT, False
        elif key in (ord('e'), ord('E')) and answered:
            return NAV_EDIT, False

        if answered:
            continue

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

# ─── Result Screen ────────────────────────────────────────────────────────────

def show_result(stdscr, question: dict, chosen, correct: bool,
                all_questions: list[dict], filepath: str) -> dict:
    correct_ans = question["answer"] if isinstance(question["answer"], list) else [question["answer"]]
    chosen_ans  = chosen if isinstance(chosen, list) else [chosen]

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        box_w = min(w - 4, 80)
        box_x = (w - box_w) // 2

        status = "✓ CORRECT!" if correct else "✗ WRONG"
        color  = curses.color_pair(1) if correct else curses.color_pair(2)

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
        except curses.error:
            pass

        draw_footer(stdscr, " Enter Continue   E Edit question ")
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


def run():
    if len(sys.argv) < 2:
        print("Usage: python study.py <questions.toml or questions.json>")
        sys.exit(1)
    curses.wrapper(lambda stdscr: main(stdscr, sys.argv[1]))


if __name__ == "__main__":
    run()
