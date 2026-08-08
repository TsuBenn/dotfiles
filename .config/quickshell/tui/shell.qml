pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.components.bar
import qs.components
import qs.services

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    Item {
        Component.onCompleted: {
            Colors.applied.connect(() => {
                SettingsInfo.colorsLoaded = true;
                init();
            });
            SettingsInfo.dependenciesCheckedChanged.connect(() => {
                if (SettingsInfo.dependenciesChecked)
                    init();
            });
            SettingsInfo.hyprAnimChanged.connect(() => {
                init();
            });
            SettingsInfo.hyprBlurChanged.connect(() => {
                init();
            });
            SystemInfo.initializedSystemInfo.connect(() => {
                wallpaper_check.active = true;
            });
        }

        function init() {
            const active_border = "rgba(" + Colors.accentStrong.toString().slice(1) + "ff)";
            const inactive_border = "rgba(" + Colors.accentDim.toString().slice(1) + "ff)";

            const command = `hl.config({

                general = {

                    gaps_in =  { top = 8, left = 3, bottom = 8, right = 3 },
                    gaps_out = { top = 9, left = 5, bottom = 9, right = 5 },

                    border_size = ${Cell.border_width},

                    allow_tearing = true,

                    col = {
                        active_border = "${active_border}",
                        inactive_border = "${inactive_border}",
                    }

                },

                xwayland = {
                    force_zero_scaling = true
                },

                render = {
                    direct_scanout = 2
                },

                cursor = {
                    no_hardware_cursors = 0,
                    use_cpu_buffer = 1,
                },

                decoration = {
                    rounding = 0,
                    shadow  = {
                        enabled = ${SettingsInfo.shadow}
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

            hl.curve("easeOutQuint",   { type = "bezier", points = {{ 0.23, 1},    { 0.32, 1}} })
            hl.curve("easeInOutCubic", { type = "bezier", points = {{ 0.65, 0.05}, { 0.36, 1}} })
            hl.curve("linear",         { type = "bezier", points = {{ 0,    0},    { 1,    1}} })
            hl.curve("almostLinear",   { type = "bezier", points = {{ 0.5,  0.5},  { 0.75, 1}} })
            hl.curve("quick",          { type = "bezier", points = {{ 0.15, 0},    { 0.1,  1}} })

            hl.animation({ leaf = "global",              enabled = ${SettingsInfo.hyprAnim}, speed = 5,   bezier = "default"})
            hl.animation({ leaf = "border",              enabled = ${SettingsInfo.hyprAnim}, speed = 4.5, bezier = "easeOutQuint"})
            hl.animation({ leaf = "windows",             enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = "easeOutQuint"})
            hl.animation({ leaf = "windowsIn",           enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = "easeOutQuint", style = "popin 1%"})
            hl.animation({ leaf = "windowsOut",          enabled = ${SettingsInfo.hyprAnim}, speed = 4,    bezier = "easeOutQuint", style = "popin 1%"})
            hl.animation({ leaf = "windowsMove",         enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = "easeOutQuint"})
            hl.animation({ leaf = "fadeIn",              enabled = ${SettingsInfo.hyprAnim}, speed = 1,    bezier = "almostLinear"})
            hl.animation({ leaf = "fadeOut",             enabled = ${SettingsInfo.hyprAnim}, speed = 1,    bezier = "almostLinear"})
            hl.animation({ leaf = "fade",                enabled = ${SettingsInfo.hyprAnim}, speed = 4,    bezier = "quick"})
            hl.animation({ leaf = "layers",              enabled = ${SettingsInfo.hyprAnim}, speed = 3, bezier = "easeOutQuint"})
            hl.animation({ leaf = "layersIn",            enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = "easeOutQuint", style = "fade"})
            hl.animation({ leaf = "layersOut",           enabled = ${SettingsInfo.hyprAnim}, speed = 1,  bezier = "linear",         style = "fade"})
            hl.animation({ leaf = "fadeLayersIn",        enabled = ${SettingsInfo.hyprAnim}, speed = 1, bezier = "almostLinear"})
            hl.animation({ leaf = "fadeLayersOut",       enabled = ${SettingsInfo.hyprAnim}, speed = 1, bezier = "almostLinear"})
            hl.animation({ leaf = "workspaces",          enabled = ${SettingsInfo.hyprAnim}, speed = 1, bezier = "almostLinear",    style = "fade"})
            hl.animation({ leaf = "workspacesIn",        enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = "easeOutQuint"})
            hl.animation({ leaf = "workspacesOut",       enabled = ${SettingsInfo.hyprAnim}, speed = 3,    bezier = "easeOutQuint"})
            hl.animation({ leaf = "specialWorkspaceIn",  enabled = ${SettingsInfo.hyprAnim}, speed = 2,    bezier = "easeOutQuint", style = "slidevert top 50%"})
            hl.animation({ leaf = "specialWorkspaceOut", enabled = ${SettingsInfo.hyprAnim}, speed = 2,    bezier = "easeOutQuint", style = "slidevert bottom 50%"})
            hl.animation({ leaf = "zoomFactor",          enabled = 1, speed = 5,    bezier = "easeOutQuint"})

            local lockRules = {}

            if not SetWorkspaceLock then
                function SetWorkspaceLock(wsList)
                  local desired = {}
                  for _, ws in ipairs(wsList) do
                    desired[tostring(ws)] = true
                  end

                  for ws, rule in pairs(lockRules) do
                    if not desired[ws] then
                      rule:set_enabled(false)
                      lockRules[ws] = nil
                    end
                  end

                  for ws, _ in pairs(desired) do
                    if not lockRules[ws] then
                      lockRules[ws] = hl.window_rule({
                        name = "lock_ws_" .. ws,
                        match = { workspace = ws , title = "negative:^(Workspace Authenticator|Workspace Locker Background)$"},
                        opacity = "0.0 override",
                        no_focus = true,
                        no_shortcuts_inhibit = true,
                        no_screen_share = true
                      })
                    end
                  end
                end
            end

            if SetWorkspaceLock then
                SetWorkspaceLock({})
            end

            hl.window_rule({
                match = { class = "^org.quickshell$", title = "^Workspace Authenticator$"},
                float = true,
                size = {"monitor_w", "monitor_h"},
                center = true,
                confine_pointer = true,
                focus_on_activate = true,
                no_close_for = 86400000,
                stay_focused = true,
                pin = true
            })

            hl.unbind("SUPER + space")
            hl.unbind("SUPER + escape")
            hl.unbind("SUPER + SHIFT + P")
            hl.unbind("SUPER + P")
            hl.unbind("SUPER + period")
            hl.unbind("SUPER + V")
            hl.unbind("end")
            hl.unbind("SUPER + end")
            hl.unbind("print")
            hl.unbind("SUPER + print")
            hl.unbind("SUPER + backspace")
            hl.unbind("SUPER + L")
            ${SettingsInfo.dependenciesChecked ? `
            hl.bind("SUPER + space", hl.dsp.exec_cmd("qs -c tui ipc call config toggle_popup quick_menu"))
            hl.bind("SUPER + escape", hl.dsp.exec_cmd("qs -c tui ipc call launcher toggle"))
            hl.bind("SUPER + P", hl.dsp.exec_cmd("qs -c tui ipc call config dummy"))
            hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("pkill -f qs"))
            hl.bind("SUPER + period", hl.dsp.exec_cmd("qs -c tui ipc call config toggle_popup emoji"))
            hl.bind("SUPER + V", hl.dsp.exec_cmd("qs -c tui ipc call config toggle_popup clipboard"))
            hl.bind("end", hl.dsp.exec_cmd("qs -c tui ipc call config screenshot false"))
            hl.bind("SUPER + end", hl.dsp.exec_cmd("qs -c tui ipc call config screenshot true"))
            hl.bind("print", hl.dsp.exec_cmd("qs -c tui ipc call config screenshot false"))
            hl.bind("SUPER + print", hl.dsp.exec_cmd("qs -c tui ipc call config screenshot true"))
            hl.bind("SUPER + backspace", hl.dsp.exec_cmd("qs -c tui ipc call config toggle hideBar"))
            hl.bind("SUPER + L", hl.dsp.exec_cmd("qs -c tui ipc call config lock_screen"))
            ` : ""}
            `;

            process.exec(["hyprctl", "eval", command]);
        }
    }

    /* FloatingWindow {

        visible: SettingsInfo.debug

        maximumSize: Qt.size(Cell.w(test_box.w), Cell.h(test_box.h))
        minimumSize: Qt.size(Cell.w(test_box.w), Cell.h(test_box.h))

        Cells {
            id: test_box
            w: 50
            h: 25
            color: Colors.bgSurface

            CellScrollList {
                id: test_list
                y: Cell.h(2)
                w: 40
                h: 20
                itemH: 2
                model: LauncherInfo.result
                delegate: CellText {
                    property int index
                    property var modelData
                    preferedW: test_list.contentW
                    text: index + " " + modelData?.label + "\n"
                    wrap: true
                }
            }
        }
    } */

    Loader {

        active: SettingsInfo.dependenciesChecked && SettingsInfo.colorsLoaded && SettingsInfo.wallpaperCached

        sourceComponent: Bar {}
    }

    WlSessionLock {

        Component.onCompleted: {
            LockInfo.lock.connect(() => {
                this.locked = true;
            });
            LockInfo.unlock.connect(() => {
                this.locked = false;
            });
        }

        LockSession {}
    }

    Loader {
        id: dependencies_check

        active: SettingsInfo.colorsLoaded

        sourceComponent: DependenciesChecker {
            property var hyprinfo_loader: HyprInfo.active   // Pre-initiating HyprInfo
        }
    }

    Loader {
        id: color_loader

        active: SettingsInfo.wallpaperCached

        sourceComponent: ColorsLoader {}
    }

    Loader {
        id: wallpaper_check

        active: false

        sourceComponent: WallpaperCacher {}
    }

    Process {
        id: process

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text)
                    console.error(text);
            }
        }
    }
}
