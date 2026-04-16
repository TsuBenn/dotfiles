pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string backend: SystemInfo.homedir + "/dotfiles/.config/quickshell/tui/scripts/launcher.py"

    property var apps: []
    property var calc: []
    property var calc_preset: [
        {
            label: "abs()",
            description: "Absolute",
            cursor: 4
        },
        {
            label: "sqrt()",
            description: "Square root",
            cursor: 5
        },
        {
            label: "pow()",
            description: "Power",
            cursor: 4
        },
        {
            label: "sin()",
            description: "Sine",
            cursor: 4
        },
        {
            label: "cos()",
            description: "Cosine",
            cursor: 4
        },
        {
            label: "tan()",
            description: "Tangent",
            cursor: 4
        },
        {
            label: "log()",
            description: "Logarith",
            cursor: 4
        },
        {
            label: "pi",
            description: "Pi",
            cursor: 2
        },
        {
            label: "e",
            description: "E",
            cursor: 2
        },
    ]

    function search_apps(query: string) {
        process.mode = "apps"
        process.exec(["python", root.backend, "--fuzzy", "--mode", "apps", query])
        scan_icons()
    }

    function calculate(query: string) {
        if (!query) {
            calc = calc_preset
            return
        }
        process.mode = "calc"
        process.exec(["python", root.backend, "--mode", "calc", query.trim()])
    }

    function copy_result(copy) {
        process.exec(["echo", copy, "| wl-copy"])
    }

    function select(mode = "apps", query: string, select: string) {
        process.command = ["python", root.backend, "--mode", mode, query, "--select", select]
        process.startDetached()
        process.command = []
    }

    function scan_icons(force = true) {
        if (icon.running && !force) return
        icon.running = true
    }

    function reset() {
        apps = []
        calc = calc_preset
    }

    Process {

        id: icon

        command: ["python", root.backend, "--icons"]

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
                        root.settings = data
                    } else if (process.mode == "calc") {
                        const error = data[0].label.includes("Error")
                        root.calc = [{
                            label: !error? "= " + data[0].label : "No result",
                            description: !error? data[0].label : "",
                            type: "result"
                        },...root.calc_preset]
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
