#!/usr/bin/env bash

# Format: "package_name|Clean Title|Description"
PACMAN_DEPS=(
    "hyprland|Hyprland|The core Wayland compositor and window manager."
    "quickshell|Quickshell|The flexible desktop shell framework driving this UI repo."
    "fastfetch|Fastfetch|System information fetching tool for the dashboard."
    "qt6-multimedia|Qt6 Multimedia|Qt module for audio and video playback features."
    "qt6-5compat|Qt6 5Compat|Compatibility layer for graphical blur and mask effects."
    "qt6-declarative|Qt6 Declarative|Engine for handling QML UIs and layouts."
    "wireplumber|WirePlumber|Session manager for PipeWire handling audio streams."
    "pipewire-pulse|PipeWire Pulse|Provides utilities for controlling audio streams."
    "upower|UPower|System daemon providing power and battery tracking statistics."
    "bluez|Bluez|The official Linux Bluetooth protocol stack daemon."
    "bluez-utils|Bluez Utilities|Development and interface tools for managing Bluetooth."
    "networkmanager|NetworkManager|Network connection management daemon and tools."
    "cava|CAVA|Console-based Audio Visualizer for the desktop backdrop."
    "wl-clipboard|WL Clipboard|Command-line copy/paste utilities for Wayland."
    "clipvault|Clipvault|Mananging clipboard history."
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

check_list() {
    local type="$1"
    shift
    local list=("$@")

    for item in "${list[@]}"; do
        # Split the string using internal field separator '|'
        IFS="|" read -r pkg title desc <<< "$item"

        # Stream out everything packed into a single colon-separated line
        # Format: ACTION:TYPE:PKG:TITLE:DESCRIPTION
        echo "START:$type:$pkg:$title:$desc"
        fflush /dev/stdout 2>/dev/null

        sleep 0.009

        if pacman -Qi "$pkg" &> /dev/null; then
            echo "OK:$type:$pkg:$title:$desc"
        else
            echo "MISSING:$type:$pkg:$title:$desc"
        fi

        sleep 0.009

        fflush /dev/stdout 2>/dev/null
    done
}

check_list "pacman" "${PACMAN_DEPS[@]}"
check_list "aur" "${AUR_DEPS[@]}"
echo "TERMINATE"
