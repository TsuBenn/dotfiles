pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.components.bar
import qs.components
import qs.services

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {

    Item {
        Component.onCompleted: {
            Colors.applied.connect(() => {
                init()
            })
            SettingsInfo.dependenciesCheckedChanged.connect(() => {
                if (SettingsInfo.dependenciesChecked) init()
            })
            SettingsInfo.hyprAnimChanged.connect(() => {
                init()
            })
            SettingsInfo.hyprBlurChanged.connect(() => {
                init()
            })
        }

        function init() {
            const active_border = "rgba(" + Colors.borderActive.toString().slice(1) + "ff)"
            const inactive_border = "rgba(" + Colors.borderInactive.toString().slice(1) + "ff)"

            const command = `hl.config({

                general = {

                    gaps_in =  { top = 8, left = 3, bottom = 8, right = 3 },
                    gaps_out = { top = 9, left = 5, bottom = 9, right = 5 },

                    border_size = 2,

                    col = {
                        active_border = \"${active_border}\",
                        inactive_border = \"${inactive_border}\",
                    }

                },

                decoration = {
                    rounding = 0,
                    shadow  = {
                        enabled = false
                    },
                    blur = {
                        enabled = ${SettingsInfo.hyprBlur},
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

            hl.animation({ leaf = \"global\",              enabled = ${SettingsInfo.hyprAnim}, speed = 5,   bezier = \"default\"})
            hl.animation({ leaf = \"border\",              enabled = ${SettingsInfo.hyprAnim}, speed = 4.5, bezier = \"easeOutQuint\"})
            hl.animation({ leaf = \"windows\",             enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = \"easeOutQuint\"})
            hl.animation({ leaf = \"windowsIn\",           enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = \"easeOutQuint\", style = \"popin 1%\"})
            hl.animation({ leaf = \"windowsOut\",          enabled = ${SettingsInfo.hyprAnim}, speed = 4,    bezier = \"easeOutQuint\", style = \"popin 1%\"})
            hl.animation({ leaf = \"windowsMove\",         enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = \"easeOutQuint\"})
            hl.animation({ leaf = \"fadeIn\",              enabled = ${SettingsInfo.hyprAnim}, speed = 1,    bezier = \"almostLinear\"})
            hl.animation({ leaf = \"fadeOut\",             enabled = ${SettingsInfo.hyprAnim}, speed = 1,    bezier = \"almostLinear\"})
            hl.animation({ leaf = \"fade\",                enabled = ${SettingsInfo.hyprAnim}, speed = 4,    bezier = \"quick\"})
            hl.animation({ leaf = \"layers\",              enabled = ${SettingsInfo.hyprAnim}, speed = 3, bezier = \"easeOutQuint\"})
            hl.animation({ leaf = \"layersIn\",            enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = \"easeOutQuint\", style = \"fade\"})
            hl.animation({ leaf = \"layersOut\",           enabled = ${SettingsInfo.hyprAnim}, speed = 1,  bezier = \"linear\",         style = \"fade\"})
            hl.animation({ leaf = \"fadeLayersIn\",        enabled = ${SettingsInfo.hyprAnim}, speed = 1, bezier = \"almostLinear\"})
            hl.animation({ leaf = \"fadeLayersOut\",       enabled = ${SettingsInfo.hyprAnim}, speed = 1, bezier = \"almostLinear\"})
            hl.animation({ leaf = \"workspaces\",          enabled = ${SettingsInfo.hyprAnim}, speed = 1, bezier = \"almostLinear\",    style = \"fade\"})
            hl.animation({ leaf = \"workspacesIn\",        enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = \"easeOutQuint\"})
            hl.animation({ leaf = \"workspacesOut\",       enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = \"easeOutQuint\"})
            hl.animation({ leaf = \"specialWorkspaceIn\",  enabled = ${SettingsInfo.hyprAnim}, speed = 2,    bezier = \"easeOutQuint\", style = \"slidevert top 50%\"})
            hl.animation({ leaf = \"specialWorkspaceOut\", enabled = ${SettingsInfo.hyprAnim}, speed = 2,    bezier = \"easeOutQuint\", style = \"slidevert bottom 50%\"})
            hl.animation({ leaf = \"zoomFactor\",          enabled = 1, speed = 5,    bezier = \"easeOutQuint\"})

            hl.unbind(\"SUPER + space\")
            hl.unbind(\"SUPER + escape\")
            hl.unbind(\"SUPER + SHIFT + P\")
            hl.unbind(\"SUPER + P\")
            hl.unbind(\"SUPER + period\")
            hl.unbind(\"SUPER + V\")
            hl.unbind(\"end\")
            hl.unbind(\"SUPER + end\")
            hl.unbind(\"print\")
            hl.unbind(\"SUPER + print\")
            hl.unbind(\"SUPER + backspace\")
            hl.unbind(\"SUPER + L\")
            ${ SettingsInfo.dependenciesChecked ? `
            hl.bind(\"SUPER + space\", hl.dsp.exec_cmd(\"qs -c tui ipc call config toggle_popup quick_menu\"))
            hl.bind(\"SUPER + escape\", hl.dsp.exec_cmd(\"qs -c tui ipc call launcher toggle\"))
            hl.bind(\"SUPER + P\", hl.dsp.exec_cmd(\"qs -c tui ipc call config dummy\"))
            hl.bind(\"SUPER + SHIFT + P\", hl.dsp.exec_cmd(\"pkill -f qs\"))
            hl.bind(\"SUPER + period\", hl.dsp.exec_cmd(\"qs -c tui ipc call config toggle_popup emoji\"))
            hl.bind(\"SUPER + V\", hl.dsp.exec_cmd(\"qs -c tui ipc call config toggle_popup clipboard\"))
            hl.bind(\"end\", hl.dsp.exec_cmd(\"qs -c tui ipc call config screenshot false\"))
            hl.bind(\"SUPER + end\", hl.dsp.exec_cmd(\"qs -c tui ipc call config screenshot true\"))
            hl.bind(\"print\", hl.dsp.exec_cmd(\"qs -c tui ipc call config screenshot false\"))
            hl.bind(\"SUPER + print\", hl.dsp.exec_cmd(\"qs -c tui ipc call config screenshot true\"))
            hl.bind(\"SUPER + backspace\", hl.dsp.exec_cmd(\"qs -c tui ipc call config toggle_hidebar\"))
            hl.bind(\"SUPER + L\", hl.dsp.exec_cmd(\"qs -c tui ipc call config lock_screen\"))
            ` : ""}
            `

            process.exec(["hyprctl", "eval", command])
        }
    }

    Loader {

        active: SettingsInfo.dependenciesChecked

        sourceComponent: Bar {}

    }

    Loader {

        active: !SettingsInfo.dependenciesChecked

        sourceComponent: DependenciesChecker {
            property var wallpaper_loader: WallpaperInfo.wallpapers // Pre-initiating WallpaperInfo
            property var hyprinfo_loader: HyprInfo.maxRefreshRate // Pre-initiating HyprInfo
        }

    }

    Process {
        id: process 

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) console.error(text)
            }
        }
    }
}

