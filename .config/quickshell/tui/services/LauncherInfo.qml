pragma Singleton

import qs.services
import qs.config

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string backend: SystemInfo.homedir + "/dotfiles/.config/quickshell/tui/scripts/launcher.py"

    property var result: []

    property bool running: process.running

    signal searched(data: var)
    signal pathFound(id: string, label: string)

    function search(tags: string, paths = [], query = "") {
        let le_paths = ""
        if (paths) {
            for (const path of paths)  {
                le_paths += "--" + path.id + " "
            }
        }
        if (process.running) {
            process.write(`-${tags} ${le_paths} ${query}\n`)
        } else {
            console.error("LauncherInfo: Process is not running")
        }
    }

    function run(index: int) {
        const item = result[index] 
        if (item.category == "app") {
            process.write(`-F ${item.id}\n`)
            PopupManager.close("launcher")
        }
        if (item.type == "exec") SystemInfo.runDetached(item.value)
        if (item.type == "menu") root.pathFound(item.id, item.label)
    }

    function reset() {
        stop()
        start()
    }

    function start() {
        result = []
        process.running = true
    }

    function stop() {
        result = []
        process.running = false
    }

    Process {

        id: process

        running: true
        command: ["python", root.backend]

        onRunningChanged: {
            root.result = []
        }

        stdout: SplitParser {
            onRead: (text) => {
                const data = JSON.parse(text)
                if (data) {
                    root.result = data
                    root.searched(data)
                    //console.log(JSON.stringify(data,null,2))
                }
            }
        }

        stderr: SplitParser {
            onRead: (text) => {
                if (text) {
                    console.log("LauncherInfo: " + text)
                }
            }
        }

    }

}
