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
ENTRY_BG    = "#1f0a0e"   # input field bg

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


def format_time(seconds):
    mins = int(seconds) // 60
    secs = int(seconds) % 60
    return f"{mins:02d}:{secs:02d}"


def serialize_toml(questions):
    """Converts Python dict of questions back to TOML format."""
    def esc(s):
        return str(s).replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

    toml_str = "version = 5\n\n"
    for q in questions:
        toml_str += "[[questions]]\n"
        toml_str += f'question = "{esc(q.get("question", ""))}"\n'

        choices = q.get('choices', [])
        toml_str += 'choices = [' + ', '.join([f'"{esc(c)}"' for c in choices]) + ']\n'

        ans = q.get('answer', "")
        if isinstance(ans, list):
            toml_str += 'answer = [' + ', '.join([f'"{esc(a)}"' for a in ans]) + ']\n'
        else:
            toml_str += f'answer = "{esc(ans)}"\n'

        exps = q.get('explanations', [""] * len(choices))
        while len(exps) < len(choices): exps.append("")
        toml_str += 'explanations = [' + ', '.join([f'"{esc(e)}"' for e in exps]) + ']\n\n'

    return toml_str


# ===== Question Editor Window =====
class EditorWindow(tk.Toplevel):
    def __init__(self, master, app, edit_idx=None):
        super().__init__(master)
        self.app = app
        self.edit_idx = edit_idx
        self.title("Edit Question" if edit_idx is not None else "Question Editor")
        self.configure(bg=BG)
        self.geometry("800x700")
        self.font = app.font
        self.grab_set()  # Modal

        self.choice_rows = []
        self.setup_ui()

        # If editing, populate fields
        if edit_idx is not None:
            self.populate_fields(app.questions[edit_idx])

    def setup_ui(self):
        tk.Label(self, text=" QUESTION EDITOR ", bg=BG, fg=ACCENT, font=self.font).pack(fill='x', pady=(10, 5))

        container = tk.Frame(self, bg=BG)
        container.pack(fill='both', expand=True, padx=20, pady=5)

        canvas = tk.Canvas(container, bg=BG, highlightthickness=0)
        scrollbar = ttk.Scrollbar(container, orient="vertical", command=canvas.yview, style="Vertical.TScrollbar")
        self.scroll_frame = tk.Frame(canvas, bg=BG)

        self.scroll_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        canvas.create_window((0, 0), window=self.scroll_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        tk.Label(self.scroll_frame, text="Question Text:", bg=BG, fg=FG, font=self.font).pack(anchor='w', pady=(5, 0))
        self.q_text = tk.Text(self.scroll_frame, height=3, bg=ENTRY_BG, fg=FG, insertbackground=FG, font=self.font, relief='flat', highlightbackground=ACCENT, highlightthickness=1)
        self.q_text.pack(fill='x', pady=2)

        tk.Label(self.scroll_frame, text="Choices & Explanations:", bg=BG, fg=FG, font=self.font).pack(anchor='w', pady=(10, 0))
        self.choices_container = tk.Frame(self.scroll_frame, bg=BG)
        self.choices_container.pack(fill='x', pady=2)

        btn_frame = tk.Frame(self, bg=BG)
        btn_frame.pack(fill='x', padx=20, pady=10)

        if self.edit_idx is None:
            tk.Button(btn_frame, text="+ Add Choice", command=self.add_choice_row, bg=SELECT_BG, fg=ACCENT, font=self.font, relief='flat', activebackground=BG, activeforeground=ACCENT).pack(side='left', padx=5)
            tk.Button(btn_frame, text="Save & New", command=lambda: self.save_question(clear=True), bg=SELECT_BG, fg=CORRECT, font=self.font, relief='flat', activebackground=BG, activeforeground=CORRECT).pack(side='right', padx=5)
            tk.Button(btn_frame, text="Save & Close", command=lambda: self.save_question(clear=False), bg=SELECT_BG, fg=FG, font=self.font, relief='flat', activebackground=BG, activeforeground=FG).pack(side='right', padx=5)
            # Initial 4 choices
            for _ in range(4):
                self.add_choice_row()
        else:
            tk.Button(btn_frame, text="+ Add Choice", command=self.add_choice_row, bg=SELECT_BG, fg=ACCENT, font=self.font, relief='flat', activebackground=BG, activeforeground=ACCENT).pack(side='left', padx=5)
            tk.Button(btn_frame, text="Update Question", command=lambda: self.save_question(clear=False), bg=SELECT_BG, fg=CORRECT, font=self.font, relief='flat', activebackground=BG, activeforeground=CORRECT).pack(side='right', padx=5)

        tk.Label(self, text="Check the green box for the correct answer(s).", bg=BG, fg=DIM, font=self.font).pack(side='bottom', pady=5)

    def add_choice_row(self):
        row = tk.Frame(self.choices_container, bg=BG)
        row.pack(fill='x', pady=2)

        correct_var = tk.BooleanVar(value=False)
        chk = tk.Checkbutton(row, variable=correct_var, bg=BG, activebackground=BG, selectcolor=ENTRY_BG, highlightthickness=0)
        chk.pack(side='left')

        entry_c = tk.Entry(row, bg=ENTRY_BG, fg=FG, insertbackground=FG, font=self.font, relief='flat', highlightbackground=BORDER, highlightthickness=1)
        entry_c.pack(side='left', fill='x', expand=True, padx=(2, 5))

        entry_e = tk.Entry(row, bg=ENTRY_BG, fg=DIM, insertbackground=FG, font=self.font, relief='flat', highlightbackground=BORDER, highlightthickness=1)
        entry_e.pack(side='left', fill='x', expand=True, padx=(2, 0))

        self.choice_rows.append({
            'frame': row,
            'correct_var': correct_var,
            'entry_c': entry_c,
            'entry_e': entry_e
        })

    def populate_fields(self, q_data):
        self.q_text.insert("1.0", q_data.get("question", ""))

        choices = q_data.get("choices", [])
        answers = q_data.get("answer", [])
        if not isinstance(answers, list): answers = [answers]

        explanations = q_data.get("explanations", [""] * len(choices))
        while len(explanations) < len(choices): explanations.append("")

        # Clear default rows if any
        for row in self.choice_rows:
            row['frame'].destroy()
        self.choice_rows = []

        for c, e in zip(choices, explanations):
            self.add_choice_row()
            row = self.choice_rows[-1]
            row['entry_c'].insert(0, c)
            row['entry_e'].insert(0, e)
            if c in answers:
                row['correct_var'].set(True)

    def save_question(self, clear=True):
        q_text = self.q_text.get("1.0", "end-1c").strip()
        if not q_text:
            messagebox.showerror("Error", "Question text cannot be empty.", parent=self)
            return

        choices = []
        explanations = []
        answers = []

        for row in self.choice_rows:
            c_text = row['entry_c'].get().strip()
            e_text = row['entry_e'].get().strip()
            is_correct = row['correct_var'].get()

            if c_text:
                choices.append(c_text)
                explanations.append(e_text)
                if is_correct:
                    answers.append(c_text)

        if len(choices) < 2:
            messagebox.showerror("Error", "Need at least 2 choices.", parent=self)
            return
        if len(answers) == 0:
            messagebox.showerror("Error", "Must select at least one correct answer.", parent=self)
            return

        data = {
            "question": q_text,
            "choices": choices,
            "answer": answers if len(answers) > 1 else answers[0],
            "explanations": explanations
        }

        if self.edit_idx is not None:
            self.app.save_edited_question(self.edit_idx, data)
            self.destroy()
        else:
            file_path = filedialog.asksaveasfilename(
                title="Save TOML File",
                defaultextension=".toml",
                filetypes=[("TOML files", "*.toml")],
                parent=self
            )
            if not file_path:
                return

            toml_str = "\n[[questions]]\n"
            toml_str += f'question = "{data["question"]}"\n'
            toml_str += 'choices = [' + ', '.join([f'"{c}"' for c in choices]) + ']\n'
            toml_str += 'answer = [' + ', '.join([f'"{a}"' for a in answers]) + ']\n' if len(answers) > 1 else f'answer = "{answers[0]}"\n'
            toml_str += 'explanations = [' + ', '.join([f'"{e}"' for e in explanations]) + ']\n\n'

            try:
                with open(file_path, 'a', encoding='utf-8') as f:
                    f.write(toml_str)
                messagebox.showinfo("Success", "Question saved successfully!", parent=self)
                self.app.add_to_recent(file_path)

                if clear:
                    self.q_text.delete("1.0", "end")
                    while len(self.choice_rows) > 4:
                        row = self.choice_rows.pop()
                        row['frame'].destroy()
                    for row in self.choice_rows:
                        row['entry_c'].delete(0, 'end')
                        row['entry_e'].delete(0, 'end')
                        row['correct_var'].set(False)
                else:
                    self.destroy()
            except Exception as e:
                messagebox.showerror("Error", f"Failed to save file:\n{e}", parent=self)


# ===== Main Study App =====
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
        self.current_file = ""
        self.current_file_path = ""

        # Timer state
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

    # ===== UI setup =====
    def setup_ui(self):
        self.header = tk.Label(
            self.root, text="", bg=BG, fg=ACCENT,
            font=self.font, anchor='w', justify='left'
        )
        self.header.pack(fill='x', padx=20, pady=(15, 2))

        self.text_frame = tk.Frame(self.root, bg=BG)
        self.text_frame.pack(fill='both', expand=True, padx=20, pady=(2, 15))

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

        for i in range(30):
            tag = f'choice_{i}'
            self.text.tag_configure(tag)
            self.text.tag_bind(tag, '<Button-1>', lambda e, idx=i: self.on_choice_click(idx))
            self.text.tag_bind(tag, '<Enter>', lambda e, idx=i: self.on_choice_hover(idx, True))
            self.text.tag_bind(tag, '<Leave>', lambda e, idx=i: self.on_choice_hover(idx, False))

        for i in range(5):
            tag = f'recent_{i}'
            self.text.tag_bind(tag, '<Button-1>', lambda e, idx=i: self.open_recent(idx))
            self.text.tag_bind(tag, '<Enter>', lambda e, t=tag: self.text.tag_config(t, foreground=ACCENT))
            self.text.tag_bind(tag, '<Leave>', lambda e, t=tag: self.text.tag_config(t, foreground=FG))

        self.text.tag_bind('button_tag', '<Button-1>', lambda e: self.browse_file())
        self.text.tag_bind('button_tag', '<Enter>', lambda e: self.text.tag_config('button_tag', foreground=FG))
        self.text.tag_bind('button_tag', '<Leave>', lambda e: self.text.tag_config('button_tag', foreground=ACCENT))

        # Editor Button Tag
        self.text.tag_bind('btn_editor', '<Button-1>', lambda e: self.open_editor())
        self.text.tag_bind('btn_editor', '<Enter>', lambda e: self.text.tag_config('btn_editor', foreground=FG))
        self.text.tag_bind('btn_editor', '<Leave>', lambda e: self.text.tag_config('btn_editor', foreground=ACCENT))

        # Action buttons (Submit, Prev, Next, Edit)
        for tag in ('btn_submit', 'btn_prev', 'btn_next', 'btn_stats', 'btn_edit'):
            self.text.tag_configure(tag, foreground=ACCENT)
            self.text.tag_bind(tag, '<Button-1>', lambda e, t=tag: self.on_button_click(t))
            self.text.tag_bind(tag, '<Enter>', lambda e, t=tag: self.text.tag_config(t, foreground=FG))
            self.text.tag_bind(tag, '<Leave>', lambda e, t=tag: self.text.tag_config(t, foreground=ACCENT))

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

        self.root.bind("<Left>",    lambda e: self.prev_question())
        self.root.bind("<Right>",   lambda e: self.on_key('right'))
        self.root.bind("h",         lambda e: self.prev_question())
        self.root.bind("l",         lambda e: self.on_key('right'))

        self.root.bind("o",         lambda e: self.browse_file())
        self.root.bind("O",         lambda e: self.browse_file())
        self.root.bind("e",         lambda e: self.open_editor(edit_current=True) if self.state == "QUESTION" else self.open_editor())
        self.root.bind("E",         lambda e: self.open_editor(edit_current=True) if self.state == "QUESTION" else self.open_editor())

        self.root.bind("+",         lambda e: self.change_font(1))
        self.root.bind("=",         lambda e: self.change_font(1))
        self.root.bind("<KP_Add>",  lambda e: self.change_font(1))
        self.root.bind("-",         lambda e: self.change_font(-1))
        self.root.bind("<KP_Subtract>", lambda e: self.change_font(-1))

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
            self.update_ui_width()

    def quit_app(self):
        if self.timer_id:
            self.root.after_cancel(self.timer_id)
        self.root.destroy()

    def open_editor(self, edit_current=False):
        edit_idx = None
        if edit_current and self.state == "QUESTION" and self.current:
            edit_idx = self.current['orig_idx']
        EditorWindow(self.root, self, edit_idx=edit_idx)

    def save_edited_question(self, orig_idx, data):
        # 1. Update the master list
        self.questions[orig_idx] = data

        # 2. Save to file
        if self.current_file_path:
            try:
                toml_str = serialize_toml(self.questions)
                with open(self.current_file_path, 'w', encoding='utf-8') as f:
                    f.write(toml_str)
            except Exception as e:
                messagebox.showerror("Error", f"Could not save changes to file:\n{e}")
                return

        # 3. Update current question in session
        if self.current and self.current['orig_idx'] == orig_idx:
            new_q = self.prepare_question(data, orig_idx)
            new_q['answered'] = False
            new_q['user_selected'] = set()

            self.history[self.history_idx] = new_q
            self.current = new_q
            self.cursor = 0
            self.selected = set()
            self.render_question()

        # 4. Remove any re-queued versions of this question from the queue
        self.queue = [q for q in self.queue if q['orig_idx'] != orig_idx]

        messagebox.showinfo("Success", "Question updated and saved to file.")

    # ===== Timer Logic =====
    def start_timer(self):
        self.session_start_time = time.time()
        self.q_start_time = time.time()
        self.update_timer()

    def update_timer(self):
        if self.state in ("QUESTION", "REVIEW"):
            elapsed = time.time() - self.session_start_time
            time_str = format_time(elapsed)
            q_elapsed = time.time() - self.q_start_time
            q_str = format_time(q_elapsed)

            self.header.config(text=f" STUDY SESSION │ Time: {time_str} │ Q-Time: {q_str} ")
            self.timer_id = self.root.after(1000, self.update_timer)

    def stop_timer(self):
        if self.timer_id:
            self.root.after_cancel(self.timer_id)
            self.timer_id = None
        self.total_time = time.time() - self.session_start_time
        self.header.config(text=" STUDY SESSION ")

    # ===== Text helpers =====
    def clear_text(self):
        self.text.configure(state='normal')
        self.text.delete('1.0', 'end')

    def add(self, s, tag=None):
        if tag:
            self.text.insert('end', s, tag)
        else:
            self.text.insert('end', s)

    def add_button(self, text, tag):
        self.text.insert('end', text, tag)

    def finalize(self):
        self.text.configure(state='disabled')
        self.text.see("1.0")

    def render_current(self):
        if self.state == "IDLE": self.show_idle()
        elif self.state == "QUESTION": self.render_question()
        elif self.state == "DONE": self.show_done()

    # ===== State: IDLE =====
    def show_idle(self):
        self.state = "IDLE"
        self.stop_timer()
        self.header.config(text=" STUDY SESSION ")

        self.clear_text()
        width = self.ui_width
        self.add("┌" + "─" * (width - 2) + "┐\n", 'border')
        self.add("│" + " STUDY SESSION ".center(width - 2) + "│\n", 'accent')
        self.add("│" + " " * (width - 2) + "│\n", 'border')
        self.add("│" + " Welcome. Load a TOML file to begin. ".center(width - 2) + "│\n", 'dim')
        self.add("│" + " " * (width - 2) + "│\n", 'border')

        btn_text = " [ Open TOML File ] "
        self.add("│" + btn_text.center(width - 2) + "│\n", 'button_tag')

        ed_text = " [ Open Question Editor ] "
        self.add("│" + ed_text.center(width - 2) + "│\n", 'btn_editor')

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

        self.add("│" + " [o] Open  [e] Editor  [+/-] Font  [1-5] Recent  [q] Quit ".center(width - 2) + "│\n", 'dim')
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
        self.current_file_path = path

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

        self.history = []
        self.history_idx = -1

        self.start_timer()
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
            'answered':        False,
            'user_selected':   set(),
            'last_was_correct':False
        }

    # ===== Navigation Logic =====
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
        self.q_start_time = time.time() # Reset per-question timer
        self.render_question()

    def prev_question(self):
        if self.history_idx > 0:
            self.history_idx -= 1
            self.current = self.history[self.history_idx]
            self.cursor = 0
            self.selected = set(self.current.get('user_selected', []))
            self.state = "QUESTION"
            self.render_question()

    def on_button_click(self, tag):
        if tag == 'btn_submit': self.submit_answer()
        elif tag == 'btn_next': self.next_question()
        elif tag == 'btn_prev': self.prev_question()
        elif tag == 'btn_stats': self.show_done()
        elif tag == 'btn_edit': self.open_editor(edit_current=True)

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
            if q['last_was_correct']:
                self.add(" ✓ CORRECT\n\n", 'correct')
            else:
                self.add(" ✗ WRONG — reviewed\n\n", 'wrong')
        else:
            if q['is_multiple']:
                self.add(" ◆ Multiple answers — Space to select, Enter to submit\n\n", 'accent')
            else:
                self.add(" ◇ Single answer — Enter to submit selection\n\n", 'accent')

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
                if is_correct_choice and user_picked:
                    line_tag = 'hl_correct'
                elif is_correct_choice and not user_picked:
                    line_tag = 'hl_missed'
                elif not is_correct_choice and user_picked:
                    line_tag = 'hl_wrong'
                else:
                    line_tag = 'dim'
            else:
                mark = ""
                line_tag = None
                tags = [f'choice_{i}']
                if is_cursor:
                    tags.append('cursor_bg')

            avail = max(10, width - len(prefix) - len(mark))
            choice_lines = wrap_text(choice, avail) or [""]
            for j, cl in enumerate(choice_lines):
                line = (prefix + cl + mark) if j == 0 else (" " * len(prefix) + cl)
                line = line.ljust(width)
                if is_answered:
                    self.add(line + "\n", line_tag)
                else:
                    self.text.insert('end', line + "\n", tuple(tags))

            if is_answered:
                expl = q['explanations'][i]
                if expl:
                    for el in wrap_text(expl, width - 8):
                        color = 'correct' if is_correct_choice else 'dim'
                        self.add("       " + el + "\n", color)

        self.add("\n")

        # Action Buttons Row
        btns = []
        if self.history_idx > 0:
            btns.append(("[ < Prev ]", 'btn_prev'))

        if not is_answered and is_last:
            btns.append(("[ Submit ]", 'btn_submit'))
        else:
            if is_last and not self.queue:
                btns.append(("[ Stats ]", 'btn_stats'))
            else:
                btns.append(("[ Next > ]", 'btn_next'))

        btns.append(("[ Edit Q ]", 'btn_edit'))

        btn_text = "   ".join([b[0] for b in btns])
        pad = max(0, (width - len(btn_text)) // 2)
        self.add(" " * pad)
        for text, tag in btns:
            self.add_button(text, tag)
            self.add("   ")
        self.add("\n\n")

        self.add(" [↑↓/jk] Navigate   [←/→] History   [Space] Select   [Enter] Submit/Next   [e] Edit   [+/-] Font   [q] Quit\n", 'dim')

        self.finalize()

    def on_choice_click(self, idx):
        if self.state != "QUESTION": return
        if self.current.get('answered', False): return
        if self.history_idx != len(self.history) - 1: return

        if idx < 0 or idx >= len(self.current['choices']): return
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
                if is_answered or not is_last:
                    self.next_question()
            elif key == 'space' and not is_answered:
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
                if self.questions: self.restart_session()
                else: self.show_idle()

    # ===== State: SUBMIT / REVIEW =====
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
            requeued = self.prepare_question(
                self.questions[q['orig_idx']],
                q['orig_idx']
            )
            if requeued:
                if not self.queue:
                    self.queue.append(requeued)
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
        self.history = []
        self.history_idx = -1

        self.start_timer()
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
