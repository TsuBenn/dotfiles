pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string hour: {
        if (raw.length <= 0) {
            return "0"
        }
        if (raw.length > 0 && raw.length == 5) {
            return raw[1]
        } else {
            return 0
        }
    }
    property string minute: {
        if (raw.length <= 0) {
            return "0"
        }
        if (raw.length == 5) {
            return raw[3]
        } else {
            return raw [1]
        }
    }
    property var raw: []

    Process {
        id: getUptime

        command: ["uptime", "-p"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.raw = text.split(" ")
        }
    }

    Timer {

        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            getUptime.running = true
        }

    }
}



