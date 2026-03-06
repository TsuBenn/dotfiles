#!/bin/bash

BG_BASE="#151214"
BG_SURFACE="#191519"
BG_MUTED="#221E21"
TEXT_PRIMARY="#EDE6E8"
TEXT_DISABLED="#7A6F74"
ACCENT_STRONG="#a32435"
ACCENT_SOFT="#f59b75"

tmux set -g status-style "bg=$BG_MUTED,fg=$TEXT_PRIMARY"
tmux set -g status-left "#[fg=$BG_BASE,bg=$ACCENT_STRONG,bold] #S #[fg=$ACCENT_STRONG,bg=$BG_MUTED]"
tmux setw -g window-status-format "#[fg=$BG_MUTED,bg=$BG_SURFACE]#[fg=$TEXT_DISABLED,bg=$BG_SURFACE] #I #W #[fg=$BG_SURFACE,bg=$BG_MUTED]"
tmux setw -g window-status-current-format "#[fg=$BG_MUTED,bg=$ACCENT_SOFT]#[fg=$BG_BASE,bg=$ACCENT_SOFT,bold] #I #W #[fg=$ACCENT_SOFT,bg=$BG_MUTED]"
tmux set -g status-right "#[fg=$TEXT_DISABLED,bg=$BG_MUTED] %d %b  %I:%M %p "
