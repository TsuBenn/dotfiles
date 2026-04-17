pragma Singleton

import qs.config

import Quickshell
import QtQuick
import Quickshell.Io

Singleton {

    id: root

    property var all: []

    property var wallpapers: ["detective_hutao.jpeg"]

    property string current: wallpapers[selected]

    property string path: "/dotfiles/Wallpapers/"

    property bool slideshow: false

    property bool scanning: scan.running

    property int selected: 0

    property int slideshowInterval: 10000

    component Type: Item {
        property string type: "wipe"
        property int step: 10
        property real duration: 0.5
        property int fps: 60
        property int angle: 30
        property var pos: [0,0]
        property var wave: [1920/2,1080/2]
    }

    property Type transition: Type {}

    onWallpapersChanged: {
        advance(0)
        set.running = true
    }

    function getIndex(image: string): int {
        for (const i in all) {
            if (all[i] == image) {
                return i
            }
        }
        return 0
    }

    function search(image: string): var {
        return all.filter(item => {
            return item.includes(image)
        })
    }

    function slideshowToggle() {
        slideshow = !slideshow
        if (!slideshow) {
            singlify()
        }
        set.running = true
    }

    function inSet(image: string): bool {
        return wallpapers.includes(image)
    }

    function add(image: string) {
        if (inSet(image)) return
        if (slideshow) {
            wallpapers.push(image)
            return
        }
        wallpapers = [image]
        set.running = true
    }

    function remove(image: string) {
        if (!inSet(image) || !slideshow || wallpapers.length == 1) return
        wallpapers = wallpapers.filter(item => {return item != image})
    }

    function clear() {
        wallpapers = []
    }

    function singlify(image = "") {
        if (!wallpapers) return
        if (image != "" && all.includes(image)) {
            wallpapers = [image]
            return
        }
        wallpapers = [wallpapers[root.selected]]
    }

    function advance(step: int) {
        selected = (selected + wallpapers.length + step)%(wallpapers.length)
        set.running = true
    }

    function set(image) {
        set.exec(["bash", "-c", "awww img --transition-step 90 --transition-fps 60 --transition-type wipe --transition-angle 30 Wallpapers/" + image])
    }

    function minute(min: int): int {
        return min*60000
    }

    function rescan() {
        scan.running = true
    }

    Timer {
        id: timer

        interval: root.slideshowInterval
        running: root.slideshow
        repeat: true
        onTriggered: {
            root.advance(1)
        }
    }

    Process {

        id: scan

        running: true

        command: ["ls", "Wallpapers"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    const data = text.split("\n").slice(0,-1)
                    root.all = data
                }
            }
        }

    }

    Process {

        id: set

        running: true
        command: ["bash", "-c", `awww img --transition-step ${root.transition.step} --transition-duration ${root.transition.duration} --transition-fps ${root.transition.fps} --transition-type ${root.transition.type} --transition-angle ${root.transition.angle} --transition-pos ${root.transition.pos.join(",")} --transition-wave ${root.transition.wave.join(",")} Wallpapers/` + root.current]

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log("WallpaperInfo: " + text)
                }
            }
        }

    }

}
