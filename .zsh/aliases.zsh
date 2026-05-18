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
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    else
        echo "No venv found!"
        echo "Creating venv..."
        python -m venv venv
        echo "Installing required Python Library"
        source venv/bin/activate
        pip install PySide6
        pip install requests
        sudo pacman -S ollama-cuda
        sudo systemctl enable --now ollama.service
        echo "Finished..."
    fi
    print() {
        tree -I "venv|logs|audio|__pycache__|__init__.py|.pyc|.git|*.png"
    }
    run() {
        pkill -f main.py
        python main.py &
        clear
    }
}

ayanoSetup() {
    cd ~/ayano || return
    echo "Setting up Ayano Project"
    echo ""
    echo "Creating venv..."
    python -m venv venv
    echo ""
    echo "Installing required Python Libraries"
    source venv/bin/activate
    echo ""
    pip install PySide6
    pip install requests
    echo ""
    sudo pacman -S ollama-cuda --needed
    sudo systemctl enable --now ollama.service
    echo ""
    echo "Finished..."
    run() {
        pkill -f main.py
        python main.py &
        clear
    }
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
    nvim .
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
