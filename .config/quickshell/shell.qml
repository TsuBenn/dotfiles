pragma ComponentBehavior: Bound 

import qs.services
import qs.modules.common

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    Scope {

        Bar {}

        Item {
            Component.onCompleted: {
                execOnce.exec(["bash", ".config/quickshell/execOnce.sh"])
            }
        }

    }

    Process {
        id: execOnce

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
