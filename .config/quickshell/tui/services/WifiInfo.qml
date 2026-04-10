pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property bool enabled: SystemInfo.wifi.enabled
    property string wifi_name: SystemInfo.wifi.name
    property var wifi_save: []
    property var wifi_scan: []
    property bool scanning: scanner.running || connect.running 

    onWifi_nameChanged: {
        scan()
    }

    function connect(wifi: string, password = "") {
        if (connect.running) return 1

        if (password == "") {
            connect.exec(["nmcli", "device", "wifi", "connect", wifi])
        } else {
            connect.exec(["nmcli", "device", "wifi", "connect", wifi, "password", password])
        }
    }

    function isSaved(wifi: string): bool {
        return wifi_save.includes(wifi)
    }

    function toggleWifi() {
        if (status.running) return 1
        status.running = true
        return 0
    }

    function scan(rescan = false) {
        if (scanner.running) return 1
        scanner.rescan = rescan
        scanner.running = true
        return 0
    }

    Process {
        id: connect
        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
            }
        }
    }

    Process {
        id: status
        command: ["bash", "-c", "nmcli radio wifi " + (root.enabled ? "off" : "on") ]
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("WifiInfo: turned " + (root.enabled ? "off" : "on"))
            }
        }
    }

    Process {
        id: saved

        running: true
        command: ["bash", "-c" ,"nmcli -t -f NAME connection show"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {

                    const wifi_save = text.split("\n").slice(0, -1)

                    root.wifi_save = wifi_save

                }
            }
        }

    }

    Process {
        id: scanner

        property bool rescan

        running: true
        command: ["bash", "-c" ,"nmcli -t -f IN-USE,SSID,SIGNAL,FREQ,SECURITY device wifi list" + (rescan ? " --rescan yes" : "")]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {

                    let wifi_scan = []

                    const datas = text.split("\n").slice(0, -1)

                    for (const data of datas) {
                        const subdatas = data.split(":")
                        let duplicate = false
                        if (subdatas[1] == "") continue
                        for (const wifi of wifi_scan) {
                            if (subdatas[1].trim() == wifi.name.trim()) {
                                duplicate = true
                            }
                        }

                        if (duplicate) continue

                        if (subdatas[0] == "*") {
                            wifi_scan.unshift({
                                "in_use": true,
                                "name": subdatas[1].trim(),
                                "signal": subdatas[2],
                                "freq": (parseInt(subdatas[3],0)/1000).toPrecision(2),
                                "security": subdatas[4],
                            })
                        } else {
                            wifi_scan.push({
                                "in_use": false,
                                "name": subdatas[1].trim(),
                                "signal": subdatas[2],
                                "freq": (parseInt(subdatas[3],0)/1000).toPrecision(2),
                                "security": subdatas[4],
                            })
                        }
                    }

                    saved.running = true
                    root.wifi_scan = wifi_scan
                }
            }
        }

    }
}
