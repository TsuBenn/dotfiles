pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property var clipboard: []

    property string path: SystemInfo.configdir + "/scripts/clipboard_cache.png"

    property string preview: ""

    signal image()

    function decode(index: int) {
        SystemInfo.runDetached(["bash", "-c", "clipvault get --index " + index + " | wl-copy"])
    }

    function paste() {
    }

    function load(object: var, index: int) {
        load.id = index
        if (object.label.startsWith("[[ binary data")) {
            load.binary = true
        } else {
            load.binary = false
        }

        load.running = true
    }

    function reload() {
        fetch.running = true
    }

    Process {

        id: fetch

        running: true
        command: ["clipvault", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    // 1. Split the massive string block into an array of individual lines
                    const lines = text.trim().split("\n");

                    // 2. Loop through and parse each line
                    const parsedClipboard = lines.map(line => {
                        const match = line.trim().match(/^(\d+)\s+(.*)$/);

                        if (match) {
                            return {
                                id: match[1],
                                label: match[2]
                            };
                        }
                        return null; 
                    }).filter(item => item !== null);

                    root.clipboard = parsedClipboard
                }
            }
        }

    }

    Process {

        id: cacher

        command: ["bash", "-c", "clipvault get --index " + load.id + " > " + root.path]

        stdout: StdioCollector {
            onStreamFinished: {
                root.image()
            }
        }

    }

    Process {

        id: load

        property int id: 0
        property bool binary: false

        command: ["bash", "-c", "clipvault get --index " + id]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    if (load.binary) {
                        root.preview = "{image_header_23042005}" + root.path
                        cacher.running = true
                    } else {
                        root.preview = text
                    }
                }
            }
        }

    }

}
