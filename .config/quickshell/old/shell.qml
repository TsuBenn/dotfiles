pragma ComponentBehavior: Bound 

import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    Scope {

        Bar {}

        Item {
            Component.onCompleted: {
                execOnce.exec(["bash", ".config/quickshell/old/execOnce.sh"])
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
