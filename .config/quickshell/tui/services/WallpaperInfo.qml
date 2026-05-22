pragma Singleton

import qs.config
import qs.services

import Quickshell
import QtQuick
import Quickshell.Io

Singleton {

    id: root

    property var all: []
    property var caches: []

    property var wallpapers: ["detective_hutao.jpeg"]

    property string current: wallpapers[selected]

    property string path: "/Wallpapers/"
    property string cache_path: "/Wallpapers/.qscache/"

    property bool slideshow: false

    property bool scanning: scan.running

    property int selected: 0

    property int slideshowInterval: 10000

    signal rescanned()

    component Type: Item {
        property string type: "wipe"
        property int step: 10
        property real duration: 0.5
        property int fps: 60
        property int angle: 30
        property var pos: [0,0]
    }

    property Type transition: Type {}

    onTransitionChanged: {
        saveConfig()
    }

    onWallpapersChanged: {
        saveConfig()
        advance(0)
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
        singlify(image)
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
    }

    function set(image) {

    }

    function minute(min: int): int {
        return min*60000
    }

    function rescan() {

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
        command: ["ls", SystemInfo.homedir + root.path]

        stdout: StdioCollector {
            onStreamFinished: {

                const data = text.split("\n").filter(item => item != "")

                let all = []

                for (const wallpaper of data ) {
                    if (/.*\.mp4$/.test(wallpaper)) {
                        all.push({
                            "name": wallpaper,
                            "type": "live",
                        })
                        continue
                    }
                    all.push({
                        "name": wallpaper,
                        "type": "still",
                    })
                }

                console.log(JSON.stringify(all,null,2))

            }
        }

    }

    function saveConfig() {

        let config = {
            transition: {
                "type"     : root.transition.type,
                "step"     : root.transition.step,
                "duration" : root.transition.duration,
                "fps"      : root.transition.fps,
                "angle"    : root.transition.angle,
                "pos"      : root.transition.pos,
            },
            wallpapers: root.wallpapers
        }

        SystemInfo.runDetached(["bash", "-c", "echo '" + JSON.stringify(config) + "' > " + SystemInfo.configdir + "/scripts/wallpapers_config.json"])
    }

    FileView {

        id: loader

        path: SystemInfo.configdir + "/scripts/wallpapers_config.json"

        onLoaded: {
            const data = JSON.parse(text())

            root.transition.type     = data.transition.type     ?? root.transition.type    
            root.transition.step     = data.transition.step     ?? root.transition.step    
            root.transition.duration = data.transition.duration ?? root.transition.duration
            root.transition.fps      = data.transition.fps      ?? root.transition.fps     
            root.transition.angle    = data.transition.angle    ?? root.transition.angle   
            root.transition.pos      = data.transition.pos      ?? root.transition.pos     

            root.wallpapers = data.wallpapers

            set.running = true

        }

    }

}
