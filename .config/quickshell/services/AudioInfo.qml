pragma Singleton 

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real volume
    property bool mute
    property real mic

    property string raw
    property var sinks
    property int sinkDefault
    property var sources
    property int sourceDefault

    property var streams
    property string streamraw 

    signal statusUpdated()

    function switchDefault(id: int) {
        setstatus.exec(["bash","-c","wpctl set-default " + id])
        timer.restart()
    }

    function setVolume(id: int, percentage: real) {

        setstatus.exec(["bash","-c","wpctl set-volume " + id + " " + percentage + "%"])

        //console.log(Math.min(Math.max(percentage, 0), 100))

        timer.restart()
        if (id == sinkDefault) volume = percentage
        if (id == sourceDefault) mic = percentage
        for (const i in streams) {
            if (id == streams[i].id) {
                streams[i].volume = percentage
            }
        }
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
            mixerstatus.running = true
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

        command: ["bash", "-c", "wpctl status -k"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.raw == text) return
                let rawsinks = text.match(/^.*Sinks:([\s\S]*?)\n.*Sources:/m)[1].split("\n")
                let rawsources = text.match(/^.*Sources:([\s\S]*?)\n.*Filters:/m)[1].split("\n")
                let rawfilters = text.match(/^.*Filters:([\s\S]*?)\n.*Streams:/m)[1].split("\n")

                //console.log(rawfilters)

                let sinks = []
                let sources = []
                let filters = []

                // Filters for Sinks
                for (const filter of rawfilters) {
                    let data = filter.match(/.(\d+)\.\s+(.*)\[Audio\/Sink]/) ?? filter.match(/.(\d+)\.\s+(.*)\[Audio\/Sink]/)
                    let defaultdata = filter.match(/.\*\s+(\d+)\.\s+.*\[/)
                    if (data) {
                        filters.push({"id": parseInt(data[1],10), "name": data[2].trim(), "default": defaultdata ? 1 : 0 })
                        if (defaultdata) {
                            root.sinkDefault = parseInt(defaultdata[1],10)
                        }
                    }
                }

                for (const sink of rawsinks) {
                    let data = sink.match(/.(\d+)\.\s+(.*)\[vol: (.*)\s+(.*)\]/) ?? sink.match(/.(\d+)\.\s+(.*)\[vol: (.*)\]/)
                    let defaultdata = sink.match(/.\*\s+(\d+)\.\s+.*\[/)
                    if (data) {
                        var id = parseInt(data[1],10)
                        if (defaultdata) {
                            root.sinkDefault = parseInt(defaultdata[1],10)
                            root.volume = parseFloat(data[3])*100
                            root.mute = data[4] ?? 0
                        } else {
                            for (const i in filters) {
                                if (filters[i].name.trim() == data[2].trim()) {
                                    id = filters[i].id
                                    if (filters[i].default == 1) {
                                        root.volume = parseFloat(data[3])*100
                                        root.mute = data[4] ?? 0
                                    }
                                }
                            }
                        }
                        sinks.push({"id": id, "name": data[2].trim(), "vol": parseFloat(data[3])})
                    }
                }

                for (const source of rawsources) {
                    let data = source.match(/.(\d+)\.\s+(.*)\[vol: (.*)\]/)
                    let defaultdata = source.match(/.\*\s+(\d+)\.\s+.*\[/)
                    if (data) {
                        sources.push({"id": parseInt(data[1],10), "name": data[2].trim(), "vol": parseFloat(data[3])})
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
                        const key = Object.keys(sinks[i])[0]
                        if (sinks[i][key] == root.sinks[i][key]) {
                            continue
                        }
                        root.sinks = sinks
                        break
                    }
                } else {
                    root.sinks = sinks
                }

                root.raw = text
                root.statusUpdated()
            }
        }

    }

    Process {
        id: mixerstatus

        command: ["bash", "-c", "pactl list sink-inputs"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.streamraw == text) return
                const datas = text.match(/^Sink Input #\d+(?:\n(?!Sink Input #).*)*/gm)

                var streams = []

                for (const data of datas) {
                    const app = data.match(/\application.name\s+=\s+"(.*)"/)[1]
                    const name = JSON.parse(`"${data.match(/\media.name\s+=\s+"(.*)"/)[1]}"`)
                    const binary = JSON.parse(`"${data.match(/\application.process.binary\s+=\s+"(.*)"/)[1]}"`)
                    const volume = parseInt(data.match(/Volume:.*?\/\s*(\d+)%/)[1])
                    const id = parseInt(data.match(/\object.id\s+=\s+"(.*)"/)[1])

                    switch (app.trim()) {
                    }
                    switch (name.trim()) {
                        case ".config/quickshell/assets/sfx/mambo.mp3": continue
                        case ".config/quickshell/assets/sfx/mambo_tongye.mp3": continue
                        case ".config/quickshell/assets/sfx/mambo_wow.mp3": continue
                    }

                    streams.push({"id": id, "volume": volume, "app": app, "name": name, "binary": binary})

                }

                root.streams = streams
                root.streamraw = text
            }
        }

    }

}

