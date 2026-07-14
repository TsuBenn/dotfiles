
import os
import curses
import sys

def draw_menu(stdscr):
    # 1. Initialization and Terminal Setup
    curses.curs_set(0) # Hide the physical blinking cursor
    stdscr.clear()

    # Track state: current directory and which index is highlighted
    current_dir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
    selected_idx = 0

    while True:
        stdscr.clear()
        height, width = stdscr.getmaxyx()

        # Read the directory files safely
        try:
            entries = [".."] + os.listdir(current_dir)
        except PermissionError:
            entries = ["..", "[Permission Denied]"]

        # 2. Render Loop: Draw the TUI grid line by line
        # Show a header mimicking the netrw top bar
        header = f"🚀 Netrw-Clone | Dir: {current_dir}"
        stdscr.addstr(0, 0, header[:width-1], curses.A_REVERSE)

        for idx, entry in enumerate(entries):
            if idx >= height - 2: # Keep layout inside terminal boundaries
                break

            full_path = os.path.join(current_dir, entry) if entry != ".." else os.path.dirname(current_dir)

            # Stylize directories vs files
            display_text = entry
            if os.path.isdir(full_path) and entry != "..":
                display_text = entry + "/"

            # Highlight the current line matching the selected index
            if idx == selected_idx:
                stdscr.addstr(idx + 2, 2, display_text[:width-3], curses.A_STANDOUT)
            else:
                stdscr.addstr(idx + 2, 2, display_text[:width-3])

        stdscr.refresh()

        # 3. Input Handling (Synchronous blocking read)
        key = stdscr.getch()

        if key == ord('q'): # Quit application
            break
        elif key == ord('j') or key == curses.KEY_DOWN:
            selected_idx = min(selected_idx + 1, len(entries) - 1)
        elif key == ord('k') or key == curses.KEY_UP:
            selected_idx = max(selected_idx - 1, 0)
        elif key == 10 or key == 13: # Enter key pressed
            target = entries[selected_idx]

            if target == "..":
                current_dir = os.path.dirname(current_dir)
                selected_idx = 0
            else:
                next_path = os.path.join(current_dir, target)
                if os.path.isdir(next_path):
                    current_dir = next_path
                    selected_idx = 0
                else:
                    # It's a file! Drop out of curses temporarily and open it in nvim
                    curses.endwin()
                    os.system(f"nvim {next_path}")
                    # Re-init screen after editor closes
                    stdscr = curses.initscr()
                    curses.curs_set(0)

if __name__ == "__main__":
    curses.wrapper(draw_menu)
