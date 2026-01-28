pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {

    id: root

    property int id: Hyprland.focusedWorkspace.id
    property var workspaces
    property var icons

    function switchWorkspace(n) {
        Hyprland.dispatch("workspace " + n)
    }

    function windowCount(n) {
        if (!workspaces) return 0
        return workspaces[n]?.length ?? 0
    }

    function iconFetch(query) {
        query = query.toLowerCase()
        const key = Object.keys(root.icons).find(k => k.includes(query))
        const value = key ? root.icons[key] : undefined
        return value
    }

    Component.onCompleted: {
        process.running = true
        Hyprland.rawEvent.connect((event) => {
            switch (event.name) {
                case "openwindow":
                case "closewindow":
                case "movewindow":
                case "activewindow": process.running = true; icons.reload(); break
            }
        })
    }

    FileView {
        id: icons

        path: ".config/quickshell/services/backend/icons.json"

        onLoaded: {
            root.icons = JSON.parse(text())
        }
    }

    Process {
        id: process

        command: ["hyprctl", "clients", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                const workspaces = {}
                const datas = JSON.parse(text)
                for (const data of datas) {
                    if (data.focusHistoryID > 10) continue
                    const workspace = data.workspace.id ?? ""
                    const monitor = data.monitor ?? ""
                    const windowclass = data.initialClass
                    const windowtitle = data.initialTitle
                    const focused = data.focusHistoryID == 0
                    if (workspaces[workspace] == undefined) workspaces[workspace] = [] 
                    workspaces[workspace].push({"workspace": workspace, "monitor": monitor, "windowclass": windowclass, "focused": focused})
                    //console.log(data.focusHistoryID)
                }
                root.workspaces = workspaces
            }
        }
    }

}


