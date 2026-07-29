import curses
import subprocess
import os

def select_file_with_miniex():
    # 1. Save main TUI state and temporarily suspend curses
    curses.def_shell_mode()
    curses.endwin()

    # 2. Spawn miniex and capture standard output
    miniex_path = os.path.expanduser("~/dotfiles/.config/helix/miniex.py")
    result = subprocess.run(
        ["miniex"],
        stdout=subprocess.PIPE,
        text=True
    )

    # 3. Restore main TUI state
    curses.reset_shell_mode()
    curses.curs_set(0)  # Hide cursor again if needed

    # 4. Extract selected path
    chosen_path = result.stdout.strip()
    return chosen_path if chosen_path else None


def main_app(stdscr):
    curses.curs_set(0)

    while True:
        stdscr.erase()
        stdscr.addstr(1, 2, "MAIN TUI APP", curses.A_BOLD)
        stdscr.addstr(3, 2, "Press [o] to open file picker via miniex")
        stdscr.addstr(4, 2, "Press [q] to quit")
        stdscr.refresh()

        key = stdscr.getch()

        if key == ord('o'):
            path = select_file_with_miniex()

            # Show the returned path in our main app
            stdscr.erase()
            if path:
                stdscr.addstr(6, 2, f"Selected: {path}", curses.A_BOLD)
            else:
                stdscr.addstr(6, 2, "No path selected / Cancelled.")
            stdscr.addstr(8, 2, "Press any key to return...")
            stdscr.refresh()
            stdscr.getch()

        elif key == ord('q'):
            break

if __name__ == "__main__":
    curses.wrapper(main_app)
