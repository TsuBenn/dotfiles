pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property bool available: false

    property int brightness: 100

    function get() {
        process.running = true
    }

    function set(percent) {
        process.exec(["brightnessctl", "set", percent + "%"])
    }

    Process {
        id: process
        command: ["brightnessctl"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {

                    const data = text.match(/.*\((.*)%\).*/)[1]

                    root.brightness = data

                }
            }
        }
    }

    Process {
        id: availability
        command: ["brightnessctl", "-l"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    if (text.includes("backlight")) {
                        root.available = true
                    }
                }
            }
        }
    }

}
