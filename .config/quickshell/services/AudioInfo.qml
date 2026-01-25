pragma Singleton 

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real volume
    property bool mute
    property real mic

    property var sinks
    property int sinkDefault
    property var sources
    property int sourceDefault

    signal statusUpdated()

    function switchDefault(id: int) {
        setstatus.exec(["bash","-c","wpctl set-default " + id])
        timer.restart()
    }

    function setVolume(id: int, percentage: real) {

        setstatus.exec(["bash","-c","wpctl set-volume " + id + " " + percentage + "%"])

        console.log(Math.min(Math.max(percentage, 0), 100))

        timer.restart()
        if (id == sinkDefault) volume = percentage
        if (id == sourceDefault) mic = percentage
    }

    function muteVolume(id: int) {
        if (mute) {
            setstatus.exec(["bash","-c","wpctl set-mute " + id + " 0"]) 
            mute = false
        }
        else if (!mute) {
            setstatus.exec(["bash","-c","wpctl set-mute " + id + " 1"])
            mute = true
        }
        timer.restart()
    }

    function playSound(file: string, vol: real) {
        playsound.exec(["bash","-c","paplay --volume="+ 65536*vol + " -d @DEFAULT_SINK@ .config/quickshell/assets/sfx/" + file + ".mp3"])
    }

    function getName(id: int): string {
        if (!sinks || !sources) {
            console.error("getName can't fetch Device")
            return
        }

        for (const sink of sinks) {
            if (sink.id == id) {
                return sink.name
            }
        }
        for (const source of sources) {
            if (source.id == id) {
                return source.name
            }
        }
        return "None"
    }

    function getVolume(id: int): real {
        if (!sinks || !sources) {
            console.error("getVolume can't fetch Device")
            return
        }
        for (const sink of sinks) {
            if (sink.id == id) {
                return sink.vol
            }
        }
        for (const source of sources) {
            if (source.id == id) {
                return source.vol
            }
        }
        return "0"
    }

    Timer {

        id: timer

        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            status.running = true
        }
    }

    Process {
        id: setstatus
    }
    Process {
        id: playsound
    }

    Process {
        id: status

        command: ["bash", "-c", "wpctl status"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let rawsinks = text.match(/^.*Sinks:([\s\S]*?)\n.*Sources:/m)[1].split("\n")
                let rawsources = text.match(/^.*Sources:([\s\S]*?)\n.*Filters:/m)[1].split("\n")

                let sinks = []
                let sources = []

                for (const sink of rawsinks) {
                    let data = sink.match(/.(\d+)\.\s+(.*)\[vol: (.*)\s+(.*)\]/) ?? sink.match(/.(\d+)\.\s+(.*)\[vol: (.*)\]/)
                    let defaultdata = sink.match(/.\*\s+(\d+)\.\s+.*\[/)
                    if (data) {
                        sinks.push({"id": parseInt(data[1],10), "name": data[2], "vol": parseFloat(data[3])})
                        if (defaultdata) {
                            root.sinkDefault = parseInt(defaultdata[1],10)
                            root.volume = parseFloat(data[3])*100
                            root.mute = data[4] ?? 0
                        }
                    }
                    //console.log(root.mute)
                }

                for (const source of rawsources) {
                    let data = source.match(/.(\d+)\.\s+(.*)\[vol: (.*)\]/)
                    let defaultdata = source.match(/.\*\s+(\d+)\.\s+.*\[/)
                    if (data) {
                        sources.push({"id": parseInt(data[1],10), "name": data[2], "vol": parseFloat(data[3])})
                        if (defaultdata) {
                            root.sourceDefault = parseInt(defaultdata[1],10)
                            root.mic = parseFloat(data[3])*100
                        }
                    }
                }

                if (sources.length == root.sources?.length && root.sources.length > 0) {
                    for (const i in sources) {
                        const key = Object.keys(sources[i])[0]
                        if (sources[i][key] == root.sources[i][key]) {
                            continue
                        }
                        root.sources = sources
                        break
                    }
                } else {
                    root.sources = sources
                }

                if (sinks.length == root.sinks?.length && root.sinks.length > 0) {
                    for (const i in sinks) {
                        const key = Object.keys(sources[i])[0]
                        if (sinks[i][key] == root.sinks[i][key]) {
                            continue
                        }
                        root.sinks = sinks
                        break
                    }
                } else {
                    root.sinks = sinks
                }

                root.statusUpdated()
            }
        }

    }

}

