[[ $- != *i* ]] && return

if [[ $- == *i* ]]; then
    bind '"\C-f":"fzf\n"'
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'

alias vim='nvim'

alias dotfiles='cd ~/dotfiles/ && nvim .'

alias hyprconf='cd ~/dotfiles/ && nvim ~/dotfiles/.config/hypr/hyprland.conf'
alias kittyconf='cd ~/dotfiles/ && nvim ~/dotfiles/.config/kitty/kitty.conf'
alias nvimconf='cd ~/.config/nvim && nvim ~/.config/nvim/'
alias bashconf='cd ~/dotfiles/ && nvim ~/dotfiles/.bashrc'
alias qsconf='cd ~/dotfiles/.config/quickshell/ && nvim ~/dotfiles/.config/quickshell/shell.qml'
alias mkdir='mkdir -p'
alias ls='ls -Alh'
alias easyeffectsRestart='easyeffects -q && easyeffects --gapplication-service &'
alias pacmanInstall='sudo pacman -S'
alias pacmanUninstall='sudo pacman -Runs'
alias fetch='clear && fastfetch'
alias cls='clear'
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ....='cd ../..'
alias ......='cd ../../..'
alias shutdown='shutdown -h now'


PS1='  \[\e[36m\]\u \[\e[37m\](\@): \[\e[37m\]\w \[\e[33m\]$ \[\e[37m\]'

eval "$(zoxide init bash)"

export EDITOR=nvim
export VISUAL=nvim

export MOZ_DISABLE_RDD_SANDBOX=1
export LIBVA_DRIVER_NAME=nvidia
export NVD_BACKEND=direct


export PATH=$PATH:/home/TsuBenn/.spicetify
