zmodload zsh/terminfo

# ESSENTIAL
alias vim='nvim'

clear() {
    print -rn $terminfo[clear]
}

alias ls='ls --color=auto'
alias list='ls -Alh --color=auto'
alias grep='grep --color=auto'
alias fetch='clear && fastfetch'
alias cls='clear'
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ....='cd ../..'
alias ......='cd ../../..'
alias shutdown='shutdown -h now'

# QUICK ACCESS
alias setup='cd ~/dotfiles/ && bash ./arch_autosetup.sh'
alias setupEdit='cd ~/dotfiles/ && nvim ./arch_autosetup.sh'

ayano() {

    cd ~/ayano || return

    # 1. Handle venv creation and activation properly
    if [ ! -d "venv" ]; then
        echo "No venv found! Creating venv..."
        python -m venv venv
        source venv/bin/activate
        echo "Installing required Python Library..."
        pip install ollama requests websockets  # Added websockets since we need it!
    else
        source venv/bin/activate
    fi

    # 2. Arch packages and systemd services should NOT live inside a daily-use function
    if ! command -v ollama &> /dev/null; then
        echo "Ollama not found. Please install ollama-cuda manually via pacman."
    fi

    # 3. Use standard Zsh aliases instead of nesting functions globally
    alias project='tree -I "venv|logs|audio|__pycache__|__init__.py|.pyc|.git|*.png"'
    alias run='pkill -f main.py; clear; python main.py &; clear'

}

alias dot='cd ~/dotfiles/ && nvim .'
alias hyprconf='cd ~/dotfiles/ && nvim ~/.config/hypr/hyprland.lua'
alias kittyconf='cd ~/dotfiles/ && nvim ~/.config/kitty/kitty.conf'
alias ghosttyconf='cd ~/dotfiles/ && nvim ~/.config/ghostty/config'
alias tmuxconf='cd ~/dotfiles/ && nvim ~/.tmux.conf'
alias nvimconf='cd ~/.config/nvim && nvim ~/.config/nvim/'
alias bashconf='cd ~/dotfiles/ && nvim ~/.bashrc'
alias zshconf='cd ~/dotfiles/.zsh/ && nvim ~/dotfiles/.zsh/'

qsconf() {
    cd ~/dotfiles/.config/quickshell/$1
    nvim ~/.config/quickshell/$1
}
qss() {
    qs -c ~/.config/quickshell/$1
}
qsD() {
    qs kill -c $1
    clear
    qs -c ~/.config/quickshell/$1
}
qsR() {
    qs kill -c $1
    qs -c ~/.config/quickshell/$1 -d
}

programs() {
    cd ~/dotfiles/programs/$1
}

alias easyeffectsRestart='easyeffects -q && easyeffects --gapplication-service &'

# QUICK INSTALL
alias wifiDriverInstall='yay -S aic8800d80-dkms'
alias grubUpdate='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias mkdir='mkdir -p'
alias pacmanInstall='echo "sudo pacman -S" && sudo pacman -S'
alias pacmanUpdate='echo "sudo pacman -Sy" && sudo pacman -Sy'
alias pacmanUninstall='echo "sudo pacman -Runs" && sudo pacman -Runs'
alias pacmanClearCache='echo "sudo pacman -Sc" && sudo pacman -Sc'
alias pacmanClearAllCache='echo "sudo pacman -Scc" && sudo pacman -Scc'
alias yayInstall='echo "yay -S" && yay -S'
alias yayClearCache='echo "yay -Sc" && yay -Sc'
alias yayClearAllCache='echo "yay -Scc" && yay -Scc'



# Java ANT
alias antrun="ant run | awk '{gsub(/^ *\[java\] /, \"\"); print}'"
