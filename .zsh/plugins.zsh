# Set dir for zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit if it doesn't exists yet
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Initiate zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#585858'

# Autoload
autoload -U compinit && compinit

zinit cdreplay -q

# Completion style
zstyle ':completion.*' matcher-list  'm:{a-z}={A-Za-z}'
zstyle ':completion.*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion.*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

eval "$(fzf --zsh)"
