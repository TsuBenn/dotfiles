[[ $- != *i* ]] && return

if [[ $- == *i* ]]; then
    bind '"\C-f":"fzf\n"'
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# ESSENTIAL
alias vim='nvim'
alias ls='ls -Alh'
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
        run() {
            pkill -f main.py
            python main.py &
        }
    else
        echo "No venv found!"
        echo "Creating venv..."
        python -m venv venv
        echo "Installing required Python Library"
        pip install PySide6
        echo "Finished..."
    fi
}

alias dot='cd ~/dotfiles/ && nvim .'
alias hyprconf='cd ~/dotfiles/ && nvim ~/.config/hypr/hyprland.conf'
alias kittyconf='cd ~/dotfiles/ && nvim ~/.config/kitty/kitty.conf'
alias nvimconf='cd ~/.config/nvim && nvim ~/.config/nvim/'
alias bashconf='cd ~/dotfiles/ && nvim ~/.bashrc'
alias qsconf='cd ~/dotfiles/.config/quickshell/ && nvim ~/.config/quickshell/shell.qml'
alias programs='cd ~/dotfiles/programs/ && nvim .'

# QUICK RESET
alias qsRestart='qs kill & qs -d'
alias qsR='qs kill & qs -d'
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


PS1='  \[\e[36m\]\u \[\e[37m\](\@): \[\e[37m\]\w \[\e[33m\]$ \[\e[37m\]'

eval "$(zoxide init bash)"

export EDITOR=nvim
export VISUAL=nvim

export MOZ_DISABLE_RDD_SANDBOX=1
export LIBVA_DRIVER_NAME=nvidia
export NVD_BACKEND=direct

export QML_IMPORT_PATH=/usr/lib/qt6/qml
export QML2_IMPORT_PATH=/usr/lib/qt6/qml

export PATH=$PATH:/usr/lib/qt6/bin
