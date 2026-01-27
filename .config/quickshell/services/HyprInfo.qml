pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {

    id: root

    property int id: Hyprland.focusedWorkspace.id
    property var workspaces

    function switchWorkspace(n) {
        Hyprland.dispatch("workspace " + n)
    }

    function windowCount(n) {
        return workspaces[n]?.length ?? 0
    }

    Component.onCompleted: {
        Hyprland.rawEvent.connect((event) => {
            process.running = true
        })
    }

    Process {
        id: process

        command: ["hyprctl", "clients", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                const workspaces = {}
                const datas = JSON.parse(text)
                for (const data of datas) {
                    if (data.focusHistoryID > 20) continue
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


