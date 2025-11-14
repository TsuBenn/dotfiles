#!/bin/bash

hyprctl keyword layerrule blur, quickshell
hyprctl keyword unbind SUPER,ESCAPE
hyprctl keyword bind SUPER,ESCAPE,exec, qs ipc call homepanel toggle
