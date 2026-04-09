pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property bool enabled: SystemInfo.wifi.enabled
    property var wifi_save: []
    property var wifi_scan: []

    function isScanning() {
        return scanner.running
    }

    function connect(wifi, password = "") {
        if (!wifi.in_use) return -1
        if (!wifi.name) return -1
        if (!wifi.signal) return -1
        if (!wifi.freq) return -1
        if (!wifi.security) return -1

        if (connect.running) return 1

        if (wifi.security == "--") {
            connect.exec(["nmcli", "device", "wifi", "connect", wifi.name])
        } else {
            connect.exec(["nmcli", "device", "wifi", "connect", wifi.name, "password", wifi.password])
        }
    }

    function toggleWifi() {
        if (status.running) return 1
        status.running = true
        return 0
    }

    function scan() {
        if (scanner.running) return 1
        scanner.running = true
        return 0
    }

    Process {
        id: connect
    }

    Process {
        id: status
        command: ["bash", "-c", "nmcli radio wifi " + (root.enabled ? "off" : "on") ]
    }

    Process {
        id: scanner

        command: ["bash", "-c" ,"nmcli -t -f IN-USE,SSID,SIGNAL,FREQ,SECURITY device wifi list --rescan yes"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {

                    let wifi_scan = []

                    const datas = text.split("\n").slice(0, -1)

                    for (const data of datas) {
                        const subdatas = data.split(":")
                        let duplicate = false
                        if (subdatas[1] == "") continue
                        for (const wifi of root.wifi_scan) {
                            if (subdatas[1] == wifi.name) {
                                duplicate = true
                            }
                        }

                        if (duplicate) continue

                        wifi_scan.push({
                            "in_use": subdatas[0] == "*",
                            "name": subdatas[1],
                            "signal": subdatas[2],
                            "freq": (parseInt(subdatas[3],0)/1000).toPrecision(2),
                            "security": subdatas[4],
                        })
                    }

                    root.wifi_scan = wifi_scan

                }
            }
        }

    }
}
