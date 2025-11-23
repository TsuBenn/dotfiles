pragma Singleton 

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property list<int> points: []
    property int framerate: 60
    property int bars: 40

    property int activeUser: 0

    function requestStart() {
        activeUser += 1
        if (activeUser === 1) process.running = true 
    }

    function release() {
        activeUser -= 1
        if (activeUser === 0) process.running = false 
    }

    Process {

        id: process

        running: true
        command: ["bash", "-c", `cava -p <(echo "
[general]
framerate = ${root.framerate}                                                       
bars = ${root.bars}                             
autosens = 1

[smoothing]
monstercat = 1
gravity = 1

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bit_format = 16bit")`]

        stdout: SplitParser {
            onRead: (data) => {
                root.points = data.split(";").slice(0,root.bars)
            }
        }

    }

}

