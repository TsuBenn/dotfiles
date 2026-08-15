#!/usr/bin/env bash

FILE="$1"
LINE="$2"

[ -z "$LINE" ] && LINE=1

# Get the most recent active tmux session name if TMUX env variable isn't passed from Godot
SESSION=$($TMUX_CMD display-message -p '#S' 2>/dev/null)
if [ -z "$SESSION" ]; then
    SESSION=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | head -n 1)
fi

# If tmux isn't running at all, exit
if [ -z "$SESSION" ]; then
    notify-send "Godot-Helix" "No active tmux session found!"
    exit 1
fi

WINDOW_NAME="godot-helix"
TARGET_WIN="${SESSION}:${WINDOW_NAME}"

# Check if the "godot-helix" window exists in the active session
if tmux list-windows -t "$SESSION" -F "#{window_name}" | grep -q "^${WINDOW_NAME}$"; then
    # Select the window and open file in existing Helix instance
    tmux select-window -t "$TARGET_WIN"
    tmux send-keys -t "$TARGET_WIN" Escape Escape ":o $FILE" Enter ":goto $LINE" Enter
else
    # Create window and run Helix
    tmux new-window -t "$SESSION" -n "$WINDOW_NAME" "helix \"$FILE:$LINE\""
fi
# 2. Focus the Ghostty terminal window in Hyprland
hyprctl dispatch "hl.dsp.focus({window=\"class:.*ghostty.*\"})"
