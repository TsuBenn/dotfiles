#!/bin/bash

echo "Setting up Hyprland's config"
hyprctl keyword source ~/.config/quickshell/tui/scripts/hyprland.conf
hyprctl keyword general:col.active_border $1
hyprctl keyword general:col.inactive_border $2
echo "Finished setting up Hyprland's config"
