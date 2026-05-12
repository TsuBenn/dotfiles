#!/bin/bash

echo "Setting up Hyprland's config"

SET_COLOR="hl.config({ 

    general = {

        gaps_in =  { top = 8, left = 3, bottom = 8, right = 3 }, 
        gaps_out = { top = 9, left = 5, bottom = 9, right = 5 }, 

        border_size = 2, 

        col = { 
            active_border = \"${1}\", 
            inactive_border = \"${2}\", 
        } 

    }, 

    decoration = { 
        rounding = 0,
        shadow  = { 
            enabled = false 
        } 
    }, 

    animations = { 
        enabled = ${3} 
    } 

})

hl.curve(\"easeOutQuint\",   { type = \"bezier\", points = {{ 0.23, 1},    { 0.32, 1}} })
hl.curve(\"easeInOutCubic\", { type = \"bezier\", points = {{ 0.65, 0.05}, { 0.36, 1}} })
hl.curve(\"linear\",         { type = \"bezier\", points = {{ 0,    0},    { 1,    1}} })
hl.curve(\"almostLinear\",   { type = \"bezier\", points = {{ 0.5,  0.5},  { 0.75, 1}} })
hl.curve(\"quick\",          { type = \"bezier\", points = {{ 0.15, 0},    { 0.1,  1}} })

hl.animation({ leaf = \"global\",              enabled = 1, speed = 10,   bezier = \"default\"})
hl.animation({ leaf = \"border\",              enabled = 1, speed = 5.39, bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"windows\",             enabled = 1, speed = 4,    bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"windowsIn\",           enabled = 1, speed = 4,    bezier = \"easeOutQuint\", style = \"popin 1%\"})
hl.animation({ leaf = \"windowsOut\",          enabled = 1, speed = 4,    bezier = \"easeOutQuint\", style = \"popin 1%\"})
hl.animation({ leaf = \"windowsMove\",         enabled = 1, speed = 4,    bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"fadeIn\",              enabled = 1, speed = 1,    bezier = \"almostLinear\"})
hl.animation({ leaf = \"fadeOut\",             enabled = 1, speed = 1,    bezier = \"almostLinear\"})
hl.animation({ leaf = \"fade\",                enabled = 1, speed = 5,    bezier = \"quick\"})
hl.animation({ leaf = \"layers\",              enabled = 1, speed = 3.81, bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"layersIn\",            enabled = 1, speed = 4,    bezier = \"easeOutQuint\", style = \"fade\"})
hl.animation({ leaf = \"layersOut\",           enabled = 1, speed = 1.5,  bezier = \"linear\",         style = \"fade\"})
hl.animation({ leaf = \"fadeLayersIn\",        enabled = 1, speed = 1.79, bezier = \"almostLinear\"})
hl.animation({ leaf = \"fadeLayersOut\",       enabled = 1, speed = 1.39, bezier = \"almostLinear\"})
hl.animation({ leaf = \"workspaces\",          enabled = 1, speed = 1.94, bezier = \"almostLinear\",    style = \"fade\"})
hl.animation({ leaf = \"workspacesIn\",        enabled = 1, speed = 4,    bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"workspacesOut\",       enabled = 1, speed = 4,    bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"specialWorkspaceIn\",  enabled = 1, speed = 3,    bezier = \"easeOutQuint\", style = \"slidevert top 50%\"})
hl.animation({ leaf = \"specialWorkspaceOut\", enabled = 1, speed = 3,    bezier = \"easeOutQuint\", style = \"slidevert bottom 50%\"})
hl.animation({ leaf = \"zoomFactor\",          enabled = 1, speed = 7,    bezier = \"easeOutQuint\"})

hl.unbind(\"SUPER + space\")
hl.unbind(\"SUPER + escape\")
hl.unbind(\"SUPER + P\")
hl.bind(\"SUPER + space\", hl.dsp.exec_cmd(\"qs -c tui ipc call config close_popup quick_menu\"), {release = false})
hl.bind(\"SUPER + space\", hl.dsp.exec_cmd(\"qs -c tui ipc call config close_popup quick_menu\"), {release = true})
hl.bind(\"SUPER + escape\", hl.dsp.exec_cmd(\"qs -c tui ipc call launcher toggle\"))
hl.bind(\"SUPER + P\", hl.dsp.exec_cmd(\"qs -c tui ipc call config dummy\"))
"

hyprctl eval "$SET_COLOR"

echo "Finished setting up Hyprland's config"
