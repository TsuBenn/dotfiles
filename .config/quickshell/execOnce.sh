#!/bin/bash

echo ""
echo "Executing!"

TARGET_PACKAGES=(
    "playerctl"
    "github-cli"
)

echo ""
echo -e "--- Checking Required Dependencies (${#TARGET_PACKAGES[@]} total) ---"
echo ""
for pkg in "${TARGET_PACKAGES[@]}"; do
if pacman -Qi "$pkg" &> /dev/null; then
    echo "[${pkg}] is installed."
else
    echo "[${pkg}] is not installed."
fi
done
echo ""
echo "--- Finished Checking Prerequisite...---"
echo ""


hyprctl keyword layerrule blur, quickshell
hyprctl keyword unbind SUPER,ESCAPE
hyprctl keyword bind SUPER,ESCAPE,exec, qs ipc call homepanel toggle

echo "Executed!"
