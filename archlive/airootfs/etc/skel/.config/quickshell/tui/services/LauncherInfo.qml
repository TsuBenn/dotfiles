pragma Singleton

import qs.services
import qs.config

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string backend: SystemInfo.configdir + "/scripts/launcher.py"

    property var result: []

    property bool running: false

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
        if (item.category) {
            if (item.category == "app") {
                process.write(`-F ${item.id}\n`)
                PopupManager.close("launcher")
            }
            if (item.category == "calc_result") {
                NotificationsInfo.send("System","","Launcher", "Copied calculation result: " + item.description)
            }
        }
        if (item.type == "exec") SystemInfo.runDetached(item.value)
        if (item.type == "menu") root.pathFound(item.id, item.label)
        if (item.type == "dir" || item.type == "file") {
            SystemInfo.copy_clipboard(item.value)
            NotificationsInfo.send("System","","Launcher",`Copied ${item.type == "dir" ? "directory's" : "file's"} path to clipboard.`)
            SystemInfo.runDetached(["bash", "-c", `dolphin --select "${item.value}"`])
        }
    }

    function reset() {
        console.log("LauncherInfo: Process restarting...")
        stop()
        start()
    }

    function start() {
        console.log("LauncherInfo: Process started!")
        result = []
        root.running = true
        process.running = true
    }

    function stop() {
        console.log("LauncherInfo: Process stopped!")
        result = []
        root.running = false
        process.running = false
    }

    function write(text: string) {
        process.write(`${text}\n`)
    } 

    Component.onCompleted: {
        start()
    }

    Process {

        id: process

        command: ["python", root.backend]

        onRunningChanged: {
            if (!running && root.running) {
                console.log("LauncherInfo: Process closed unexpectedly, Process restarting...")
                running = true
            } else if (running && !root.running) {
                console.log("LauncherInfo: Process opened unexpectedly, Process closing...")
                running = false
            }
            console.log(`Process: ${running}, Root: ${root.running}`)
            root.result = []
        }

        stdout: SplitParser {
            onRead: (text) => {
                if (text) {
                    let data = []
                    try {
                        data = JSON.parse(text)
                    } catch (error) {
                        //console.log("LauncherInfo: Parse Error")
                        return
                    }
                    if (data) {
                        root.result = data
                        root.searched(data)
                        //console.log(JSON.stringify(data,null,2))
                    } else {
                        console.log("LauncherInfo: No data: " + text)
                    }
                } else {
                    //console.log("LauncherInfo: No output: " + text)
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
