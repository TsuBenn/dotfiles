pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var clipboard: []

    property var path: SystemInfo.configdir + "/scripts/clip_watcher.py"

    property var preview: ""

    Process {

        command: ["python", root.path]
        running: true

        stdout: SplitParser {
            splitMarker: ""
            onRead: text => {
                console.log(text);
                let data = JSON.parse(text);
                data.reverse();
                root.clipboard = data;
            }
        }
    }
}
