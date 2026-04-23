# fzf keybind
zmodload zsh/terminfo
export KEYTIMEOUT=1

# --- History Navigation ---
# Standard Up/Down arrows
bindkey "${terminfo[kcuu1]}" history-search-backward
bindkey "${terminfo[kcud1]}" history-search-forward

# --- Word Movement ---
# Ctrl + Left / Right
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# --- Tab & Suggestions ---
# Tab: Standard completion (handled by Zsh/Zinit completions)
bindkey '^I' expand-or-complete 

# Escape: Accept the current autosuggestion
# Note: This requires zsh-autosuggestions to be loaded via zinit first
bindkey '\e' autosuggest-accept

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^w' edit-command-line

bindkey '^z' undo

bindkey ' ' magic-space

# --- Custom Selection Widgets ---

# Shift + Left
backward-char-select() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle backward-char
}

# Shift + Right
forward-char-select() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle forward-char
}

# Ctrl + Shift + Left
backward-word-select() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle backward-word
}

# Ctrl + Shift + Right
forward-word-select() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle forward-word
}

# Register all of them
zle -N backward-char-select
zle -N forward-char-select
zle -N backward-word-select
zle -N forward-word-select

# Shift + Arrows
bindkey '^[[1;2D' backward-char-select
bindkey '^[[1;2C' forward-char-select

# Ctrl + Shift + Arrows
bindkey '^[[1;6D' backward-word-select
bindkey '^[[1;6C' forward-word-select



# Create the Select All widget
select-all() {
    # Move to the end of the line
    zle end-of-line
    # Set the 'mark' (the start of a selection)
    zle set-mark-command
    # Move to the beginning of the line
    zle beginning-of-line
}

# Register it as a widget
zle -N select-all

# Bind it to Ctrl+A
bindkey '^A' select-all

# This function checks if a selection is active. 
# If yes, it deletes the selection. If no, it deletes one char.
backward-delete-char-or-selection() {
    if (( REGION_ACTIVE )); then
        zle kill-region
    else
        zle backward-delete-char
    fi
}

# Register and bind it to Backspace (^?)
zle -N backward-delete-char-or-selection
bindkey '^?' backward-delete-char-or-selection

# Do the same for the Delete key
delete-char-or-selection() {
    if (( REGION_ACTIVE )); then
        zle kill-region
    else
        zle delete-char
    fi
}

zle -N delete-char-or-selection
bindkey "^[[3~" delete-char-or-selection # Standard Delete key code

bindkey -s '^f' 'fzf\n'

# --- Modern Ctrl + Backspace ---
modern-backward-kill-word() {
  if (( REGION_ACTIVE )); then
    zle kill-region
  else
    zle backward-kill-word
  fi
}

zle -N modern-backward-kill-word

# The keycode for Ctrl+Backspace can vary:
# '^H' is common for Alacritty/Kitty
# '^?' is sometimes used, but that's usually just Backspace
bindkey '^H' modern-backward-kill-word

clear-keep-buffer() {
    zle clear-screen
}
zle -N clear-keep-buffer
bindkey '^X' clear-keep-buffer
