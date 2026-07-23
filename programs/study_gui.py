import tkinter as tk
import tkinter.font as tkfont
from tkinter import filedialog, messagebox, ttk
import random
import os
import json
import time

try:
    import tomllib  # Python 3.11+
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        tomllib = None

# ===== High Contrast Dark Hu Tao color theme =====
BG          = "#120608"   # near-black plum background
FG          = "#f5ebeb"   # bright cream foreground
ACCENT      = "#ff4d6d"   # bright Hu Tao red
SELECT_BG   = "#4a2028"   # visible selection background
CORRECT     = "#5af0a0"   # neon green
WRONG       = "#ff5566"   # bright red
DIM         = "#b09a9a"   # lighter dim for readability
BORDER      = "#7a3a48"   # brighter box borders
QUESTION_BG = "#241218"   # question box bg
MISSED      = "#ffd060"   # bright yellow for missed-correct
HL_CORRECT  = "#1f4a1f"   # dark green highlight
HL_WRONG    = "#4a1f1f"   # dark red highlight
HL_MISSED   = "#4a4a1f"   # dark yellow highlight

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
    for c in ("JetBrains Mono", "JetBrainsMono Nerd Font", "JetBrainsMono NF", "Courier"):
        if c in available:
            return c
    return "Courier"


def format_time(seconds):
    mins = int(seconds) // 60
    secs = int(seconds) % 60
    return f"{mins:02d}:{secs:02d}"


class StudyApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Study Session")
        self.root.configure(bg=BG)
        self.root.geometry("900x700")
        self.root.minsize(500, 400)

        self.font_family = detect_font_family()
        self.font_size = 12
        self.font = (self.font_family, self.font_size)
        self.tk_font = tkfont.Font(self.root, self.font)

        # Session State
        self.questions = []
        self.queue = []
        self.history = []
        self.history_idx = -1

        self.original_count = 0
        self.first_try_correct = 0
        self.unique_wrong = set()
        self.attempts = 0
        self.correct_attempts = 0
        self.wrong_attempts = 0

        self.current = None
        self.cursor = 0
        self.selected = set()
        self.state = "IDLE"
        self.show_reference = False

        # Course Reader Notes Table: { "1.1": {"title": "...", "content": "..."} }
        self.subtopic_notes = {}
        self.course_dir = ""
        self.course_title = "Course Modules"
        self.chapters = []

        # Timers
        self.session_start_time = 0
        self.q_start_time = 0
        self.total_time = 0
        self.timer_id = None

        self.ui_width = 80
        self.after_id = None
        self.recent_files = self.load_recent_files()

        self.setup_ui()
        self.bind_keys()
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

    # ===== UI Setup =====
    def setup_ui(self):
        self.header = tk.Label(self.root, text="", bg=BG, fg=ACCENT, font=self.font, anchor='w')
        self.header.pack(fill='x', padx=20, pady=(15, 2))

        self.text_frame = tk.Frame(self.root, bg=BG)
        self.text_frame.pack(fill='both', expand=True, padx=20, pady=(2, 15))

        style = ttk.Style()
        try: style.theme_use('clam')
        except: pass
        style.configure("Vertical.TScrollbar", background=BG, troughcolor=BG, arrowcolor=ACCENT, bordercolor=BG)

        self.scrollbar = ttk.Scrollbar(self.text_frame, command=self.text_yview, style="Vertical.TScrollbar")
        self.scrollbar.pack(side='right', fill='y')

        self.text = tk.Text(
            self.text_frame, bg=BG, fg=FG, font=self.font,
            insertbackground=FG, wrap='none', padx=20, pady=15,
            highlightthickness=0, bd=0, cursor='arrow',
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

        for i in range(30):
            tag = f'choice_{i}'
            self.text.tag_bind(tag, '<Button-1>', lambda e, idx=i: self.on_choice_click(idx))

        for i in range(20):
            tag = f'ch_{i}'
            self.text.tag_bind(tag, '<Button-1>', lambda e, idx=i: self.load_chapter_by_index(idx))

        for i in range(5):
            tag = f'recent_{i}'
            self.text.tag_bind(tag, '<Button-1>', lambda e, idx=i: self.open_recent(idx))

        self.text.tag_bind('btn_open_file',  '<Button-1>', lambda e: self.browse_file())
        self.text.tag_bind('btn_open_dir',   '<Button-1>', lambda e: self.browse_directory())
        self.text.tag_bind('btn_mock_exam',  '<Button-1>', lambda e: self.start_mock_exam())
        self.text.tag_bind('btn_all_ch',     '<Button-1>', lambda e: self.start_combined_course())
        self.text.tag_bind('btn_ref_toggle', '<Button-1>', lambda e: self.toggle_reference())

        for tag in ('btn_submit', 'btn_prev', 'btn_next', 'btn_open_file', 'btn_open_dir', 'btn_mock_exam', 'btn_all_ch', 'btn_ref_toggle'):
            self.text.tag_configure(tag, foreground=ACCENT)

        self.text.configure(state='disabled')
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
        if w <= 1: return
        char_width = self.tk_font.measure("M")
        if char_width == 0: return
        usable_width = w - 45
        new_width = max(30, usable_width // char_width)

        if new_width != self.ui_width:
            self.ui_width = new_width
            self.render_current()

    def bind_keys(self):
        self.root.bind("<Up>",      lambda e: self.on_key('up'))
        self.root.bind("<Down>",    lambda e: self.on_key('down'))
        self.root.bind("k",         lambda e: self.on_key('up'))
        self.root.bind("j",         lambda e: self.on_key('down'))
        self.root.bind("<Return>",  lambda e: self.on_key('enter'))
        self.root.bind("<space>",   lambda e: self.on_key('space'))

        self.root.bind("<Left>",    lambda e: self.prev_question())
        self.root.bind("<Right>",   lambda e: self.on_key('right'))
        self.root.bind("h",         lambda e: self.prev_question())
        self.root.bind("l",         lambda e: self.on_key('right'))

        self.root.bind("o",         lambda e: self.browse_file())
        self.root.bind("d",         lambda e: self.browse_directory())
        self.root.bind("r",         lambda e: self.toggle_reference() if self.state == "QUESTION" else self.restart_session())
        self.root.bind("m",         lambda e: self.start_mock_exam() if self.state == "COURSE_MENU" else None)

        self.root.bind("1",         lambda e: self.open_recent_or_chapter(0))
        self.root.bind("2",         lambda e: self.open_recent_or_chapter(1))
        self.root.bind("3",         lambda e: self.open_recent_or_chapter(2))
        self.root.bind("4",         lambda e: self.open_recent_or_chapter(3))
        self.root.bind("5",         lambda e: self.open_recent_or_chapter(4))

        self.root.bind("q",         lambda e: self.quit_app())
        self.root.bind("<Escape>",  lambda e: self.show_idle() if self.state == "COURSE_MENU" else self.quit_app())

    def open_recent_or_chapter(self, idx):
        if self.state == "COURSE_MENU": self.load_chapter_by_index(idx)
        elif self.state == "IDLE": self.open_recent(idx)

    def toggle_reference(self):
        if self.state == "QUESTION":
            self.show_reference = not self.show_reference
            self.render_question()

    def quit_app(self):
        if self.timer_id: self.root.after_cancel(self.timer_id)
        self.root.destroy()

    # ===== Timers =====
    def start_timer(self):
        self.session_start_time = time.time()
        self.q_start_time = time.time()
        self.update_timer()

    def update_timer(self):
        if self.state in ("QUESTION", "REVIEW"):
            elapsed = time.time() - self.session_start_time
            q_elapsed = time.time() - self.q_start_time
            self.header.config(text=f" STUDY SESSION │ Total: {format_time(elapsed)} │ Q-Time: {format_time(q_elapsed)} ")
            self.timer_id = self.root.after(1000, self.update_timer)

    def stop_timer(self):
        if self.timer_id:
            self.root.after_cancel(self.timer_id)
            self.timer_id = None
        self.header.config(text=" STUDY SESSION ")

    # ===== Text Helpers =====
    def clear_text(self):
        self.text.configure(state='normal')
        self.text.delete('1.0', 'end')

    def add(self, s, tag=None):
        if tag: self.text.insert('end', s, tag)
        else: self.text.insert('end', s)

    def finalize(self):
        self.text.configure(state='disabled')

    def render_current(self):
        if self.state == "IDLE": self.show_idle()
        elif self.state == "COURSE_MENU": self.show_course_menu()
        elif self.state == "QUESTION": self.render_question()
        elif self.state == "DONE": self.show_done()

    # ===== State: IDLE =====
    def show_idle(self):
        self.state = "IDLE"
        self.stop_timer()
        self.clear_text()
        width = self.ui_width

        self.add("┌" + "─" * (width - 2) + "┐\n", 'border')
        self.add("│" + " STUDY SESSION ".center(width - 2) + "│\n", 'accent')
        self.add("│" + " " * (width - 2) + "│\n", 'border')
        self.add("│" + " Select a file or course directory to begin ".center(width - 2) + "│\n", 'dim')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        self.add("│" + " [ Open Single Question File (o) ] ".center(width - 2) + "│\n", 'btn_open_file')
        self.add("│" + " [ Open Course Directory (d) ] ".center(width - 2) + "│\n", 'btn_open_dir')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        if self.recent_files:
            self.add("│" + " Recent Items ".center(width - 2) + "│\n", 'accent')
            for i, f in enumerate(self.recent_files):
                name = os.path.basename(f)
                if os.path.isdir(f): name = f"📁 {name}/"
                max_len = width - 12
                if len(name) > max_len: name = "..." + name[-(max_len-3):]
                line = f" [{i+1}] {name} "
                self.add("│")
                self.text.insert('end', line.ljust(width - 2), f'recent_{i}')
                self.add("│\n")
            self.add("│" + " " * (width - 2) + "│\n", 'border')

        self.add("│" + " [o] Open File  [d] Course Dir  [1-5] Recent  [q] Quit ".center(width - 2) + "│\n", 'dim')
        self.add("└" + "─" * (width - 2) + "┘\n", 'border')
        self.finalize()

    # ===== Directory & Course Master Reader Parsing =====
    def browse_directory(self):
        path = filedialog.askdirectory(title="Select Course Directory")
        if path: self.load_course_directory(path)

    def browse_file(self):
        path = filedialog.askopenfilename(title="Open TOML file", filetypes=[("TOML files", "*.toml")])
        if path:
            if os.path.basename(path) in ("course.toml", "curriculum.toml"):
                self.load_course_directory(os.path.dirname(path))
            else:
                self.load_single_file(path)

    def open_recent(self, idx):
        if idx < len(self.recent_files):
            path = self.recent_files[idx]
            if os.path.exists(path):
                if os.path.isdir(path): self.load_course_directory(path)
                else: self.load_single_file(path)
            else:
                self.recent_files.pop(idx)
                self.save_recent_files()
                self.show_idle()

    def load_course_directory(self, path):
        self.course_dir = path
        self.chapters = []
        self.subtopic_notes = {}
        self.add_to_recent(path)

        # Look for master course manifest
        course_file = None
        for candidate in ("course.toml", "curriculum.toml"):
            p = os.path.join(path, candidate)
            if os.path.exists(p):
                course_file = p
                break

        search_dir = os.path.join(path, "questions") if os.path.exists(os.path.join(path, "questions")) else path

        if course_file:
            try:
                with open(course_file, 'rb') as f:
                    manifest = tomllib.load(f)
                    self.course_title = manifest.get('course_title', 'Course Modules')

                    # Parse chapters & build Master Reader Lookup Table
                    for ch in manifest.get('chapters', []):
                        for sub in ch.get('subtopics', []):
                            sub_id = str(sub.get('id', ''))
                            if sub_id:
                                self.subtopic_notes[sub_id] = {
                                    'title': sub.get('title', ''),
                                    'content': sub.get('content', 'No detailed textbook notes available for this subtopic.')
                                }

                        fname = ch.get('file_name', f"ch{ch.get('id', 0):02d}.toml")
                        fpath = os.path.join(search_dir, fname)
                        if not os.path.exists(fpath):
                            # Search by title match
                            fpath = os.path.join(search_dir, f"{ch.get('title', '').lower().replace(' ', '_')}.toml")

                        cnt = self.count_questions_in_file(fpath) if os.path.exists(fpath) else 0
                        self.chapters.append({'title': ch.get('title', fname), 'file': fpath, 'count': cnt})
            except Exception as e:
                print(f"Error reading course manifest: {e}")

        # Fallback if no course manifest was present
        if not self.chapters:
            self.course_title = os.path.basename(path).replace("_", " ").title()
            for root_dir, _, files in os.walk(search_dir):
                for file in sorted(files):
                    if file.endswith('.toml') and file not in ('course.toml', 'curriculum.toml'):
                        fpath = os.path.join(root_dir, file)
                        cnt = self.count_questions_in_file(fpath)
                        if cnt > 0:
                            title = file.replace('.toml', '').replace('_', ' ').title()
                            self.chapters.append({'title': title, 'file': fpath, 'count': cnt})

        if not self.chapters:
            messagebox.showerror("Error", "No valid question files found in this directory.")
            return

        self.show_course_menu()

    def count_questions_in_file(self, path):
        try:
            with open(path, 'rb') as f:
                data = tomllib.load(f)
                return len(data.get('questions', []))
        except Exception:
            return 0

    # ===== State: COURSE MENU =====
    def show_course_menu(self):
        self.state = "COURSE_MENU"
        self.stop_timer()
        self.clear_text()
        width = self.ui_width

        self.add("┌" + "─" * (width - 2) + "┐\n", 'border')
        self.add("│" + f" COURSE: {self.course_title} ".center(width - 2) + "│\n", 'accent')
        self.add("├" + "─" * (width - 2) + "┤\n", 'border')

        total_qs = sum(c['count'] for c in self.chapters if os.path.exists(c['file']))
        self.add("│" + f" Select a chapter or practice mode ({total_qs} Total Questions) ".center(width - 2) + "│\n", 'dim')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        self.add("│" + " [ 🎲 Full Mock Final Exam ] ".center(width - 2) + "│\n", 'btn_mock_exam')
        self.add("│" + " [ 📚 All Chapters Combined ] ".center(width - 2) + "│\n", 'btn_all_ch')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        self.add("│" + " CHAPTER MODULES ".center(width - 2) + "│\n", 'accent')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        for i, ch in enumerate(self.chapters[:20]):
            label = f" [{i+1}] {ch['title']}"
            cnt_str = f"({ch['count']} Qs) "
            pad = width - 4 - len(label) - len(cnt_str)
            line = label + " " * max(0, pad) + cnt_str
            self.add("│ ")
            self.text.insert('end', line, f'ch_{i}')
            self.add(" │\n")

        self.add("│" + " " * (width - 2) + "│\n", 'border')
        self.add("│" + " [1-9] Open Chapter  [m] Mock Final  [Esc] Back ".center(width - 2) + "│\n", 'dim')
        self.add("└" + "─" * (width - 2) + "┘\n", 'border')
        self.finalize()

    def load_chapter_by_index(self, idx):
        if idx < len(self.chapters) and os.path.exists(self.chapters[idx]['file']):
            self.start_quiz_session([self.chapters[idx]['file']])

    def start_combined_course(self):
        files = [c['file'] for c in self.chapters if os.path.exists(c['file'])]
        self.start_quiz_session(files)

    def start_mock_exam(self):
        all_questions = []
        for ch in self.chapters:
            if os.path.exists(ch['file']):
                qs = self.load_raw_questions_from_file(ch['file'])
                sample_size = min(len(qs), 4)
                all_questions.extend(random.sample(qs, sample_size))

        random.shuffle(all_questions)
        self.init_quiz_state(all_questions, "Mock Final Exam")

    def load_single_file(self, path):
        self.add_to_recent(path)
        qs = self.load_raw_questions_from_file(path)
        if qs: self.init_quiz_state(qs, os.path.basename(path))

    def start_quiz_session(self, file_paths):
        combined = []
        for path in file_paths:
            combined.extend(self.load_raw_questions_from_file(path))
        if combined:
            title = "Combined Session" if len(file_paths) > 1 else os.path.basename(file_paths[0])
            self.init_quiz_state(combined, title)

    def load_raw_questions_from_file(self, path):
        try:
            with open(path, 'rb') as f:
                data = tomllib.load(f)
                return data.get('questions', [])
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load {os.path.basename(path)}:\n{e}")
            return []

    def init_quiz_state(self, raw_questions, session_title):
        self.questions = raw_questions
        self.original_count = len(self.questions)
        self.current_file = session_title

        prepared = []
        for i, q in enumerate(self.questions):
            p = self.prepare_question(q, i)
            if p: prepared.append(p)

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
        self.history = []
        self.history_idx = -1
        self.show_reference = False

        self.start_timer()
        self.next_question()

    def prepare_question(self, q, orig_idx):
        if 'question' not in q or 'choices' not in q or 'answer' not in q:
            return None

        choices = list(q['choices'])
        explanations = list(q.get('explanations', [''] * len(choices)))
        while len(explanations) < len(choices): explanations.append('')

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
        if len(correct_indices) > 1: is_multiple = True

        return {
            'question':        q['question'],
            'choices':         scrambled_choices,
            'explanations':    scrambled_explanations,
            'correct_indices': correct_indices,
            'is_multiple':     is_multiple,
            'orig_idx':        orig_idx,
            'answered':        False,
            'user_selected':   set(),
            'last_was_correct':False,
            'subtopic_id':     str(q.get('subtopic_id', '')),
            'section':         q.get('section', ''),
            'context':         q.get('context', '')
        }

    # ===== Navigation =====
    def next_question(self):
        if self.history_idx < len(self.history) - 1:
            self.history_idx += 1
            self.current = self.history[self.history_idx]
        else:
            if not self.queue:
                self.show_done()
                return
            self.current = self.queue.pop(0)
            self.history.append(self.current)
            self.history_idx += 1

        self.cursor = 0
        self.selected = set(self.current.get('user_selected', []))
        self.state = "QUESTION"
        self.q_start_time = time.time()
        self.render_question()

    def prev_question(self):
        if self.history_idx > 0:
            self.history_idx -= 1
            self.current = self.history[self.history_idx]
            self.cursor = 0
            self.selected = set(self.current.get('user_selected', []))
            self.state = "QUESTION"
            self.render_question()

    # ===== State: QUESTION =====
    def render_question(self):
        q = self.current
        is_answered = q.get('answered', False)
        is_last = (self.history_idx == len(self.history) - 1)

        self.clear_text()
        width = self.ui_width

        file_info = f"[{self.current_file}] " if self.current_file else ""
        info = (f" {file_info}Q{self.history_idx + 1}/{len(self.history) + len(self.queue)}"
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

        if is_answered:
            if q['last_was_correct']: self.add(" ✓ CORRECT\n\n", 'correct')
            else: self.add(" ✗ WRONG — reviewed\n\n", 'wrong')
        else:
            if q['is_multiple']: self.add(" ◆ Multiple answers — Space to select, Enter to submit\n\n", 'accent')
            else: self.add(" ◇ Single answer — Enter to submit selection\n\n", 'accent')

        for i, choice in enumerate(q['choices']):
            is_cursor   = (i == self.cursor) and not is_answered
            is_selected = (i in self.selected)
            cursor_marker = "▶" if is_cursor else " "
            checkbox      = "[x]" if is_selected else "[ ]"
            prefix = f" {cursor_marker} {checkbox} "

            if is_answered:
                is_correct_choice = (i in q['correct_indices'])
                user_picked       = (i in self.selected)
                mark = "  ✓" if is_correct_choice else ("  ✗" if user_picked else "")
                if is_correct_choice and user_picked: line_tag = 'hl_correct'
                elif is_correct_choice and not user_picked: line_tag = 'hl_missed'
                elif not is_correct_choice and user_picked: line_tag = 'hl_wrong'
                else: line_tag = 'dim'
            else:
                mark = ""
                line_tag = None
                tags = [f'choice_{i}']
                if is_cursor: tags.append('cursor_bg')

            avail = max(10, width - len(prefix) - len(mark))
            choice_lines = wrap_text(choice, avail) or [""]
            for j, cl in enumerate(choice_lines):
                line = (prefix + cl + mark) if j == 0 else (" " * len(prefix) + cl)
                line = line.ljust(width)
                if is_answered: self.add(line + "\n", line_tag)
                else: self.text.insert('end', line + "\n", tuple(tags))

            if is_answered:
                expl = q['explanations'][i]
                if expl:
                    for el in wrap_text(expl, width - 8):
                        color = 'correct' if is_correct_choice else 'dim'
                        self.add("       " + el + "\n", color)

        # ===== MASTER READER REFERENCE CARD =====
        if is_answered and self.show_reference:
            sub_id = q.get('subtopic_id', '')
            note = self.subtopic_notes.get(sub_id, {})

            sec_title = note.get('title', q.get('section', 'Course Reference'))
            sec_content = note.get('content', q.get('context', 'No course notes found for this section.'))

            self.add("\n")
            self.add("┌" + "─" * (width - 2) + "┐\n", 'border')
            self.add("│ " + f"📖 COURSE MATERIAL [{sub_id}]: {sec_title}".ljust(width - 4) + " │\n", 'accent')
            self.add("├" + "─" * (width - 2) + "┤\n", 'border')

            for paragraph in sec_content.strip().split('\n'):
                if not paragraph.strip():
                    self.add("│" + " " * (width - 2) + "│\n", 'border')
                    continue
                for wrapped in wrap_text(paragraph, width - 6):
                    self.add("│   " + wrapped.ljust(width - 6) + " │\n", 'dim')

            self.add("└" + "─" * (width - 2) + "┘\n", 'border')

        self.add("\n")

        # Action Buttons Row
        btns = []
        if self.history_idx > 0: btns.append(("[ < Prev ]", 'btn_prev'))
        if not is_answered and is_last:
            btns.append(("[ Submit ]", 'btn_submit'))
        else:
            if is_answered:
                ref_lbl = "[ Hide Ref (r) ]" if self.show_reference else "[ Read Course Notes (r) ]"
                btns.append((ref_lbl, 'btn_ref_toggle'))
            if is_last and not self.queue: btns.append(("[ Stats ]", 'btn_stats'))
            else: btns.append(("[ Next > ]", 'btn_next'))

        btn_text = "   ".join([b[0] for b in btns])
        pad = max(0, (width - len(btn_text)) // 2)
        self.add(" " * pad)
        for text, tag in btns:
            self.text.insert('end', text, tag)
            self.add("   ")
        self.add("\n\n")

        self.add(" [↑↓/jk] Navigate   [Space] Select   [Enter] Submit/Next   [r] Course Notes   [q] Quit\n", 'dim')
        self.finalize()

    def on_choice_click(self, idx):
        if self.state != "QUESTION" or self.current.get('answered', False): return
        if self.history_idx != len(self.history) - 1: return
        if idx < 0 or idx >= len(self.current['choices']): return

        self.cursor = idx
        q = self.current
        if q['is_multiple']:
            if idx in self.selected: self.selected.discard(idx)
            else: self.selected.add(idx)
        else:
            self.selected = {idx}
        self.render_question()

    def on_key(self, key):
        if self.state == "IDLE":
            if key in ('enter', 'space'): self.browse_file()
        elif self.state == "QUESTION":
            is_answered = self.current.get('answered', False)
            is_last = (self.history_idx == len(self.history) - 1)

            if key == 'up' and not is_answered:
                self.cursor = (self.cursor - 1) % len(self.current['choices'])
                self.render_question()
            elif key == 'down' and not is_answered:
                self.cursor = (self.cursor + 1) % len(self.current['choices'])
                self.render_question()
            elif key == 'left':
                self.prev_question()
            elif key == 'right':
                if is_answered or not is_last: self.next_question()
            elif key == 'space' and not is_answered:
                q = self.current
                if q['is_multiple']:
                    if self.cursor in self.selected: self.selected.discard(self.cursor)
                    else: self.selected.add(self.cursor)
                else: self.selected = {self.cursor}
                self.render_question()
            elif key == 'enter':
                if is_answered or not is_last:
                    self.next_question()
                else:
                    q = self.current
                    if q['is_multiple']:
                        if not self.selected: return
                        self.submit_answer()
                    else:
                        self.selected = {self.cursor}
                        self.submit_answer()
        elif self.state == "DONE":
            if key in ('enter', 'space', 'right'):
                if self.chapters: self.show_course_menu()
                elif self.questions: self.restart_session()
                else: self.show_idle()

    def submit_answer(self):
        if self.current.get('answered', False): return
        if self.history_idx != len(self.history) - 1: return

        q = self.current
        user_selected = self.selected
        correct_indices = q['correct_indices']
        is_correct = (user_selected == correct_indices)

        q['answered'] = True
        q['user_selected'] = set(user_selected)
        q['last_was_correct'] = is_correct

        self.attempts += 1
        if is_correct:
            self.correct_attempts += 1
            if q['orig_idx'] not in self.unique_wrong:
                self.first_try_correct += 1
        else:
            self.wrong_attempts += 1
            self.unique_wrong.add(q['orig_idx'])
            requeued = self.prepare_question(self.questions[q['orig_idx']], q['orig_idx'])
            if requeued:
                if not self.queue: self.queue.append(requeued)
                else:
                    insert_pos = random.randint(min(3, len(self.queue)), len(self.queue))
                    self.queue.insert(insert_pos, requeued)

        self.render_question()

    # ===== State: DONE =====
    def show_done(self):
        self.state = "DONE"
        self.stop_timer()
        self.clear_text()
        width = self.ui_width

        self.add("┌" + "─" * (width - 2) + "┐\n", 'border')
        self.add("│" + " SESSION COMPLETE ".center(width - 2) + "│\n", 'accent')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        avg_q_time = self.total_time / self.attempts if self.attempts > 0 else 0

        stats = [
            ("Total questions",     f"{self.original_count}"),
            ("Total attempts",      f"{self.attempts}"),
            ("Correct first try",   f"{self.first_try_correct}"),
            ("Wrong (unique)",      f"{len(self.unique_wrong)}"),
            ("Correct attempts",    f"{self.correct_attempts}"),
            ("Wrong attempts",      f"{self.wrong_attempts}"),
            ("Total time",          f"{format_time(self.total_time)}"),
            ("Avg time/question",   f"{format_time(avg_q_time)}"),
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

        self.add(" Press [Enter/Space] to return to menu   [q] Quit\n", 'dim')
        self.header.config(text=" STUDY SESSION — COMPLETE ")
        self.finalize()

    def restart_session(self):
        if self.chapters: self.show_course_menu()
        elif self.questions: self.init_quiz_state(self.questions, self.current_file)
        else: self.show_idle()


def main():
    if tomllib is None:
        print("Error: tomllib (Python 3.11+) or 'tomli' required.")
        return
    root = tk.Tk()
    StudyApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
