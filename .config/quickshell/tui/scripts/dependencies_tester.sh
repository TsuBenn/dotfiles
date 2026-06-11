#!/usr/bin/env bash

PACMAN_DEPS=(
    "hyprland" "fastfetch" "qt6-multimedia" "qt6-5compat" "qt6-declarative"
    "wireplumber" "upower" "bluez" "bluez-utils" "networkmanager" "cava"
    "wl-clipboard" "wtype" "grim" "dolphin" "python" "ffmpeg" "imagemagick"
    "fd" "noto-fonts-extra" "noto-fonts-emoji" "noto-fonts-cjk"
    "ttf-jetbrains-mono" "ttf-jetbrains-mono-nerd"
)

AUR_DEPS=(
    "quickshell" "ttf-apple-emoji"
)

# Function to process a list of packages for a specific repository type
check_list() {
    local type="$1"
    shift
    local list=("$@")

    for pkg in "${list[@]}"; do
        # Stream the start event along with its type
        echo "START:$type:$pkg"
        fflush /dev/stdout 2>/dev/null
        
        sleep 0.08

        if pacman -Qi "$pkg" &> /dev/null; then
            echo "OK:$type:$pkg"
        else
            echo "MISSING:$type:$pkg"
        fi
        fflush /dev/stdout 2>/dev/null
    done
}

# Run the checks for both sets
check_list "pacman" "${PACMAN_DEPS[@]}"
check_list "aur" "${AUR_DEPS[@]}"
