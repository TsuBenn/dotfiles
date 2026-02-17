#!/bin/bash

echo ""
echo "Executing!"

echo ""
echo "Dependencies:"
echo "  - cava"
echo "  - fastfetch"
echo "  - wpctl"
echo "  - pactl"
echo "  - github-cli"
echo ""

#hyprctl keyword layerrule blur on, match:namespace quickshell
hyprctl keyword unbind SUPER,ESCAPE
hyprctl keyword bind SUPER,ESCAPE,exec, qs ipc call homepanel toggle
hyprctl keyword gesture 3, down, dispatcher, exec, qs ipc call homepanel toggle

echo "Executed!"
