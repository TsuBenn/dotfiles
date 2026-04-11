pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property var bluetooth_connected: []
    property var bluetooth_saved: []
    property var bluetooth_scan: []

    property bool enabled: SystemInfo.bluetooth.enabled

    property bool scanning: process.running

    function toggle() {
        if (status.running) return 1
        status.running = true
        return 0
    } 

    function scanToggle() {
        scanning ? scanOff() : scanOn()
    }

    function scanOff() {
        process.write("scan off\n")
        process.running = false
        bluetooth_scan = []
    } 

    function scanOn() {
        process.running = true
        process.write("scan on\n")
    } 

    function stripAnsi(str) {
        return str.replace(/\x1b\[[0-9;]*m/g, "").replace(/\x1b\[[0-9;]*[A-Za-z]/g, "")
    }

    Process {
        id: process
        command: ["bluetoothctl"]

        stdout: SplitParser {
            onRead: (line) => {
                line = root.stripAnsi(line)
                if (line.includes("[NEW] Device")) {
                    let bluetooth_scan = root.bluetooth_scan 
                    const parts = line.split(" ")
                    const mac = parts[2]
                    const name = parts.slice(3).join(" ")
                    bluetooth_scan.push({
                        "name": name,
                        "mac": mac
                    })
                    console.log(JSON.stringify(bluetooth_scan, null, 4))
                    root.bluetooth_scan = bluetooth_scan
                }
            }
        }
    }

    Process {
        id: connect_status

        command: ["bluetoothctl", "devices", "Connected"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let connected = root.bluetooth_connected
                    const datas = text.split("\n").slice(0,-1)
                    for (const data of datas) {
                        const section = data.split(" ")
                        const mac = section[1]
                        connected.push(mac)
                    }
                    root.bluetooth_connected = connected
                }
            }
        }
    }

    Process {
        id: save_status

        command: ["bluetoothctl", "devices"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let saved = root.bluetooth_saved
                    const datas = text.split("\n").slice(0,-1)
                    for (const data of datas) {
                        const section = data.split(" ")
                        const mac = section[1]
                        saved.push(mac)
                    }
                    root.bluetooth_saved = saved
                }
            }
        }
    }

    Process {
        id: status
        command: ["bluetoothctl", "power", (root.enabled ? "off" : "on")]
    }

}
