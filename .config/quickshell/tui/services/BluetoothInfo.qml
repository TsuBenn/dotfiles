pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property var bluetooth_connected: []
    property var bluetooth_paired: []
    property var bluetooth_scan: []

    signal error(info: string)
    signal success(info: string)
    signal info(info: string)
    signal agent(info: string, mac: string)

    property bool refreshing: connect.running || unpair.running || status.running

    property bool enabled: SystemInfo.bluetooth.enabled

    property bool scanning: process.running

    function send(text: string) {
        process.write(text + "\n")
    }

    function jsonify(name) {
        return JSON.stringify(name, null, 4)
    }

    function isNamedDevice(name) {
        return !/^([0-9A-F]{2}-){5}[0-9A-F]{2}$/i.test(name)
    }

    function toggle() {
        if (status.running) return 1
        status.running = true
        return 0
    } 

    function isSaved(mac: string): bool {
        return bluetooth_paired.some(obj => obj.mac === mac)
    }

    function isConnected(mac: string): bool {
        return bluetooth_connected.some(obj => obj.mac === mac)
    }

    function refresh() {
        pair_status.running = true
        connect_status.running = true
    }

    function scanToggle() {
        refresh()
        scanning ? scanOff() : scanOn()
    }

    function scanOff() {
        process.write("scan off\n")
        process.running = false
        bluetooth_scan = []
        console.log("BluetoothInfo: Scan off!")
    } 

    function scanOn() {
        process.running = true
        process.write("scan on\n")
        console.log("BluetoothInfo: Scan on!")
    } 

    function stripAnsi(str) {
        return str.replace(/\x1b\[[0-9;]*m/g, "").replace(/\x1b\[[0-9;]*[A-Za-z]/g, "")
    }

    function disconnect(mac: string) {
        connect.mac = mac
        connect.exec(["bluetoothctl", "disconnect", mac])
    }

    function connect(mac: string) {
        connect.mac = mac
        connect.exec(["bluetoothctl", "connect", mac])
    }

    function unpair(mac: string) {
        connect.mac = mac
        connect.exec(["bluetoothctl", "remove", mac])
    }

    Process {

        id: connect

        property string mac: ""

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
                if (text.includes("Failed")) {
                    root.error("Failed to connect to " + connect.mac)
                } else if (text.includes("Connection successful")) {
                    root.success("Connected to " + connect.mac)
                } else if (text.includes("Disconnection successful")) {
                    root.success("Disconnected from " + connect.mac)
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                connect.mac = ""
            }
        }

    }

    Process {
        id: process
        command: ["bluetoothctl"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: (line) => {
                line = root.stripAnsi(line)
                if (line.includes("[agent]")) {
                    root.agent(line.match(/\[agent\]\s+Confirm passkey\s+(\d+)\s+\(yes\/no\):/)[1],connect.mac)
                    return
                }
                scanner.running = true
            }
        }
    }

    Process {
        id: scanner

        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    if (!text.startsWith("Device")) return
                    let scan = []
                    const datas = text.split("\n").slice(0,-1)
                    for (const data of datas) {
                        if (!data.startsWith("Device")) return
                        const section = data.split(" ")
                        const mac = section[1]
                        const name = section.slice(2).join(" ")
                        if (root.isNamedDevice(name)) {
                            scan.push({
                                "mac": mac,
                                "name": name,
                            })
                        }
                    }
                    root.bluetooth_scan = scan.filter((device)=>{
                        return !root.isSaved(device.mac)
                    })
                    root.refresh()
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
                    if (!text.startsWith("Device")) return
                    let connected = []
                    const datas = text.split("\n").slice(0,-1)
                    for (const data of datas) {
                        if (!data.startsWith("Device")) return
                        const section = data.split(" ")
                        const mac = section[1]
                        const name = section.slice(2).join(" ")
                        if (root.isNamedDevice(name)) {
                            connected.push({
                                "mac": mac,
                                "name": name,
                            })
                        }
                    }
                    root.bluetooth_connected = connected
                } else {
                    root.bluetooth_connected = []
                }

            }
        }
    }

    Process {
        id: pair_status

        command: ["bluetoothctl", "devices", "Paired"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    if (!text.startsWith("Device")) return
                    let paired = []
                    const datas = text.split("\n").slice(0,-1)
                    for (const data of datas) {
                        if (!data.startsWith("Device")) return
                        const section = data.split(" ")
                        const mac = section[1]
                        const name = section.slice(2).join(" ")
                        if (root.isNamedDevice(name)) {
                            paired.push({
                                "mac": mac,
                                "name": name,
                            })
                        }
                    }
                    root.bluetooth_paired = paired
                } else {
                    root.bluetooth_paired = []
                }
            }
        }
    }

    Process {
        id: status
        command: ["bluetoothctl", "power", (root.enabled ? "off" : "on")]
    }

}
