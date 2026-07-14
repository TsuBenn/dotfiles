#!/usr/bin/env bash
# File: ~/.config/helix/helix-tui-open.sh
# Make sure to run `chmod +x` on this file!

# 1. Create a secure, unique named pipe (FIFO)
FIFO_PATH=$(mktemp -u /tmp/hx-tui-fifo.XXXXXX)
mkfifo "$FIFO_PATH"

# 2. Launch your TUI tool in the foreground, passing the pipe path to it
# Your program should run normally here.
python3 /home/tsubenn/dotfiles/.config/helix/mininetrw.py "$FIFO_PATH"

# 3. Read the file path your program wrote to the pipe
if [ -p "$FIFO_PATH" ]; then
    CHOSEN_FILE=$(cat "$FIFO_PATH")
    rm "$FIFO_PATH" # Clean up the pipe immediately

    # 4. If a file was selected, echo the Helix command back to stdout
    if [ -n "$CHOSEN_FILE" ]; then
        echo "open $CHOSEN_FILE"
    fi
fi
