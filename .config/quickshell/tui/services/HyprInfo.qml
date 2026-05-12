pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {

    id: root

    function fmt(str, ...args) {
        return str.replace(/{}/g, () => args.shift());
    }

    property int focusedworkspace: Hyprland.focusedWorkspace?.id ?? 1
    property int focusedspecial: 0

    property var focusedwindow: {"title": "", "class": ""}

    property var workspaces
    property var specialworkspaces
    property var monitors: ({})

    property var focusedMonitor: ({})

    signal hyprEvent(event : string)

    signal cursorPos(ex: int, why: int)

    function switchWorkspace(n) {
        if (Number.isInteger(n)) {
            Hyprland.dispatch(root.fmt("hl.dsp.focus({workspace = {}})", n)) // New lua config
            return
        }
        Hyprland.dispatch(root.fmt(`hl.dsp.workspace.toggle_special("{}")`, n)) // New lua config
    }

    function windowCount(n) {
        if (!workspaces) return 0
        return workspaces[n]?.length ?? 0
    }

    function getCursorPos() {
        get_cursorpos.running = true
    }

    Component.onCompleted: {

        Hyprland.rawEvent.connect((event) => {
            switch (event.name) {
                case "openwindow":
                case "closewindow":
                case "movewindow":
                case "workspace":
                case "activewindow": {
                    process.running = true
                    specials.running = true
                    //get_icons.reload()
                    break
                }
                case "focusedmon": {
                    monitor.running = true
                    break
                }
            }
            root.hyprEvent(event.name)
            //console.log(event.name)
        })
    }

    Process {
        id: specials

        command: ["hyprctl", "workspaces", "-j"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var special = []
                const datas = JSON.parse(text)
                for (const data of datas) {
                    const id = data.id ?? 0
                    const name = data.name ?? ""
                    const windows = data.windows ?? 0
                    if (id < 0) {
                        special.push({"id":id,"name":name,"windows":windows})
                    }
                }
                root.specialworkspaces = special
            }
        }
    }

    Process {
        id: process

        command: ["hyprctl", "clients", "-j"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var workspaces = {}
                const datas = JSON.parse(text)
                for (const data of datas) {
                    const workspace = data.workspace.id ?? ""
                    const monitor = data.monitor ?? ""
                    const windowclass = data.class
                    const windowtitle = data.title
                    const fullscreen = parseInt(data.fullscreen)
                    const address = data.address
                    const focused = (data.focusHistoryID == 0)
                    if (workspaces[workspace] == undefined) workspaces[workspace] = [] 
                    workspaces[workspace].push({
                        "workspace": workspace,
                        "monitor": monitor,
                        "windowclass": windowclass,
                        "address": address,
                        "windowtitle": windowtitle,
                        "focused": focused,
                        "fullscreen": fullscreen
                    })
                    if (focused) {
                        root.focusedspecial = workspace < 0 ? workspace : 0
                        root.focusedwindow = {
                            "title": windowtitle,
                            "class": windowclass,
                            "address": address,
                            "monitor": monitor,
                            "fullscreen": fullscreen
                        }
                    }
                }
                if (root.windowCount(root.focusedworkspace) == 0) root.focusedwindow = {
                    "title": "Desktop",
                    "class": ""
                }
                root.workspaces = workspaces
            }
        }
    }

    Process {
        id: monitor

        command: ["hyprctl", "monitors", "-j"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const monitors = []
                const datas = JSON.parse(text)
                for (const data of datas) {
                    const id = data.id
                    const name = data.name
                    const width = data.width
                    const height = data.height
                    const scale = data.scale
                    const model = data.model
                    const refreshRate = data.refreshRate
                    const focused = data.focused
                    monitors[name] = {
                        "id": id,
                        "name": name,
                        "width": width,
                        "height": height,
                        "scale": scale,
                        "model": model,
                        "refreshRate": refreshRate,
                        "focused": focused
                    }
                    monitors[id] = {
                        "id": id,
                        "name": name,
                        "width": width,
                        "height": height,
                        "scale": scale,
                        "model": model,
                        "refreshRate": refreshRate,
                        "focused": focused
                    }
                    if (focused) {
                        root.focusedMonitor = monitors[name]
                    }
                }
                root.monitors = monitors
            }
        }
    }

    Process {
        id: get_cursorpos

        command: ["hyprctl", "cursorpos"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    const data = text.split(",")
                    root.cursorPos(parseInt(data[0]),parseInt(data[1]))
                }
            }
        }

    }

}


