pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string location: "Saigon"
    property string temperature: "NA"
    property string condition: "..."
    property string condition_icon: "🌦" 

    Timer {
        id: timer
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            weather.running = true
        }
    }

    Process {
        id: weather
        command: ["curl", "www.wttr.in/?format='%t;%C;%c;%l'"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    const raw_data = this.text.split(";")
                    root.temperature = raw_data[0].trim().match(/([0-9]+)/)[1]
                    root.condition = raw_data[1].trim()
                    root.condition_icon = raw_data[2].trim().match(/([\S]+)/)[1].trim()
                    root.location = raw_data[3].split(",")[0]
                    if (raw_data && timer.interval!=60000) {timer.interval=60000; console.log("Loaded Weather Info from " + raw_data[3].split(",")[0].trim() + "!" + root.condition_icon)}
                }
            }
        }
    }

}

