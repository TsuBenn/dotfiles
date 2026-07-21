#!/usr/bin/env python3
"""
study_gui.py — A Tkinter GUI study app for multiple-choice TOML question files.

Usage:
    python study_gui.py
    python study_gui.py path/to/questions.toml

Features:
    • Open any TOML file with a [[questions]] table
    • Single-answer and "select all that apply" multi-answer questions
    • Spaced re-queue: wrong answers reappear 1–4 spots later in the queue
    • Per-choice explanations shown on the result screen (if the TOML provides them)
    • End-of-session stats: total / correct / wrong / percentage
    • Wrong-answer log persisted to wrong_answers.json next to the TOML file
    • Recent-files list on the welcome screen (last 5)
    • Resizable window with dynamic text wrapping
    • Keyboard shortcuts: A–H select choice, Enter submit/next, Esc quit session

TOML format expected:
    version = 1

    [[questions]]
    question = "What is 2 + 2?"
    choices = ["3", "4", "5"]
    answer = "4"
    explanations = ["", "Correct: 2 + 2 = 4", ""]

    [[questions]]
    question = "Which are prime?"
    choices = ["2", "4", "7"]
    answer = ["2", "7"]
    explanations = ["Prime", "Composite", "Prime"]
"""

import json
import random
import sys
import tomllib
from datetime import datetime
from pathlib import Path
from tkinter import Tk, Frame, Label, Button, filedialog, messagebox, font

APP_NAME = "Study GUI"
APP_VERSION = "1.0.0"
APP_DATA_FILE = Path.home() / ".study_gui_data.json"
WRONG_ANSWERS_FILE = "wrong_answers.json"
LABELS = ["A", "B", "C", "D", "E", "F", "G", "H"]

# ─── Dark Study Theme ─────────────────────────────────────────────────────────
THEME = {
    "bg":           "#1e1e2e",
    "surface":      "#2d2d3f",
    "surface_alt":  "#3d3d52",
    "text":         "#e0e0e8",
    "text_dim":     "#9090a8",
    "accent":       "#6c8eff",
    "accent_hover": "#8aa5ff",
    "correct":      "#4ade80",
    "correct_bg":   "#1f3a2a",
    "wrong":        "#f87171",
    "wrong_bg":     "#3a1f1f",
    "warning":      "#fbbf24",
    "warning_bg":   "#3a3a1f",
    "border":       "#4a4a62",
}


def get_fonts():
    # Cross-platform font stack: Segoe UI (Win), Helvetica (Mac), DejaVu Sans (Linux)
    families = ["Segoe UI", "Helvetica", "DejaVu Sans", "Arial"]
    return {
        "title":   font.Font(family=families[0], size=22, weight="bold"),
        "heading": font.Font(family=families[0], size=14, weight="bold"),
        "body":    font.Font(family=families[0], size=12),
        "choice":  font.Font(family=families[0], size=12),
        "small":   font.Font(family=families[0], size=10),
        "stat":    font.Font(family=families[0], size=26, weight="bold"),
    }


# ─── Choice Button Widget ─────────────────────────────────────────────────────
class ChoiceButton(Frame):
    """A clickable choice widget with selection and result states."""

    def __init__(self, parent, letter, text, on_click, app, **kwargs):
        super().__init__(parent, **kwargs)
        self.app = app
        self.letter = letter
        self.text = text
        self.on_click = on_click
        self.index = ord(letter) - ord("A")
        self.selected = False
        self.state = "normal"  # normal | correct | wrong | missed

        self.configure(bg=THEME["surface"], cursor="hand2", padx=14, pady=10)

        self.label_letter = Label(
            self, text=f"{letter}.", font=app.fonts["heading"],
            bg=THEME["surface"], fg=THEME["accent"]
        )
        self.label_letter.pack(side="left", anchor="n", padx=(0, 12))

        self.label_text = Label(
            self, text=text, font=app.fonts["choice"],
            bg=THEME["surface"], fg=THEME["text"],
            wraplength=600, justify="left", anchor="w"
        )
        self.label_text.pack(side="left", fill="x", expand=True, anchor="w")

        for w in (self, self.label_letter, self.label_text):
            w.bind("<Button-1>", self._handle_click)
            w.bind("<Enter>", self._handle_enter)
            w.bind("<Leave>", self._handle_leave)

    def _handle_click(self, event=None):
        self.on_click(self.index)

    def _handle_enter(self, event=None):
        if self.state == "normal" and not self.selected:
            self._set_bg(THEME["surface_alt"])

    def _handle_leave(self, event=None):
        if self.state == "normal" and not self.selected:
            self._set_bg(THEME["surface"])

    def _set_bg(self, color):
        self.configure(bg=color)
        self.label_letter.configure(bg=color)
        self.label_text.configure(bg=color)

    def set_selected(self, selected):
        self.selected = selected
        if self.state == "normal":
            if selected:
                self._set_bg(THEME["surface_alt"])
                self.label_letter.configure(fg=THEME["accent_hover"])
            else:
                self._set_bg(THEME["surface"])
                self.label_letter.configure(fg=THEME["accent"])

    def set_result_state(self, state):
        self.state = state
        if state == "correct":
            self._set_bg(THEME["correct_bg"])
            self.label_letter.configure(fg=THEME["correct"])
            self.label_text.configure(fg=THEME["correct"])
        elif state == "wrong":
            self._set_bg(THEME["wrong_bg"])
            self.label_letter.configure(fg=THEME["wrong"])
            self.label_text.configure(fg=THEME["wrong"])
        elif state == "missed":
            self._set_bg(THEME["warning_bg"])
            self.label_letter.configure(fg=THEME["warning"])
            self.label_text.configure(fg=THEME["warning"])
        else:
            self._set_bg(THEME["surface"])
            self.label_letter.configure(fg=THEME["accent"])
            self.label_text.configure(fg=THEME["text"])

    def update_wraplength(self, width):
        # Account for letter label + padding (~50px)
        self.label_text.configure(wraplength=max(100, width - 50))


# ─── Main App ─────────────────────────────────────────────────────────────────
class StudyApp:
    def __init__(self, root):
        self.root = root
        self.root.title(f"{APP_NAME} v{APP_VERSION}")
        self.root.geometry("900x650")
        self.root.minsize(600, 500)
        self.root.configure(bg=THEME["bg"])

        self.fonts = get_fonts()
        self.recent_files = self._load_recent_files()
        self.current_filepath = None
        self.questions = []
        self.queue = []
        self.current_idx = 0
        self.correct_first_try = set()
        self.wrong_log = []
        self.session_active = False
        self.submitted = False
        self.selected_indices = set()
        self.choice_buttons = []
        self.explanation_labels = []
        self.current_question = None

        # Keyboard bindings
        for ch in "abcdefghABCDEFGH":
            self.root.bind(ch, lambda e, c=ch: self._on_letter(c.upper()))
        self.root.bind("<Return>", self._on_enter)
        self.root.bind("<KP_Enter>", self._on_enter)
        self.root.bind("<Escape>", self._on_escape)
        self.root.bind("<Right>", lambda e: self._on_enter() if self.submitted else None)

        self.container = Frame(root, bg=THEME["bg"])
        self.container.pack(fill="both", expand=True)

        # If launched with a file argument, jump straight in
        if len(sys.argv) > 1 and Path(sys.argv[1]).exists():
            if self._load_questions(sys.argv[1]):
                self._start_session()
            else:
                self._show_welcome()
        else:
            self._show_welcome()

    # ─── Persistence ───────────────────────────────────────────────────────────
    def _load_recent_files(self):
        try:
            if APP_DATA_FILE.exists():
                data = json.loads(APP_DATA_FILE.read_text(encoding="utf-8"))
                return [f for f in data.get("recent_files", []) if Path(f).exists()]
        except Exception:
            pass
        return []

    def _save_recent_files(self):
        try:
            APP_DATA_FILE.write_text(
                json.dumps({"recent_files": self.recent_files[:5]}, indent=2),
                encoding="utf-8",
            )
        except Exception:
            pass

    def _add_recent_file(self, filepath):
        filepath = str(filepath)
        if filepath in self.recent_files:
            self.recent_files.remove(filepath)
        self.recent_files.insert(0, filepath)
        self.recent_files = self.recent_files[:5]
        self._save_recent_files()

    def _load_questions(self, filepath):
        path = Path(filepath)
        if not path.exists():
            messagebox.showerror("Error", f"File not found:\n{filepath}")
            return False
        try:
            with open(path, "rb") as f:
                data = tomllib.load(f)
            self.questions = data.get("questions", [])
            if not self.questions:
                messagebox.showerror("Error", "No questions found in file.")
                return False
            self.current_filepath = filepath
            self._add_recent_file(filepath)
            return True
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load TOML:\n{e}")
            return False

    def _save_wrong_answers(self):
        if not self.wrong_log or not self.current_filepath:
            return
        wrong_file = Path(self.current_filepath).parent / WRONG_ANSWERS_FILE
        try:
            existing = []
            if wrong_file.exists():
                existing = json.loads(wrong_file.read_text(encoding="utf-8"))
            existing.extend(self.wrong_log)
            wrong_file.write_text(json.dumps(existing, indent=2), encoding="utf-8")
        except Exception:
            pass

    # ─── Queue ─────────────────────────────────────────────────────────────────
    def _build_queue(self):
        result = []
        for q in self.questions:
            q_copy = dict(q)
            q_copy["_wrong_count"] = 0
            q_copy["_answered_correct"] = False
            choices = list(q_copy.get("choices", []))
            explanations = list(q_copy.get("explanations", []))
            if explanations and len(explanations) == len(choices):
                paired = list(zip(choices, explanations))
                random.shuffle(paired)
                choices, explanations = zip(*paired)
                q_copy["choices"] = list(choices)
                q_copy["explanations"] = list(explanations)
            else:
                random.shuffle(choices)
                q_copy["choices"] = choices
            result.append(q_copy)
        random.shuffle(result)
        return result

    # ─── Helpers ───────────────────────────────────────────────────────────────
    def _is_multi(self, question):
        ans = question.get("answer")
        return isinstance(ans, list) and len(ans) > 1

    def _check_answer(self, question, chosen):
        ans = question["answer"]
        if self._is_multi(question):
            return set(chosen) == set(ans)
        if isinstance(ans, list):
            return chosen == ans[0] or chosen in ans
        return chosen == ans

    def _clear_container(self):
        for w in self.container.winfo_children():
            w.destroy()

    # ─── Welcome Screen ────────────────────────────────────────────────────────
    def _show_welcome(self):
        self._clear_container()
        self.session_active = False

        center = Frame(self.container, bg=THEME["bg"])
        center.pack(expand=True, fill="both", padx=40, pady=40)

        Label(
            center, text=APP_NAME, font=self.fonts["title"],
            bg=THEME["bg"], fg=THEME["text"]
        ).pack(pady=(30, 6))

        Label(
            center, text="Multiple-choice study sessions from TOML files",
            font=self.fonts["body"], bg=THEME["bg"], fg=THEME["text_dim"]
        ).pack(pady=(0, 30))

        Button(
            center, text="  Open TOML File…  ", font=self.fonts["heading"],
            bg=THEME["accent"], fg="white",
            activebackground=THEME["accent_hover"], activeforeground="white",
            bd=0, padx=28, pady=12, cursor="hand2",
            command=self._open_file_dialog
        ).pack(pady=8)

        if self.recent_files:
            Label(
                center, text="Recent Files", font=self.fonts["heading"],
                bg=THEME["bg"], fg=THEME["text_dim"]
            ).pack(pady=(36, 10))

            recent_frame = Frame(center, bg=THEME["bg"])
            recent_frame.pack(fill="x", padx=80)
            for f in self.recent_files:
                p = Path(f)
                btn = Button(
                    recent_frame, text=f"  {p.name}  —  {p.parent}",
                    font=self.fonts["body"],
                    bg=THEME["surface"], fg=THEME["text"],
                    activebackground=THEME["surface_alt"], activeforeground=THEME["text"],
                    bd=0, padx=16, pady=10, cursor="hand2", anchor="w",
                    command=lambda fp=f: self._open_recent(fp)
                )
                btn.pack(fill="x", pady=3)
        else:
            Label(
                center, text="No recent files — open one to get started.",
                font=self.fonts["small"], bg=THEME["bg"], fg=THEME["text_dim"]
            ).pack(pady=20)

        Label(
            center,
            text="Shortcuts:  A–H select  •  Enter submit / next  •  Esc end session",
            font=self.fonts["small"], bg=THEME["bg"], fg=THEME["text_dim"]
        ).pack(side="bottom", pady=20)

    def _open_file_dialog(self):
        fp = filedialog.askopenfilename(
            title="Open study questions",
            filetypes=[("TOML files", "*.toml"), ("All files", "*.*")]
        )
        if fp and self._load_questions(fp):
            self._start_session()

    def _open_recent(self, filepath):
        if self._load_questions(filepath):
            self._start_session()

    # ─── Session Screen ────────────────────────────────────────────────────────
    def _start_session(self):
        self.queue = self._build_queue()
        self.current_idx = 0
        self.correct_first_try = set()
        self.wrong_log = []
        self.session_active = True
        self._show_question()

    def _show_question(self):
        self._clear_container()
        self.submitted = False
        self.selected_indices = set()
        self.explanation_labels = []

        if self.current_idx < 0 or self.current_idx >= len(self.queue):
            self._show_stats()
            return

        q = self.queue[self.current_idx]
        self.current_question = q
        multi = self._is_multi(q)

        # Progress header
        header = Frame(self.container, bg=THEME["bg"])
        header.pack(fill="x", padx=24, pady=(16, 6))

        score = len(self.correct_first_try)
        progress_text = f"Question {self.current_idx + 1} of {len(self.queue)}   •   Score: {score}"
        Label(
            header, text=progress_text, font=self.fonts["small"],
            bg=THEME["bg"], fg=THEME["text_dim"]
        ).pack(side="left")

        if multi:
            Label(
                header, text="select all that apply", font=self.fonts["small"],
                bg=THEME["bg"], fg=THEME["accent"]
            ).pack(side="right")

        # Progress bar
        bar_frame = Frame(self.container, bg=THEME["border"], height=6)
        bar_frame.pack(fill="x", padx=24, pady=(0, 16))
        bar_frame.pack_propagate(False)
        fill_pct = self.current_idx / max(1, len(self.queue))
        fill = Frame(bar_frame, bg=THEME["accent"])
        fill.place(x=0, y=0, relwidth=fill_pct, relheight=1)

        # Content
        content = Frame(self.container, bg=THEME["bg"])
        content.pack(fill="both", expand=True, padx=24, pady=4)

        Label(
            content, text="Question", font=self.fonts["small"],
            bg=THEME["bg"], fg=THEME["text_dim"]
        ).pack(anchor="w", pady=(0, 4))

        self.question_label = Label(
            content, text=q["question"], font=self.fonts["heading"],
            bg=THEME["bg"], fg=THEME["text"],
            wraplength=820, justify="left", anchor="w"
        )
        self.question_label.pack(fill="x", pady=(0, 16))

        # Choices
        self.choice_buttons = []
        choices = q.get("choices", [])
        for i, choice in enumerate(choices):
            letter = LABELS[i] if i < len(LABELS) else str(i + 1)
            cb = ChoiceButton(content, letter, choice, self._on_choice_click, self)
            cb.pack(fill="x", pady=3)
            self.choice_buttons.append(cb)

        # Feedback
        self.feedback_label = Label(
            content, text="", font=self.fonts["heading"],
            bg=THEME["bg"], fg=THEME["text"],
            wraplength=820, justify="left", anchor="w"
        )
        self.feedback_label.pack(fill="x", pady=(12, 4))

        self.explanation_frame = Frame(content, bg=THEME["bg"])
        self.explanation_frame.pack(fill="x", pady=(0, 8))

        # Action button
        self.action_btn = Button(
            content, text="Submit", font=self.fonts["heading"],
            bg=THEME["accent"], fg="white",
            activebackground=THEME["accent_hover"], activeforeground="white",
            bd=0, padx=36, pady=12, cursor="hand2",
            command=self._on_action
        )
        self.action_btn.pack(pady=(8, 16))

        # Resize handling
        content.bind("<Configure>", lambda e: self._update_wraplengths())
        self.root.after_idle(self._update_wraplengths)

    def _update_wraplengths(self):
        try:
            width = self.container.winfo_width() - 80
            if width < 200:
                width = 600
            if hasattr(self, "question_label") and self.question_label.winfo_exists():
                self.question_label.configure(wraplength=width)
            for cb in self.choice_buttons:
                if cb.winfo_exists():
                    cb.update_wraplength(width)
            for lbl in self.explanation_labels:
                if lbl.winfo_exists():
                    lbl.configure(wraplength=width - 20)
        except Exception:
            pass

    def _on_choice_click(self, index):
        if self.submitted or not self.session_active:
            return
        q = self.current_question
        multi = self._is_multi(q)
        if multi:
            if index in self.selected_indices:
                self.selected_indices.discard(index)
            else:
                self.selected_indices.add(index)
            self.choice_buttons[index].set_selected(index in self.selected_indices)
        else:
            self.selected_indices = {index}
            for i, cb in enumerate(self.choice_buttons):
                cb.set_selected(i in self.selected_indices)

    def _on_letter(self, letter):
        if not self.session_active or self.submitted:
            return
        idx = ord(letter) - ord("A")
        if 0 <= idx < len(self.choice_buttons):
            self._on_choice_click(idx)

    def _on_enter(self, event=None):
        if not self.session_active:
            return
        self._on_action()

    def _on_escape(self, event=None):
        if self.session_active:
            if messagebox.askyesno(
                "End Session",
                "End this study session and return to the welcome screen?"
            ):
                self.session_active = False
                self._show_welcome()

    def _on_action(self):
        if not self.submitted:
            self._submit_answer()
        else:
            self._next_question()

    def _submit_answer(self):
        q = self.current_question
        multi = self._is_multi(q)

        if not self.selected_indices:
            # Briefly flash a hint
            self.feedback_label.configure(
                text="Please select an answer first.", fg=THEME["warning"]
            )
            return

        sorted_idx = sorted(self.selected_indices)
        chosen = [q["choices"][i] for i in sorted_idx]
        if not multi:
            chosen = chosen[0]

        correct = self._check_answer(q, chosen)
        self.submitted = True

        correct_ans = q["answer"] if isinstance(q["answer"], list) else [q["answer"]]

        # Highlight choices
        for i, cb in enumerate(self.choice_buttons):
            choice_text = q["choices"][i]
            if choice_text in correct_ans:
                cb.set_result_state("correct")
            elif i in self.selected_indices:
                cb.set_result_state("wrong")

        # Update question state
        q["_last_chosen"] = chosen
        if correct:
            q["_answered_correct"] = True
            if q["_wrong_count"] == 0:
                self.correct_first_try.add(id(q))
            self.feedback_label.configure(text="✓ Correct!", fg=THEME["correct"])
        else:
            q["_wrong_count"] += 1
            if q["_wrong_count"] == 1:
                self.wrong_log.append({
                    "question": q["question"],
                    "answer": q["answer"],
                    "your_answer": chosen,
                    "timestamp": datetime.now().isoformat()
                })
            ans_display = ", ".join(correct_ans) if isinstance(q["answer"], list) else q["answer"]
            self.feedback_label.configure(
                text=f"✗ Wrong. Correct answer: {ans_display}",
                fg=THEME["wrong"]
            )

        # Show explanations if available
        explanations = q.get("explanations", [])
        if explanations and len(explanations) == len(q["choices"]):
            for w in self.explanation_frame.winfo_children():
                w.destroy()
            self.explanation_labels = []
            for i, exp in enumerate(explanations):
                if not exp:
                    continue
                choice_text = q["choices"][i]
                is_correct = choice_text in correct_ans
                color = THEME["correct"] if is_correct else THEME["text_dim"]
                letter = LABELS[i] if i < len(LABELS) else str(i + 1)
                lbl = Label(
                    self.explanation_frame,
                    text=f"  {letter}. {exp}",
                    font=self.fonts["small"],
                    bg=THEME["bg"], fg=color,
                    wraplength=800, justify="left", anchor="w"
                )
                lbl.pack(fill="x", pady=2)
                self.explanation_labels.append(lbl)

        self.action_btn.configure(text="Next  →")
        self._update_wraplengths()

    def _next_question(self):
        q = self.current_question
        if not q["_answered_correct"]:
            # Spaced re-queue: pop and reinsert 1–4 spots later
            self.queue.pop(self.current_idx)
            insert_at = min(self.current_idx + random.randint(1, 4), len(self.queue))
            self.queue.insert(insert_at, q)
            # current_idx now points to the next question
        else:
            self.current_idx += 1
        self._show_question()

    # ─── Stats Screen ──────────────────────────────────────────────────────────
    def _show_stats(self):
        self._clear_container()
        self.session_active = False
        self._save_wrong_answers()

        total = len(self.questions)
        correct = len(self.correct_first_try)
        wrong = total - correct
        pct = (correct / total * 100) if total > 0 else 0

        center = Frame(self.container, bg=THEME["bg"])
        center.pack(expand=True, fill="both", padx=40, pady=40)

        Label(
            center, text="Session Complete!", font=self.fonts["title"],
            bg=THEME["bg"], fg=THEME["text"]
        ).pack(pady=(20, 20))

        stats_card = Frame(center, bg=THEME["surface"], padx=40, pady=24)
        stats_card.pack()
        stats_inner = Frame(stats_card, bg=THEME["surface"])
        stats_inner.pack()

        rows = [
            ("Total Questions",     str(total),     THEME["text"]),
            ("Correct (first try)", str(correct),   THEME["correct"]),
            ("Wrong",               str(wrong),     THEME["wrong"]),
            ("Score",               f"{pct:.1f}%",  THEME["accent"]),
        ]
        for i, (label, value, color) in enumerate(rows):
            Label(
                stats_inner, text=label, font=self.fonts["body"],
                bg=THEME["surface"], fg=THEME["text_dim"]
            ).grid(row=i, column=0, sticky="e", padx=(20, 30), pady=6)
            Label(
                stats_inner, text=value, font=self.fonts["stat"],
                bg=THEME["surface"], fg=color
            ).grid(row=i, column=1, sticky="w", padx=(30, 20), pady=6)

        btn_frame = Frame(center, bg=THEME["bg"])
        btn_frame.pack(pady=36)

        Button(
            btn_frame, text="  Study Again  ", font=self.fonts["heading"],
            bg=THEME["accent"], fg="white",
            activebackground=THEME["accent_hover"], activeforeground="white",
            bd=0, padx=24, pady=12, cursor="hand2",
            command=self._start_session
        ).pack(side="left", padx=6)

        Button(
            btn_frame, text="  Open Another File  ", font=self.fonts["heading"],
            bg=THEME["surface"], fg=THEME["text"],
            activebackground=THEME["surface_alt"], activeforeground=THEME["text"],
            bd=0, padx=24, pady=12, cursor="hand2",
            command=self._open_file_dialog
        ).pack(side="left", padx=6)

        Button(
            btn_frame, text="  Back to Home  ", font=self.fonts["body"],
            bg=THEME["surface"], fg=THEME["text_dim"],
            activebackground=THEME["surface_alt"], activeforeground=THEME["text"],
            bd=0, padx=24, pady=12, cursor="hand2",
            command=self._show_welcome
        ).pack(side="left", padx=6)

        if self.wrong_log and self.current_filepath:
            wrong_file = Path(self.current_filepath).parent / WRONG_ANSWERS_FILE
            Label(
                center,
                text=f"Wrong answers logged to: {wrong_file}",
                font=self.fonts["small"], bg=THEME["bg"], fg=THEME["text_dim"]
            ).pack(side="bottom", pady=16)


def main():
    root = Tk()
    StudyApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
