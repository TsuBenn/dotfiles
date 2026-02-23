#!/bin/bash

# ===== Color Definitions =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================="
echo -e "      Arch Linux Post-Install Script   "
echo -e "=======================================${NC}"

sudo pacman -Syu --noconfirm

# ===== Kernel Selection =====
echo -e "${YELLOW}\nSelect Linux Kernel to install:${NC}"
echo -e "${CYAN}1) linux (default)"
echo -e "2) linux-zen (optimized for desktop/gaming)"
echo -e "3) linux-lts (long-term support)${NC}"
read -p "Enter choice (1/2/3): " kernel_choice

case $kernel_choice in
    1|"")
        KERNEL="linux"
        HEADERS="linux-headers"
        ;;
    2)
        KERNEL="linux-zen"
        HEADERS="linux-zen-headers linux-headers"
        ;;
    3)
        KERNEL="linux-lts"
        HEADERS="linux-lts-headers linux-headers"
        ;;
    *)
        echo -e "${RED}Invalid choice, installing Normal Linux.${NC}"
        KERNEL="linux"
        HEADERS="linux linux-headers"
        ;;
esac

echo -e "${GREEN}✔ Installing selected kernel: $KERNEL${NC}"

sudo pacman -S --noconfirm --needed "$KERNEL" "$HEADERS"

echo -e "${YELLOW}\nAre you using an NVIDIA GPU? (y/n): ${NC}"
read -p "" use_nvidia

if [[ $use_nvidia == "y" || $use_nvidia == "Y" ]]; then
    echo -e "${CYAN}Installing NVIDIA drivers...${NC}"

    if [[ "$KERNEL" == "linux-zen" || "$KERNEL" == "linux-lts" ]]; then
        sudo pacman -S --noconfirm --needed nvidia-dkms nvidia-utils lib32-nvidia-utils
        echo -e "${GREEN}✔ Installed nvidia-dkms for $KERNEL${NC}"
    else
        sudo pacman -S --noconfirm --needed nvidia nvidia-utils lib32-nvidia-utils
        echo -e "${GREEN}✔ Installed standard NVIDIA driver for linux${NC}"
    fi

    echo -e "${YELLOW}Remember to run: sudo mkinitcpio -P${NC}"
fi

# ===== Package Arrays =====

BASE_PKGS=(
    base amd-ucode linux-firmware sudo git base-devel grub timeshift
    networkmanager reflector man openssh keyd
)

BLUETOOTH=(
    bluez bluez-utils bluez-deprecated-tools
)

DEV_PKGS=(
    npm nodejs python unzip clang clang-tools-extra rustup go fzf fd
    lazygit tree-sitter-cli meson cmake make unixodbc
)

TERMINALS=(kitty)

HYPR_PKGS=(
    hyprland qt6-wayland xdg-desktop-portal-hyprland hyprshot archlinux-xdg-menu
)

FONTS=(
    noto-fonts noto-fonts-cjk noto-fonts-extra noto-fonts-emoji
)

AUDIO_PKGS=(
    wireplumber pipewire pipewire-alsa pipewire-jack pipewire-pulse pavucontrol easyeffects lsp-plugins
)

NVIDIA_PKGS=(
    nvidia-utils lib32-nvidia-utils libva-nvidia-driver egl-wayland
)

GAMING_PKGS=(
    steam
    mesa lib32-mesa 
    vulkan-radeon lib32-vulkan-radeon 
    gamemode lib32-gamemode 
    gamescope
    mangohud goverlay
    wine 
    winetricks 
    python-kivy 
    lib32-vulkan-icd-loader vulkan-driver 
)


ESSENTIAL_APPS=(
    discord obs-studio 7zip zoxide filelight ark mpv yazi dolphin libreoffice
    vlc vlc-plugin-x264 vlc-plugin-ffmpeg lame libmad pinta openrgb github-cli libva-utils
    flatpak avahi
    rofi rofi-emoji wtype
    fastfetch
    cloc
)

MONITORING=(btop nvtop)

INPUT_METHOD=(
    fcitx5 fcitx5-im fcitx5-configtool fcitx5-unikey fcitx5-mozc wl-clipboard
)

RICING=(
    quickshell swww ttf-jetbrains-mono-nerd cava
    qt6-base qt6-declarative qt6-svg qt6-wayland
)

# ===== AUR Packages =====
AUR_PACKAGES=(
    nvidia-vaapi-driver
    localsend
    spotify
    ds4drv
    proton-ge-custom-bin
    protonplus
    cbonsai
    alac
    wavpack
    portproton
    clipvault
    qalculate-qt
    uxplay
    adb
    lsfg-vk
    qimgv
    zen-browser-bin
    kdenlive
)

# ===== Flatpak Apps =====
FLATPAK_APPS=(
)

# ===== Install Function =====
install_packages() {
    echo -e "\n${YELLOW}==> Installing: $1 ${NC}"
    shift
    for PKG in "$@"; do
        echo -e "${CYAN}→ Installing ${PKG}...${NC}"
        sudo pacman -S --noconfirm --needed "$PKG"
    done
    echo -e "${GREEN}✔ Completed installing: $1${NC}"
}

# ===== Pacman Package Install =====
install_packages "Base System" "${BASE_PKGS[@]}"
install_packages "Bluetooh" "${BLUETOOTH[@]}"
install_packages "Development Tools" "${DEV_PKGS[@]}"
install_packages "Gaming Packages" "${GAMING_PKGS[@]}"
install_packages "Terminals" "${TERMINALS[@]}"
install_packages "Hyprland & Portal" "${HYPR_PKGS[@]}"
install_packages "Fonts" "${FONTS[@]}"
install_packages "Audio Tools" "${AUDIO_PKGS[@]}"
install_packages "NVIDIA Drivers (if needed)" "${NVIDIA_PKGS[@]}"
install_packages "Essential Apps" "${ESSENTIAL_APPS[@]}"
install_packages "Monitoring Tools" "${MONITORING[@]}"
install_packages "Input & Language" "${INPUT_METHOD[@]}"
install_packages "Ricing & Aesthetics" "${RICING[@]}"

# ===== Install Yay (AUR Helper) =====
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}Installing yay AUR helper...${NC}"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo -e "${GREEN}✔ yay already installed.${NC}"
fi

# ===== Install AUR Packages =====
echo -e "${BLUE}Installing AUR packages...${NC}"
for PKG in "${AUR_PACKAGES[@]}"; do
    echo -e "${CYAN}→ Installing (AUR) $PKG...${NC}"
    yay -S --noconfirm --needed "$PKG"
done
echo -e "${GREEN}✔ AUR packages installed!${NC}"

# ===== Install Flatpak Apps =====
echo -e "${BLUE}Installing Flatpak apps...${NC}"
for PKG in "${FLATPAK_APPS[@]}"; do
    echo -e "${CYAN}→ Installing (Flatpak) $PKG...${NC}"
    flatpak install "$PKG"
done
echo -e "${GREEN}✔ Flatpak packages installed!${NC}"


# ===== Enable Spotify Ad-Blocker =====
echo -e "${BLUE}Installing Spotify ad-blocker...${NC}"
git clone https://github.com/abba23/spotify-adblock.git
cd spotify-adblock
make
echo -e "${GREEN}✔ Ad-blocked Spotify successfully!${NC}"

# ===== Enable Services =====
echo -e "${BLUE}Enabling system services...${NC}"
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now keyd
sudo systemctl enable --now sshd
systemctl enable --now avahi-daemon
systemctl enable --now pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true
echo -e "${GREEN}✔ Services enabled${NC}"

# ===== Git Configuration =====
echo -e "${YELLOW}Configuring Git...${NC}"
read -p "Enter your Git username: " git_user
read -p "Enter your Git email: " git_email
git config --global user.name "$git_user"
git config --global user.email "$git_email"
echo -e "${GREEN}✔ Git configured successfully!${NC}\n"

# ===== Set Keyd config =====
sudo mkdir -p /etc/keyd
sudo tee /etc/keyd/default.conf > /dev/null << 'EOF'
[ids]

*

[main]

capslock = esc

esc = `
EOF
echo "Keyd config created at /etc/keyd/default.conf"
sudo keyd reload


# ===== System Update =====
echo -e ""
echo -e "${BLUE}Updating system...${NC}"

# ===== Manual Reminders =====
echo -e "${YELLOW}\nRemember to manually configure:${NC}"
echo -e "${CYAN}• Locale generation: sudo locale-gen"
echo -e "• Nvidia Initramfs: sudo mkinitcpio -P"
echo -e "• GRUB Update: sudo grub-mkconfig -o /boot/grub/grub.cfg"
echo -e "• Set keyd config in /etc/keyd/default.conf${NC}"

echo -e "${GREEN}\n🎉 Setup Complete! Reboot recommended.${NC}"
