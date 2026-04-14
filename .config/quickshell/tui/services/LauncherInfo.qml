pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property var apps: []
    property var settings: []
    property var web: []
    property var calc: []

    function search(mode = "apps", query: string) {
        process.mode = mode
        process.exec(["python", ".config/quickshell/tui/scripts/launcher.py", "--mode", mode, query])
        scan_icons()
    }

    function scan_icons(force = true) {
        if (icon.running && !force) return
        icon.running = true
    }

    function reset() {
        apps = []
        settings = []
        web = []
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
                    } else if (process.mode == "settings") {
                        console.log(text)
                    } else if (process.mode == "web") {
                        console.log(text)
                    } else if (process.mode == "calc") {
                        console.log(text)
                    }
                }
            }
        }

    }

}
