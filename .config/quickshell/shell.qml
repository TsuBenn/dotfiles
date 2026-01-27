pragma ComponentBehavior: Bound 

import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    Scope {

        Bar {}

        Item {
            Component.onCompleted: {
                execOnce.exec(["bash", ".config/quickshell/execOnce.sh"])
                execOnce.exec(["python", ".config/quickshell/services/backend/launcher.py", "zen"])
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
