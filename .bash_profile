#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi


## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[ -f /home/tsubenn/.dart-cli-completion/bash-config.bash ] && . /home/tsubenn/.dart-cli-completion/bash-config.bash || true
## [/Completion]

