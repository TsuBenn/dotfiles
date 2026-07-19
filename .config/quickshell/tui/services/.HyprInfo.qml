pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    function fmt(str, ...args) {
        return str.replace(/{}/g, () => args.shift());
    }

    property int maxRefreshRate: 0

    property var something: HyprInfo_new.focusedMonitor

    property int focusedworkspace: Hyprland.focusedWorkspace?.id ?? 1
    property int focusedspecial: 0

    property string activespecial: ""

    property var focusedwindow: {
        "title": "",
        "class": ""
    }

    property var workspaces

    property var specialworkspaces
    property var monitors: ({})

    property var focusedMonitor: ({})

    signal hyprEvent(event: string)

    signal cursorPos(ex: int, why: int)

    function switchWorkspace(n) {
        if (Number.isInteger(n)) {
            Hyprland.dispatch(root.fmt("hl.dsp.focus({workspace = {}})", n)); // New lua config
            return;
        }
        Hyprland.dispatch(root.fmt(`hl.dsp.workspace.toggle_special("{}")`, n)); // New lua config
    }

    function evaluate(code: string) {
        SystemInfo.runDetached(["hyprctl", "eval", code]);
    }

    function windowCount(n) {
        if (!workspaces)
            return 0;
        return workspaces[n]?.length ?? 0;
    }

    function isCurrentMonitor(name: string): bool {
        // console.log(`${focusedMonitor.name} == ${name}`)
        return focusedMonitor.name == name;
    }

    function focusWindow(le_title = "", le_class = "", le_address = "") {
        evaluate(fmt("focusWindow(\"{}\",\"{}\",\"{}\")", le_title, le_class, le_address));
    }

    function getCursorPos() {
        get_cursorpos.running = true;
    }

    Component.onCompleted: {
        Hyprland.rawEvent.connect(event => {
            switch (event.name) {
            case "workspace":
                {
                    if (!SettingsInfo.dependenciesChecked) {
                        Hyprland.dispatch(root.fmt("hl.dsp.window.move({workspace = {}, window = \"title:tsubenn_tui_qs_depcheck\"})", event.data));
                    }
                    if (root.activespecial) {
                        // switchWorkspace(root.activespecial.replace("special:", ""));
                    }
                    break;
                }
            case "openwindow":
            case "closewindow":
            case "movewindow":
            case "workspace":
            case "activewindow":
                {
                    process.running = true;
                    specials.running = true;
                    //get_icons.reload()
                    break;
                }
            case "focusedmon":
                {
                    monitor.running = true;
                    break;
                }
            case "activespecial":
                {
                    const data = event.data.split(",")[0];
                    root.activespecial = data;
                    if (!SettingsInfo.dependenciesChecked) {
                        Hyprland.dispatch(root.fmt("hl.dsp.window.move({workspace = \"{}\", window = \"title:tsubenn_tui_qs_depcheck\"})", data == "" ? root.focusedworkspace : data));
                    }
                    break;
                }
            }
            root.hyprEvent(event.name);
        // console.log(JSON.stringify(event))
        });
    }

    Process {
        id: specials

        command: ["hyprctl", "workspaces", "-j"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var special = [];
                const datas = JSON.parse(text);
                for (const data of datas) {
                    const id = data.id ?? 0;
                    const name = data.name ?? "";
                    const windows = data.windows ?? 0;
                    if (id < 0) {
                        special.push({
                            "id": id,
                            "name": name,
                            "windows": windows
                        });
                    }
                }
                root.specialworkspaces = special;
            }
        }
    }

    Process {
        id: process

        command: ["hyprctl", "clients", "-j"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var workspaces = {};
                const datas = JSON.parse(text);
                for (const data of datas) {
                    const workspace = data.workspace.id ?? "";
                    const monitor = data.monitor ?? "";
                    const windowclass = data.class;
                    const windowtitle = data.title;
                    const fullscreen = parseInt(data.fullscreen);
                    const address = data.address;
                    const focused = (data.focusHistoryID == 0);
                    if (workspaces[workspace] == undefined)
                        workspaces[workspace] = [];
                    workspaces[workspace].push({
                        "workspace": workspace,
                        "monitor": monitor,
                        "windowclass": windowclass,
                        "address": address,
                        "windowtitle": windowtitle,
                        "focused": focused,
                        "fullscreen": fullscreen
                    });
                    if (focused) {
                        root.focusedspecial = workspace < 0 ? workspace : 0;
                        root.focusedwindow = {
                            "title": windowtitle,
                            "class": windowclass,
                            "address": address,
                            "monitor": monitor,
                            "fullscreen": fullscreen
                        };
                    }
                }
                if (root.windowCount(root.focusedworkspace) == 0)
                    root.focusedwindow = {
                        "title": "Desktop",
                        "class": ""
                    };
                root.workspaces = workspaces;
            }
        }
    }

    Process {
        id: monitor

        command: ["hyprctl", "monitors", "-j"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const monitors = [];
                const datas = JSON.parse(text);
                for (const data of datas) {
                    const id = data.id;
                    const name = data.name;
                    const x = data.x;
                    const y = data.y;
                    const width = data.width;
                    const height = data.height;
                    const scale = data.scale;
                    const model = data.model;
                    const refreshRate = data.refreshRate;
                    const focused = data.focused;

                    if (refreshRate > root.maxRefreshRate) {
                        root.maxRefreshRate = refreshRate;
                    }

                    monitors[name] = {
                        "id": id,
                        "name": name,
                        "x": x,
                        "y": y,
                        "width": width / scale,
                        "height": height / scale,
                        "scale": scale,
                        "model": model,
                        "refreshRate": refreshRate,
                        "focused": focused
                    };
                    monitors[id] = {
                        "id": id,
                        "name": name,
                        "x": x,
                        "y": y,
                        "width": width / scale,
                        "height": height / scale,
                        "scale": scale,
                        "model": model,
                        "refreshRate": refreshRate,
                        "focused": focused
                    };
                    if (focused) {
                        root.focusedMonitor = monitors[name];
                    }
                }
                root.monitors = monitors;
            }
        }
    }

    Process {
        id: get_cursorpos

        command: ["hyprctl", "cursorpos"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    const data = text.split(",");
                    root.cursorPos(parseInt(data[0]), parseInt(data[1]));
                }
            }
        }
    }
}
