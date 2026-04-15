pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property var apps: []
    property var settings: []
    property var calc: []
    property var result: []

    function search(mode = "apps", query: string) {
        process.mode = mode
        process.exec(["python", ".config/quickshell/tui/scripts/launcher.py", "--fuzzy", "--mode", mode, query])
        scan_icons()
    }

    function select(mode = "apps", query: string, select: string) {
        process.command = ["python", ".config/quickshell/tui/scripts/launcher.py", "--mode", mode, query, "--select", select]
        process.startDetached()
        process.command = []
    }

    function scan_icons(force = true) {
        if (icon.running && !force) return
        icon.running = true
    }

    function reset() {
        apps = []
        settings = []
        calc = []
    }

    Process {

        id: icon

        command: ["python", ".config/quickshell/tui/scripts/launcher.py", "--icons"]

    }

    Process {

        id: process

        property string mode: "apps"

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    const data = JSON.parse(text)
                    if (process.mode == "apps") {
                        root.apps = data
                        root.result = data
                    } else if (process.mode == "settings") {
                        root.settings = data
                        root.result = data
                    } else if (process.mode == "web") {
                        console.log(text)
                    } else if (process.mode == "calc") {
                        console.log(text)
                    }
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log("LauncherInfo: " + text)
                }
            }
        }

    }

}
