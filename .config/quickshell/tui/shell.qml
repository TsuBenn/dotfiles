pragma ComponentBehavior: Bound

import qs.config
import qs.components.bar
import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {

    Item {
        Component.onCompleted: {
            Colors.applied.connect(() => {
                init()
            })
        }

        function init() {
            const active_border = "0xff" + Colors.borderActive.toString().slice(1)
            const inactive_border = "0xff" + Colors.borderInactive.toString().slice(1)
            process.exec(["bash", SystemInfo.homedir + "/dotfiles/.config/quickshell/tui/scripts/init.sh", active_border, inactive_border])
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

