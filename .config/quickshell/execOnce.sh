#!/bin/bash

echo ""
echo "Executing!"

hyprctl keyword unbind SUPER,ESCAPE
hyprctl keyword bind SUPER,ESCAPE,exec, qs ipc call homepanel toggle
hyprctl keyword layerrule blur on, match:namespace quickshell

echo "Executed!"
