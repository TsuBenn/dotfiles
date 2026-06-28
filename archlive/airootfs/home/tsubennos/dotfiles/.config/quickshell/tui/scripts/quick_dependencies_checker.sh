#!/usr/bin/env bash

PACMAN_DEPS=(
    "hyprland|Hyprland|The core Wayland compositor and window manager."
    "quickshell|Quickshell|The flexible desktop shell framework driving this UI repo."
    "fastfetch|Fastfetch|System information fetching tool for the dashboard."
    "qt6-multimedia|Qt6 Multimedia|Qt module for audio and video playback features."
    "qt6-5compat|Qt6 5Compat|Compatibility layer for graphical blur and mask effects."
    "qt6-declarative|Qt6 Declarative|Engine for handling QML UIs and layouts."
    "wireplumber|WirePlumber|Session manager for PipeWire handling audio streams."
    "upower|UPower|System daemon providing power and battery tracking statistics."
    "bluez|Bluez|The official Linux Bluetooth protocol stack daemon."
    "bluez-utils|Bluez Utilities|Development and interface tools for managing Bluetooth."
    "networkmanager|NetworkManager|Network connection management daemon and tools."
    "cava|CAVA|Console-based Audio Visualizer for the desktop backdrop."
    "wl-clipboard|WL Clipboard|Command-line copy/paste utilities for Wayland."
    "wtype|WType|Wayland keystroke simulator tool used for typing emojis."
    "grim|Grim|Grab images from a Wayland compositor to take screenshots."
    "dolphin|Dolphin|The desktop graphical file manager application."
    "python|Python|Interpreter required to run optimized helper scripts."
    "ffmpeg|FFmpeg|Audio and video streaming, recording, and processing tool."
    "imagemagick|ImageMagick|Command-line software suite for creating and editing images."
    "fd|FD|A simple, fast, and user-friendly alternative to find."
    "noto-fonts-extra|Noto Fonts Extra|Extended decorative font support packages."
    "noto-fonts-emoji|Noto Fonts Emoji|Google Noto color emoji font package."
    "noto-fonts-cjk|Noto Fonts CJK|Google Noto fonts supporting Chinese, Japanese, and Korean."
    "ttf-jetbrains-mono|JetBrains Mono|High-legibility monospaced font tailored for developers."
    "ttf-jetbrains-mono-nerd|JetBrains Mono Nerd|Monospaced font patched with developer iconography glyphs."
)

AUR_DEPS=(
    "ttf-apple-emoji|Apple Color Emoji|Apple style color emojis for layout elements."
)

# 1. Declare an in-memory Hash Map / Associative Array
declare -A INSTALLED_MAP

# 2. Populate the hash map instantly from pacman's output list
while read -r pkg; do
    [[ -n "$pkg" ]] && INSTALLED_MAP["$pkg"]=1
done < <(pacman -Qq)

check_list() {
    local type="$1"
    shift
    local list=("$@")

    for item in "${list[@]}"; do
        IFS="|" read -r pkg title desc <<< "$item"

        # 3. $O(1)$ Hash lookup: Instant check that ignores whitespace completely
        if [[ -z "${INSTALLED_MAP[$pkg]}" ]]; then
            echo "MISSING:$type:$pkg:$title:$desc"
        fi
    done
}

check_list "pacman" "${PACMAN_DEPS[@]}"
check_list "aur" "${AUR_DEPS[@]}"

echo "TERMINATE"
