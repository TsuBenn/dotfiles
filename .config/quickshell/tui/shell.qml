pragma ComponentBehavior: Bound

import qs.config
import qs.components.bar

import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {

    Item {
        Component.onCompleted: {
            const active_border = "0xff" + Colors.accentStrong.toString().slice(1)
            const inactive_border = "0xff" + Colors.fgSubtle.toString().slice(1)
            process.exec(["bash", ".config/quickshell/tui/scripts/init.sh", active_border, inactive_border])
        }
    }

    Bar {}

    Process {
        id: process 

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) console.error(text)
            }
        }
    }
}

