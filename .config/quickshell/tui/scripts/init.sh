#!/bin/bash

echo ""
echo ""
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
        },
        blur = {
            enabled = ${4},
            size = 1,
            passes = 2,
            vibrancy = 0.2,
        }
    },

    animations = {
        enabled = true
    }

})

hl.curve(\"easeOutQuint\",   { type = \"bezier\", points = {{ 0.23, 1},    { 0.32, 1}} })
hl.curve(\"easeInOutCubic\", { type = \"bezier\", points = {{ 0.65, 0.05}, { 0.36, 1}} })
hl.curve(\"linear\",         { type = \"bezier\", points = {{ 0,    0},    { 1,    1}} })
hl.curve(\"almostLinear\",   { type = \"bezier\", points = {{ 0.5,  0.5},  { 0.75, 1}} })
hl.curve(\"quick\",          { type = \"bezier\", points = {{ 0.15, 0},    { 0.1,  1}} })

hl.animation({ leaf = \"global\",              enabled = ${3}, speed = 5,   bezier = \"default\"})
hl.animation({ leaf = \"border\",              enabled = ${3}, speed = 4.5, bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"windows\",             enabled = ${3}, speed = 3,    bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"windowsIn\",           enabled = ${3}, speed = 3,    bezier = \"easeOutQuint\", style = \"popin 1%\"})
hl.animation({ leaf = \"windowsOut\",          enabled = ${3}, speed = 4,    bezier = \"easeOutQuint\", style = \"popin 1%\"})
hl.animation({ leaf = \"windowsMove\",         enabled = ${3}, speed = 3,    bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"fadeIn\",              enabled = ${3}, speed = 1,    bezier = \"almostLinear\"})
hl.animation({ leaf = \"fadeOut\",             enabled = ${3}, speed = 1,    bezier = \"almostLinear\"})
hl.animation({ leaf = \"fade\",                enabled = ${3}, speed = 4,    bezier = \"quick\"})
hl.animation({ leaf = \"layers\",              enabled = ${3}, speed = 3, bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"layersIn\",            enabled = ${3}, speed = 3,    bezier = \"easeOutQuint\", style = \"fade\"})
hl.animation({ leaf = \"layersOut\",           enabled = ${3}, speed = 1,  bezier = \"linear\",         style = \"fade\"})
hl.animation({ leaf = \"fadeLayersIn\",        enabled = ${3}, speed = 1, bezier = \"almostLinear\"})
hl.animation({ leaf = \"fadeLayersOut\",       enabled = ${3}, speed = 1, bezier = \"almostLinear\"})
hl.animation({ leaf = \"workspaces\",          enabled = ${3}, speed = 1, bezier = \"almostLinear\",    style = \"fade\"})
hl.animation({ leaf = \"workspacesIn\",        enabled = ${3}, speed = 3,    bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"workspacesOut\",       enabled = ${3}, speed = 3,    bezier = \"easeOutQuint\"})
hl.animation({ leaf = \"specialWorkspaceIn\",  enabled = ${3}, speed = 2,    bezier = \"easeOutQuint\", style = \"slidevert top 50%\"})
hl.animation({ leaf = \"specialWorkspaceOut\", enabled = ${3}, speed = 2,    bezier = \"easeOutQuint\", style = \"slidevert bottom 50%\"})
hl.animation({ leaf = \"zoomFactor\",          enabled = 1, speed = 5,    bezier = \"easeOutQuint\"})

hl.unbind(\"SUPER + space\")
hl.unbind(\"SUPER + escape\")
hl.unbind(\"SUPER + SHIFT + P\")
hl.unbind(\"SUPER + P\")
hl.unbind(\"SUPER + period\")
hl.unbind(\"SUPER + V\")
hl.bind(\"SUPER + space\", hl.dsp.exec_cmd(\"qs -c tui ipc call config toggle_popup quick_menu\"))
hl.bind(\"SUPER + escape\", hl.dsp.exec_cmd(\"qs -c tui ipc call launcher toggle\"))
hl.bind(\"SUPER + P\", hl.dsp.exec_cmd(\"qs -c tui ipc call config dummy\"))
hl.bind(\"SUPER + SHIFT + P\", hl.dsp.exec_cmd(\"pkill -f qs\"))
hl.bind(\"SUPER + period\", hl.dsp.exec_cmd(\"qs -c tui ipc call config toggle_popup emoji\"))
hl.bind(\"SUPER + V\", hl.dsp.exec_cmd(\"qs -c tui ipc call config toggle_popup clipboard\"))

"

hyprctl eval "$SET_COLOR"

echo "Finished setting up Hyprland's config"
