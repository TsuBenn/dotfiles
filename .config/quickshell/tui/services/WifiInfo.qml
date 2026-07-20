pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    //
    // nmcli connection add type wifi con-name 'connection_name' ifname wlan0 ssid 'ssid' -- 802-1x.eap peap 802-1x.phase2-auth mschapv2 802-1x.identity 'username' 802-1x.password 'password' 802-1x.system-ca-certs no wifi-sec.key-mgmt wpa-eap
    //
    //
    function fmt(str, ...args) {
        return str.replace(/{}/g, () => args.shift());
    }

    property bool enabled: SystemInfo.wifi.enabled
    property string wifi_name: SystemInfo.wifi.name
    property var wifi_save: []
    property var wifi_scan: []
    property bool scanning: scanner.running || connect.running
    property string connectivity: ""

    signal error(text: string)
    signal success(text: string)
    signal info(text: string)
    signal rescanned

    onWifi_nameChanged: {
        scan(false, true);
    }

    function checkConnectivity() {
        if (connectivitiy_check.running)
            return;
        connectivitiy_check.running = true;
    }

    function connect(wifi: string, security, password = "", username = "") {
        if (connect.running)
            return 1;

        connect.wifi = wifi;

        if (security == "" || isSaved(wifi)) {
            connect.exec(["nmcli", "device", "wifi", "connect", wifi]);
        } else if (security == "WPA2 802.1X") {
            connect.exec(["bash", "-c", root.fmt("nmcli connection add type wifi con-name {} ifname wlan0 ssid {} -- 802-1x.eap peap 802-1x.phase2-auth mschapv2 802-1x.identity {} 802-1x.password {} 802-1x.system-ca-certs no wifi-sec.key-mgmt wpa-eap && nmcli connection up {}", wifi, wifi, username, password, wifi)]);
        } else {
            connect.exec(["nmcli", "device", "wifi", "connect", wifi, "password", password]);
        }
    }

    function disconnect(wifi: string, password = "") {
        if (connect.running)
            return 1;
        if (forget.running)
            return 1;

        connect.wifi = "";

        forget.exec(["nmcli", "connection", "down", wifi]);
    }

    function isSaved(wifi: string): bool {
        return wifi_save.includes(wifi);
    }

    function toggle() {
        if (status.running)
            return 1;
        status.running = true;
        return 0;
    }

    function scan(rescan = false, force = false) {
        if (scanner.running && !force)
            return 1;
        scanner.rescan = rescan;
        scanner.running = true;
        return 0;
    }

    function forget(wifi: string) {
        forget.exec(["nmcli", "connection", "delete", wifi]);
    }

    Process {
        id: connect

        property string wifi

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log(text);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (!text) {
                    root.success(`Connected to ${connect.wifi}`);
                    root.checkConnectivity();
                    root.scan();
                    return;
                }
                root.error(`Failed to connect to ${connect.wifi}`);
                root.forget(connect.wifi);
            }
        }
    }

    Process {
        id: forget
        stdout: StdioCollector {
            onStreamFinished: {
                root.checkConnectivity();
                root.scan();
            }
        }
    }

    Process {
        id: status
        command: ["bash", "-c", "nmcli radio wifi " + (root.enabled ? "off" : "on")]
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("WifiInfo: turned " + (root.enabled ? "off" : "on"));
            }
        }
    }

    Process {
        id: connectivitiy_check

        running: true
        command: ["bash", "-c", "nmcli networking connectivity check"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.connectivity = text.trim();
                }
            }
        }
    }

    Process {
        id: saved

        running: true
        command: ["bash", "-c", "nmcli -t -f NAME connection show"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    const wifi_save = text.split("\n").slice(0, -1);

                    root.wifi_save = wifi_save;
                }
            }
        }
    }

    Process {
        id: scanner

        property bool rescan: false

        command: ["bash", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,FREQ,SECURITY device wifi list" + (rescan ? " --rescan yes" : "")]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let wifi_scan = [];

                    const datas = text.split("\n").slice(0, -1);

                    for (const data of datas) {
                        const subdatas = data.split(":");
                        let duplicate = false;
                        if (subdatas[1] == "")
                            continue;
                        for (const wifi of wifi_scan) {
                            if (subdatas[1].trim() == wifi.name.trim()) {
                                duplicate = true;
                            }
                        }

                        if (duplicate)
                            continue;
                        if (subdatas[0] == "*") {
                            wifi_scan.unshift({
                                "in_use": true,
                                "name": subdatas[1].trim(),
                                "signal": subdatas[2],
                                "freq": (parseInt(subdatas[3], 0) / 1000).toPrecision(2),
                                "security": subdatas[4]
                            });
                        } else {
                            wifi_scan.push({
                                "in_use": false,
                                "name": subdatas[1].trim(),
                                "signal": subdatas[2],
                                "freq": (parseInt(subdatas[3], 0) / 1000).toPrecision(2),
                                "security": subdatas[4]
                            });
                        }
                    }

                    saved.running = true;
                    root.wifi_scan = wifi_scan;
                    root.rescanned();
                    root.checkConnectivity();
                    console.log("WifiInfo: scanned!");
                }
            }
        }
    }
}
