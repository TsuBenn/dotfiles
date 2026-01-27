pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {

    id: root

    property int id: Hyprland.focusedWorkspace.id
    property var workspaces

    property var apps

    function switchWorkspace(n) {
        Hyprland.dispatch("workspace " + n)
    }

    function windowCount(n) {
        return workspaces[n]?.length ?? 0
    }

    Timer {
        id: timer
        interval: 1
        running: true
        repeat: true
        triggeredOnStart: true
        
        onTriggered: {
            process.running = true
        }
    }

    Process {
        id: process

        command: ["hyprctl", "clients"]

        stdout: StdioCollector {
            onStreamFinished: {
                const workspaces = {}
                const datas = text.match(/Window [\s\S]*?(?=\n\nWindow|\s*$)/g)
                for (const data of datas) {
                    const workspace = parseInt(data.match(/workspace: (.+)/)[1])
                    const monitor = data.match(/monitor: (.+)/)[1]
                    const windowclass = data.match(/initialClass: (.+)/)[1]
                    const windowtitle = data.match(/initialTitle: (.+)/)[1]
                    const focused = parseInt(data.match(/focusHistoryID: (.+)/)[1]) == 0
                    if (workspaces[workspace] == undefined) workspaces[workspace] = [] 
                    workspaces[workspace].push({"workspace": workspace, "monitor": monitor, "windowclass": windowclass, "focused": focused})
                }
                root.workspaces = workspaces
            }
        }
    }

}


