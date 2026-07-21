import tkinter as tk
import tkinter.font as tkfont
from tkinter import filedialog, messagebox, ttk
import random
import os
import json

try:
    import tomllib  # Python 3.11+
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        tomllib = None

# ===== Dark Hu Tao color theme =====
BG          = "#1a0e12"   # deep plum-black background
FG          = "#e8d5d5"   # warm cream foreground
ACCENT      = "#d6405a"   # Hu Tao red
SELECT_BG   = "#3a1a25"   # selection background
CORRECT     = "#5fb878"   # green
WRONG       = "#ff5566"   # bright red
DIM         = "#8a6a6a"   # muted text
BORDER      = "#4a2530"   # box borders
QUESTION_BG = "#221218"   # question box bg
MISSED      = "#e8c358"   # missed-correct highlight
HL_CORRECT  = "#1f3a1f"
HL_WRONG    = "#3a1f1f"
HL_MISSED   = "#3a3a1f"

CONFIG_FILE = os.path.expanduser("~/.study_session_config.json")


def wrap_text(text, width):
    lines = []
    for paragraph in text.split('\n'):
        words = paragraph.split(' ')
        current = ""
        for word in words:
            if not current:
                current = word
            elif len(current) + 1 + len(word) <= width:
                current += " " + word
            else:
                lines.append(current)
                current = word
        lines.append(current)
    return lines if lines else [""]


def detect_font_family():
    try:
        available = set(tkfont.families())
    except Exception:
        return "Courier"
    for c in ("JetBrains Mono",
              "JetBrainsMono Nerd Font",
              "JetBrainsMonoNL Nerd Font",
              "JetBrainsMono NF",
              "JetBrains Mono Regular"):
        if c in available:
            return c
    return "Courier"


class StudyApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Study Session")
        self.root.configure(bg=BG)
        self.root.geometry("900x680")
        self.root.minsize(500, 400)

        self.font_family = detect_font_family()
        self.font_size = 12
        self.font = (self.font_family, self.font_size)
        self.tk_font = tkfont.Font(self.root, self.font)

        # session state
        self.questions = []
        self.queue = []
        self.original_count = 0
        self.first_try_correct = 0
        self.unique_wrong = set()
        self.attempts = 0
        self.correct_attempts = 0
        self.wrong_attempts = 0
        self.questions_seen = 0

        self.current = None
        self.cursor = 0
        self.selected = set()
        self.state = "IDLE"
        self.last_was_correct = False
        self.current_orig_idx = -1
        self.current_file = ""

        self.ui_width = 80
        self.after_id = None

        # Load recent files
        self.recent_files = self.load_recent_files()

        self.setup_ui()
        self.bind_keys()

        # Defer initial render to ensure window width is calculated
        self.root.after(100, self.update_ui_width)
        self.show_idle()

    # ===== Config / Recent Files =====
    def load_recent_files(self):
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, 'r') as f:
                    return json.load(f).get('recent', [])
            except Exception:
                return []
        return []

    def save_recent_files(self):
        try:
            with open(CONFIG_FILE, 'w') as f:
                json.dump({'recent': self.recent_files}, f)
        except Exception:
            pass

    def add_to_recent(self, path):
        if path in self.recent_files:
            self.recent_files.remove(path)
        self.recent_files.insert(0, path)
        self.recent_files = self.recent_files[:5]
        self.save_recent_files()

    # ===== UI setup =====
    def setup_ui(self):
        self.header = tk.Label(
            self.root, text="", bg=BG, fg=ACCENT,
            font=self.font, anchor='w', justify='left'
        )
        self.header.pack(fill='x', padx=20, pady=(15, 2))

        # Main Text Container
        self.text_frame = tk.Frame(self.root, bg=BG)
        self.text_frame.pack(fill='both', expand=True, padx=20, pady=(2, 5))

        # Custom themed Scrollbar
        style = ttk.Style()
        try:
            style.theme_use('clam')
        except:
            pass
        style.configure("Vertical.TScrollbar", background=BG, troughcolor=BG, arrowcolor=ACCENT, bordercolor=BG, lightcolor=BG, darkcolor=BG, gripcount=0)
        style.map("Vertical.TScrollbar", background=[('active', SELECT_BG)])

        self.scrollbar = ttk.Scrollbar(self.text_frame, command=self.text_yview, style="Vertical.TScrollbar")
        self.scrollbar.pack(side='right', fill='y')

        self.text = tk.Text(
            self.text_frame, bg=BG, fg=FG, font=self.font,
            insertbackground=FG, wrap='none',
            padx=20, pady=15,
            spacing1=2, spacing3=2,
            highlightthickness=0, bd=0,
            cursor='arrow', takefocus=0,
            yscrollcommand=self.scrollbar.set
        )
        self.text.pack(side='left', fill='both', expand=True)

        # Tags
        self.text.tag_configure('accent',      foreground=ACCENT)
        self.text.tag_configure('dim',         foreground=DIM)
        self.text.tag_configure('correct',     foreground=CORRECT)
        self.text.tag_configure('wrong',       foreground=WRONG)
        self.text.tag_configure('cursor_bg',   background=SELECT_BG)
        self.text.tag_configure('hl_correct',  background=HL_CORRECT, foreground=CORRECT)
        self.text.tag_configure('hl_wrong',    background=HL_WRONG,   foreground=WRONG)
        self.text.tag_configure('hl_missed',   background=HL_MISSED,  foreground=MISSED)
        self.text.tag_configure('border',      foreground=BORDER)
        self.text.tag_configure('question_bg', background=QUESTION_BG)
        self.text.tag_configure('button_tag',  foreground=ACCENT)
        self.text.tag_configure('recent_tag',  foreground=FG)

        # Bindings for choices (up to 30)
        for i in range(30):
            tag = f'choice_{i}'
            self.text.tag_configure(tag)
            self.text.tag_bind(tag, '<Button-1>', lambda e, idx=i: self.on_choice_click(idx))
            self.text.tag_bind(tag, '<Enter>', lambda e, idx=i: self.on_choice_hover(idx, True))
            self.text.tag_bind(tag, '<Leave>', lambda e, idx=i: self.on_choice_hover(idx, False))

        # Bindings for recent files
        for i in range(5):
            tag = f'recent_{i}'
            self.text.tag_bind(tag, '<Button-1>', lambda e, idx=i: self.open_recent(idx))
            self.text.tag_bind(tag, '<Enter>', lambda e, t=tag: self.text.tag_config(t, foreground=ACCENT))
            self.text.tag_bind(tag, '<Leave>', lambda e, t=tag: self.text.tag_config(t, foreground=FG))

        # Bindings for buttons
        self.text.tag_bind('button_tag', '<Button-1>', lambda e: self.browse_file())
        self.text.tag_bind('button_tag', '<Enter>', lambda e: self.text.tag_config('button_tag', foreground=FG))
        self.text.tag_bind('button_tag', '<Leave>', lambda e: self.text.tag_config('button_tag', foreground=ACCENT))

        self.text.configure(state='disabled')

        self.footer = tk.Label(
            self.root, text="", bg=BG, fg=DIM,
            font=self.font, anchor='w', justify='left'
        )
        self.footer.pack(fill='x', padx=20, pady=(2, 15))

        # Bind window resize
        self.text.bind("<Configure>", self.on_resize)

    def text_yview(self, *args):
        self.text.yview(*args)

    def on_resize(self, event):
        if self.after_id:
            self.root.after_cancel(self.after_id)
        self.after_id = self.root.after(50, self.update_ui_width)

    def update_ui_width(self):
        self.root.update_idletasks()
        w = self.text.winfo_width()
        if w <= 1: return  # Not ready yet

        char_width = self.tk_font.measure("M")
        if char_width == 0: return

        # Account for padx (20 + 20) and a small safety margin
        usable_width = w - 45
        new_width = max(30, usable_width // char_width)

        if new_width != self.ui_width:
            self.ui_width = new_width
            self.render_current()

    def on_choice_hover(self, idx, is_enter):
        if self.state == "QUESTION" and idx < len(self.current['choices']):
            if is_enter and idx != self.cursor:
                self.cursor = idx
                self.render_question()

    def bind_keys(self):
        self.root.bind("<Up>",      lambda e: self.on_key('up'))
        self.root.bind("<Down>",    lambda e: self.on_key('down'))
        self.root.bind("k",         lambda e: self.on_key('up'))
        self.root.bind("j",         lambda e: self.on_key('down'))
        self.root.bind("<Return>",  lambda e: self.on_key('enter'))
        self.root.bind("<space>",   lambda e: self.on_key('space'))

        # File & Font bindings
        self.root.bind("o",         lambda e: self.browse_file())
        self.root.bind("O",         lambda e: self.browse_file())
        self.root.bind("+",         lambda e: self.change_font(1))
        self.root.bind("=",         lambda e: self.change_font(1))
        self.root.bind("<KP_Add>",  lambda e: self.change_font(1))
        self.root.bind("-",         lambda e: self.change_font(-1))
        self.root.bind("<KP_Subtract>", lambda e: self.change_font(-1))

        # Recent file shortcuts
        self.root.bind("1",         lambda e: self.open_recent(0))
        self.root.bind("2",         lambda e: self.open_recent(1))
        self.root.bind("3",         lambda e: self.open_recent(2))
        self.root.bind("4",         lambda e: self.open_recent(3))
        self.root.bind("5",         lambda e: self.open_recent(4))

        self.root.bind("r",         lambda e: self.restart_session())
        self.root.bind("R",         lambda e: self.restart_session())
        self.root.bind("q",         lambda e: self.quit_app())
        self.root.bind("Q",         lambda e: self.quit_app())
        self.root.bind("<Escape>",  lambda e: self.quit_app())

    def change_font(self, delta):
        new_size = max(8, min(22, self.font_size + delta))
        if new_size != self.font_size:
            self.font_size = new_size
            self.font = (self.font_family, self.font_size)
            self.tk_font = tkfont.Font(self.root, self.font)
            self.text.config(font=self.font)
            self.header.config(font=self.font)
            self.footer.config(font=self.font)
            self.update_ui_width()  # This will automatically trigger a re-render

    def quit_app(self):
        self.root.destroy()

    # ===== Text helpers =====
    def clear_text(self):
        self.text.configure(state='normal')
        self.text.delete('1.0', 'end')

    def add(self, s, tag=None):
        if tag:
            self.text.insert('end', s, tag)
        else:
            self.text.insert('end', s)

    def finalize(self):
        self.text.configure(state='disabled')
        self.text.see("1.0")

    def render_current(self):
        if self.state == "IDLE": self.show_idle()
        elif self.state == "QUESTION": self.render_question()
        elif self.state == "REVIEW": self.render_review()
        elif self.state == "DONE": self.show_done()

    # ===== State: IDLE =====
    def show_idle(self):
        self.state = "IDLE"
        self.header.config(text=" STUDY SESSION ")
        self.footer.config(text=" [o] Open TOML   [+/-] Font Size   [1-5] Open Recent   [q] Quit")

        self.clear_text()
        width = self.ui_width
        self.add("┌" + "─" * (width - 2) + "┐\n", 'border')
        self.add("│" + " STUDY SESSION ".center(width - 2) + "│\n", 'accent')
        self.add("│" + " " * (width - 2) + "│\n", 'border')
        self.add("│" + " Welcome. Load a TOML question file to begin. ".center(width - 2) + "│\n", 'dim')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        btn_text = " [ Open TOML File ] "
        self.add("│" + btn_text.center(width - 2) + "│\n", 'button_tag')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        if self.recent_files:
            self.add("│" + " Recent Files ".center(width - 2) + "│\n", 'accent')
            self.add("│" + " " * (width - 2) + "│\n", 'border')
            for i, f in enumerate(self.recent_files):
                name = os.path.basename(f)
                max_len = width - 12
                if len(name) > max_len:
                    name = "..." + name[-(max_len-3):]
                line = f" [{i+1}] {name} "
                self.add("│")
                self.text.insert('end', line.ljust(width - 2), f'recent_{i}')
                self.add("│\n")
            self.add("│" + " " * (width - 2) + "│\n", 'border')

        self.add("└" + "─" * (width - 2) + "┘\n", 'border')
        self.finalize()

    # ===== File loading =====
    def browse_file(self):
        path = filedialog.askopenfilename(
            title="Open TOML file",
            filetypes=[("TOML files", "*.toml"), ("All files", "*.*")]
        )
        if path:
            self.load_file(path)

    def open_recent(self, idx):
        if idx < len(self.recent_files):
            path = self.recent_files[idx]
            if os.path.exists(path):
                self.load_file(path)
            else:
                messagebox.showerror("Error", "File not found. It will be removed from recent.")
                self.recent_files.pop(idx)
                self.save_recent_files()
                if self.state == "IDLE":
                    self.show_idle()

    def load_file(self, path):
        try:
            with open(path, 'rb') as f:
                data = tomllib.load(f)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load TOML:\n{e}")
            return

        if 'questions' not in data or not data['questions']:
            messagebox.showerror("Error", "No questions found in TOML file.")
            return

        self.questions = data['questions']
        self.original_count = len(self.questions)
        self.current_file = os.path.basename(path)

        self.add_to_recent(path)

        prepared = []
        for i, q in enumerate(self.questions):
            p = self.prepare_question(q, i)
            if p:
                prepared.append(p)

        if not prepared:
            messagebox.showerror("Error", "No valid questions found.")
            return

        self.queue = prepared
        random.shuffle(self.queue)

        self.first_try_correct = 0
        self.unique_wrong = set()
        self.attempts = 0
        self.correct_attempts = 0
        self.wrong_attempts = 0
        self.questions_seen = 0

        self.next_question()

    def prepare_question(self, q, orig_idx):
        if 'question' not in q or 'choices' not in q or 'answer' not in q:
            return None

        choices = list(q['choices'])
        explanations = list(q.get('explanations', [''] * len(choices)))
        while len(explanations) < len(choices):
            explanations.append('')

        paired = list(zip(choices, explanations))
        random.shuffle(paired)

        scrambled_choices = [p[0] for p in paired]
        scrambled_explanations = [p[1] for p in paired]

        if isinstance(q['answer'], list):
            correct_answers = set(q['answer'])
            is_multiple = True
        else:
            correct_answers = {q['answer']}
            is_multiple = False

        correct_indices = {i for i, c in enumerate(scrambled_choices) if c in correct_answers}

        if len(correct_indices) > 1:
            is_multiple = True

        return {
            'question':        q['question'],
            'choices':         scrambled_choices,
            'explanations':    scrambled_explanations,
            'correct_indices': correct_indices,
            'is_multiple':     is_multiple,
            'orig_idx':        orig_idx,
        }

    # ===== State: QUESTION =====
    def next_question(self):
        if not self.queue:
            self.show_done()
            return

        self.current = self.queue.pop(0)
        self.current_orig_idx = self.current['orig_idx']
        self.questions_seen += 1

        self.cursor = 0
        self.selected = set()
        self.state = "QUESTION"
        self.render_question()

    def render_question(self):
        q = self.current
        self.clear_text()
        width = self.ui_width

        file_info = f"[{self.current_file}] " if self.current_file else ""
        info = (f" {file_info}Q{self.questions_seen}/{self.original_count}"
                f"  │  Queue:{len(self.queue)+1}"
                f"  │  ✓{self.correct_attempts}"
                f"  │  ✗{self.wrong_attempts} ")
        self.add(info + "\n", 'accent')
        self.add("─" * width + "\n", 'border')
        self.add("\n")

        inner_width = width - 4
        self.add("┌" + "─" * (width - 2) + "┐\n", 'border')
        for line in wrap_text(q['question'], inner_width):
            self.add("│ " + line.ljust(inner_width) + " │\n", 'question_bg')
        self.add("└" + "─" * (width - 2) + "┘\n", 'border')
        self.add("\n")

        if q['is_multiple']:
            self.add(" ◆ Multiple answers — Space to select, Enter to submit\n\n", 'accent')
        else:
            self.add(" ◇ Single answer — Enter to submit selection\n\n", 'accent')

        for i, choice in enumerate(q['choices']):
            is_cursor   = (i == self.cursor)
            is_selected = (i in self.selected)
            cursor_marker = "▶" if is_cursor else " "
            checkbox      = "[x]" if is_selected else "[ ]"
            prefix = f" {cursor_marker} {checkbox} "

            avail = max(10, width - len(prefix))
            choice_lines = wrap_text(choice, avail) or [""]
            for j, cl in enumerate(choice_lines):
                line = (prefix + cl) if j == 0 else (" " * len(prefix) + cl)
                line = line.ljust(width)
                tags = [f'choice_{i}']
                if is_cursor:
                    tags.append('cursor_bg')
                self.text.insert('end', line + "\n", tuple(tags))

        self.add("\n")
        self.add(" [↑↓/jk] Navigate   [Space] Select   [Enter] Submit   [+/-] Font   [o] Open   [q] Quit\n", 'dim')

        if q['is_multiple']:
            self.footer.config(text=f" Selected: {len(self.selected)}  |  [Space] toggle  [Enter] submit")
        else:
            self.footer.config(text=" [Enter] submits the highlighted choice")

        self.finalize()

    def on_choice_click(self, idx):
        if self.state != "QUESTION":
            return
        if idx < 0 or idx >= len(self.current['choices']):
            return
        self.cursor = idx
        q = self.current
        if q['is_multiple']:
            if idx in self.selected:
                self.selected.discard(idx)
            else:
                self.selected.add(idx)
        else:
            self.selected = {idx}
        self.render_question()

    def on_key(self, key):
        if self.state == "IDLE":
            if key in ('enter', 'space'):
                self.browse_file()
        elif self.state == "QUESTION":
            if key == 'up':
                self.cursor = (self.cursor - 1) % len(self.current['choices'])
                self.render_question()
            elif key == 'down':
                self.cursor = (self.cursor + 1) % len(self.current['choices'])
                self.render_question()
            elif key == 'space':
                q = self.current
                if q['is_multiple']:
                    if self.cursor in self.selected:
                        self.selected.discard(self.cursor)
                    else:
                        self.selected.add(self.cursor)
                    self.render_question()
                else:
                    self.selected = {self.cursor}
                    self.render_question()
            elif key == 'enter':
                q = self.current
                if q['is_multiple']:
                    if not self.selected:
                        return
                    self.submit_answer()
                else:
                    self.selected = {self.cursor}
                    self.submit_answer()
        elif self.state == "REVIEW":
            if key in ('enter', 'space'):
                self.next_question()
        elif self.state == "DONE":
            if key in ('enter', 'space'):
                if self.questions:
                    self.restart_session()
                else:
                    self.show_idle()

    # ===== State: REVIEW =====
    def submit_answer(self):
        q = self.current
        user_selected = self.selected
        correct_indices = q['correct_indices']

        is_correct = (user_selected == correct_indices)

        self.attempts += 1
        if is_correct:
            self.correct_attempts += 1
            if self.current_orig_idx not in self.unique_wrong:
                self.first_try_correct += 1
        else:
            self.wrong_attempts += 1
            self.unique_wrong.add(self.current_orig_idx)
            requeued = self.prepare_question(
                self.questions[self.current_orig_idx],
                self.current_orig_idx
            )
            if requeued:
                if not self.queue:
                    self.queue.append(requeued)
                else:
                    insert_pos = random.randint(min(3, len(self.queue)), len(self.queue))
                    self.queue.insert(insert_pos, requeued)

        self.last_was_correct = is_correct
        self.state = "REVIEW"
        self.render_review()

    def render_review(self):
        q = self.current
        user_selected = self.selected
        correct_indices = q['correct_indices']

        self.clear_text()
        width = self.ui_width

        file_info = f"[{self.current_file}] " if self.current_file else ""
        info = (f" {file_info}Q{self.questions_seen}/{self.original_count}"
                f"  │  Queue:{len(self.queue)}"
                f"  │  ✓{self.correct_attempts}"
                f"  │  ✗{self.wrong_attempts} ")
        self.add(info + "\n", 'accent')
        self.add("─" * width + "\n", 'border')
        self.add("\n")

        inner_width = width - 4
        self.add("┌" + "─" * (width - 2) + "┐\n", 'border')
        for line in wrap_text(q['question'], inner_width):
            self.add("│ " + line.ljust(inner_width) + " │\n", 'question_bg')
        self.add("└" + "─" * (width - 2) + "┘\n", 'border')
        self.add("\n")

        if self.last_was_correct:
            self.add(" ✓ CORRECT\n\n", 'correct')
        else:
            self.add(" ✗ WRONG — re-queuing for recall\n\n", 'wrong')

        for i, (choice, expl) in enumerate(zip(q['choices'], q['explanations'])):
            is_correct_choice = (i in correct_indices)
            user_picked       = (i in user_selected)

            checkbox = "[x]" if user_picked else "[ ]"
            mark = "  ✓" if is_correct_choice else ("  ✗" if user_picked else "")
            prefix = f"   {checkbox} "

            if is_correct_choice and user_picked:
                line_tag = 'hl_correct'
            elif is_correct_choice and not user_picked:
                line_tag = 'hl_missed'
            elif not is_correct_choice and user_picked:
                line_tag = 'hl_wrong'
            else:
                line_tag = 'dim'

            avail = max(10, width - len(prefix) - len(mark))
            choice_lines = wrap_text(choice, avail) or [""]
            for j, cl in enumerate(choice_lines):
                line = (prefix + cl + mark) if j == 0 else (" " * len(prefix) + cl)
                line = line.ljust(width)
                self.add(line + "\n", line_tag)

            if expl:
                for el in wrap_text(expl, width - 8):
                    color = 'correct' if is_correct_choice else 'dim'
                    self.add("       " + el + "\n", color)

        self.add("\n")
        self.add("─" * width + "\n", 'border')
        self.add("\n")

        if self.queue:
            self.add(" Press [Enter] for next question   [+/-] Font   [q] Quit\n", 'dim')
        else:
            self.add(" Press [Enter] to see session stats   [+/-] Font   [q] Quit\n", 'dim')

        self.footer.config(
            text=f" {'✓ CORRECT' if self.last_was_correct else '✗ WRONG — re-queued'}"
        )
        self.finalize()

    # ===== State: DONE =====
    def show_done(self):
        self.state = "DONE"
        self.clear_text()

        width = self.ui_width
        self.add("┌" + "─" * (width - 2) + "┐\n", 'border')
        self.add("│" + " SESSION COMPLETE ".center(width - 2) + "│\n", 'accent')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        stats = [
            ("Total questions",     f"{self.original_count}"),
            ("Total attempts",      f"{self.attempts}"),
            ("Correct first try",   f"{self.first_try_correct}"),
            ("Wrong (unique)",      f"{len(self.unique_wrong)}"),
            ("Correct attempts",    f"{self.correct_attempts}"),
            ("Wrong attempts",      f"{self.wrong_attempts}"),
        ]
        if self.attempts > 0:
            acc = (self.correct_attempts / self.attempts) * 100
            stats.append(("Accuracy", f"{acc:.1f}%"))
        if self.original_count > 0:
            first_rate = (self.first_try_correct / self.original_count) * 100
            stats.append(("First-try rate", f"{first_rate:.1f}%"))

        inner_width = width - 4
        left_w  = inner_width // 2
        right_w = inner_width - left_w
        for label, value in stats:
            left  = f" {label}:"
            right = f"{value} "
            line = left.ljust(left_w) + right.rjust(right_w)
            self.add("│ " + line + " │\n", 'question_bg')

        self.add("│" + " " * (width - 2) + "│\n", 'border')
        self.add("└" + "─" * (width - 2) + "┘\n", 'border')
        self.add("\n")

        if self.unique_wrong:
            self.add(" Questions you got wrong (need review):\n\n", 'wrong')
            for idx in sorted(self.unique_wrong):
                q_text = self.questions[idx].get('question', '?')
                max_len = width - 8
                if len(q_text) > max_len:
                    q_text = q_text[:max_len-3] + "..."
                self.add(f"   • {q_text}\n", 'dim')
            self.add("\n")

        self.add(" Press [r] to start a new session   [+/-] Font   [q] Quit\n", 'dim')

        self.header.config(text=" STUDY SESSION — COMPLETE ")
        self.footer.config(text=" [r] New session   [q] Quit")
        self.finalize()

    def restart_session(self):
        if not self.questions:
            self.show_idle()
            return
        self.queue = []
        for i, q in enumerate(self.questions):
            p = self.prepare_question(q, i)
            if p:
                self.queue.append(p)
        random.shuffle(self.queue)
        self.first_try_correct = 0
        self.unique_wrong = set()
        self.attempts = 0
        self.correct_attempts = 0
        self.wrong_attempts = 0
        self.questions_seen = 0
        self.next_question()


def main():
    if tomllib is None:
        print("Error: tomllib (Python 3.11+) or 'tomli' package required.")
        print("Install with: pip install tomli")
        return
    root = tk.Tk()
    StudyApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
