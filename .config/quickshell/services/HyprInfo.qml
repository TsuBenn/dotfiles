pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {

    id: root

    property int focusedworkspace: Hyprland.focusedWorkspace?.id

    onFocusedworkspaceChanged: {
        //console.log(focusedworkspace)
    }

    property var focusedwindow: {"title": "", "class": ""}

    property var workspaces

    property var specialWorkspaces
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
                    special.running = true
                    get_icons.reload()
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
                    const windowclass = data.initialClass
                    const windowtitle = data.initialTitle
                    const focused = (data.focusHistoryID == 0)
                    if (workspaces[workspace] == undefined) workspaces[workspace] = [] 
                    workspaces[workspace].push({"workspace": workspace, "monitor": monitor, "windowclass": windowclass, "windowtitle": windowtitle, "focused": focused})
                    if (focused) root.focusedwindow = {"title": windowtitle, "class": windowclass}
                }
                if (root.windowCount(root.focusedworkspace) == 0) root.focusedwindow = {"title": "Desktop", "class": ""}
                root.workspaces = workspaces
            }
        }
    }

    Process {
        id: special

        command: ["hyprctl", "workspaces", "-j"]

        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const specialWorkspaces = []
                const datas = JSON.parse(text)
                for (const data of datas) {
                    if (data.id >= 0) continue
                    //console.log(data.id)
                    const id = data.id ?? ""
                    const name = data.name ?? ""
                    const windows = data.windows ?? ""
                    specialWorkspaces.push({"id": id, "name": name, "windows": windows})
                }
                root.specialWorkspaces = specialWorkspaces
            }
        }
    }

}


