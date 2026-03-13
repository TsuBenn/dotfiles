pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {

    id: root

    property int focusedworkspace: Hyprland.focusedWorkspace?.id

    property var focusedwindow: {"title": "", "class": ""}

    property var workspaces
    property var monitors: ({})

    property var focusedMonitor: ({})

    property var icons

    signal hyprEvent(event : string)

    function switchWorkspace(n) {
        Hyprland.dispatch("workspace " + n)
    }

    function windowCount(n) {
        if (!workspaces) return 0
        return workspaces[n]?.length ?? 0
    }

    function iconFetch(query, query2) {
        if (query == "") return "exception"
        query = query.replace(/\.[^/.]+$/, "").toLowerCase()
        query2 = query2.replace(/\.[^/.]+$/, "").toLowerCase()
        var key = Object.keys(root.icons).find(k => k.toLowerCase().includes(query))
        var value = key ? root.icons[key] : undefined
        if (!value) {
            key = Object.entries(root.icons).find(([,k]) => k.toLowerCase().includes(query))
            value = key ? key[1] : undefined
        }
        if (!value) {
            key = Object.keys(root.icons).find(k => k.toLowerCase().includes(query2))
            value = key ? root.icons[key] : undefined
        }
        if (!value) {
            key = Object.entries(root.icons).find(([,k]) => k.toLowerCase().includes(query2))
            value = key ? key[1] : "exception"
        }
        if (!value) value = "exception"
        return value
    }

    Component.onCompleted: {

        Hyprland.rawEvent.connect((event) => {
            switch (event.name) {
                case "openwindow":
                case "closewindow":
                case "movewindow":
                case "activewindow": {
                    process.running = true
                    get_icons.reload()
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

    FileView {
        id: get_icons

        path: ".config/quickshell/services/backend/icons.json"

        onLoaded: {
            root.icons = JSON.parse(text())
        }
    }

    Process {
        id: process

        command: ["hyprctl", "clients", "-j"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const workspaces = {}
                const datas = JSON.parse(text)
                for (const data of datas) {
                    const workspace = data.workspace.id ?? ""
                    const monitor = data.monitor ?? ""
                    const windowclass = data.class
                    const windowtitle = data.title
                    const address = data.address
                    const focused = (data.focusHistoryID == 0)
                    if (workspaces[workspace] == undefined) workspaces[workspace] = [] 
                    workspaces[workspace].push({
                        "workspace": workspace,
                        "monitor": monitor,
                        "windowclass": windowclass,
                        "address": address,
                        "windowtitle": windowtitle,
                        "focused": focused
                    })
                    if (focused) root.focusedwindow = {
                        "title": windowtitle,
                        "class": windowclass,
                        "address": address,
                        "monitor": monitor,
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

}


