pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property var clipboard: []

    function paste() {
        ze_paste.running = true
    }

    Process {
        id: ze_paste
        command: ["bash", "-c", "wtype $(wl-paste)"]
    }

}
