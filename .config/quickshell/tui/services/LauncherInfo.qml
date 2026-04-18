pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string backend: SystemInfo.homedir + "/dotfiles/.config/quickshell/tui/scripts/launcher.py"

    property var result: []

    signal searched(data: var)

    function search(tags: string, query = "") {
        if (process.running) {
            process.write(`${tags} ${query}\n`)
        } else {
            console.error("LauncherInfo: Process is not running")
        }
    }

    function start() {
        process.running = true
    }

    function stop() {
        process.running = false
    }

    Process {

        id: process

        onRunningChanged: {
            root.result = []
        }

        stdout: SplitParser {
            onRead: (text) => {
                const data = JSON.parse(text)
                if (data) {
                    root.result = data
                    root.searched(data)
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
