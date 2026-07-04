# Prompt
PROMPT='
  %F{cyan}%n %F{white}(%@): %F{white}%~ %F{yellow}$ %F{white}'

#History
HISTSIZE=5000
HISTFILE=${HOME}/.zsh_history
SAVEHIST=HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# tmux auto-attach
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach || tmux
fi

# Zoxide
eval "$(zoxide init zsh)"

# Exports
export EDITOR=nvim
export VISUAL=nvim
export MOZ_DISABLE_RDD_SANDBOX=1
export LIBVA_DRIVER_NAME=nvidia
export NVD_BACKEND=direct
export QML_IMPORT_PATH=/usr/lib/qt6/qml
export QML2_IMPORT_PATH=/usr/lib/qt6/qml
export PATH=$PATH:/usr/lib/qt6/bin
export PATH="/home/tsubenn/.local/bin:$PATH"
