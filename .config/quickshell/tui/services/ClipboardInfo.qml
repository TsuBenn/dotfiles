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

        onRunningChanged: {
            if (!running) {
                console.log("ClipboardInfo: Process closed unexpectedly, restarting...");
                running = true;
            }
        }

        stdout: SplitParser {
            splitMarker: ""
            onRead: {
                reader.reload();
            }
        }
    }

    FileView {
        id: reader
        path: SystemInfo.homedir + "/.cache/clip-watcher/clipboard_history.json"
        onLoaded: {
            root.clipboard = JSON.parse(text());
        }
        // onFileChanged: reload()
    }
}
