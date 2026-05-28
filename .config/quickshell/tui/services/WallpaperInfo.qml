pragma Singleton

import qs.config
import qs.services

import Quickshell
import QtQuick
import Quickshell.Io

Singleton {

    id: root

    property var all: []

    property var wallpapers: []

    property string current: wallpapers[selected]

    property string path: "/Wallpapers/"
    property string cache_path: "/Wallpapers/.qscache/"
    property string cache_prefix: "_thumb.jpg"
    property string still_prefix: "_still.png"

    property bool slideshow: false

    property bool live: false

    property bool scanning: scan.running

    property int selected: 0

    property int slideshowInterval: 10000

    property bool loaded: false

    signal rescanned()

    onConfigChanged: {
        saveConfig()
    }

    function setConfig(imageName, propertyPath, value) {
        var currentConfig = root.config || {};

        if (!currentConfig[imageName]) {
            currentConfig[imageName] = {};
        }

        var fileConfig = currentConfig[imageName];
        var parts = propertyPath.split('.');

        if (parts.length === 1) {
            // Direct assignment (e.g., "transition")
            var key = parts[0];
            fileConfig[key] = value;
        } else if (parts.length === 2) {
            // Nested assignment (e.g., "reposition.scalar")
            var parentKey = parts[0]; // "reposition" or "transition"
            var childKey = parts[1];  // "scalar", "type", etc.

            // If the parent doesn't exist, initialize it with your defaults
            if (!fileConfig[parentKey]) {
                if (parentKey === "reposition") {
                    fileConfig["reposition"] = {
                        "scalar": 1,
                        "verticalOffset": 0,
                        "horizontalOffset": 0
                    };
                } else if (parentKey === "transition") {
                    fileConfig["transition"] = {
                        "type": transition.type,
                        "step": transition.step,
                        "duration": transition.duration,
                        "fps": transition.fps,
                        "posX": transition.posX,
                        "posY": transition.posY
                    };
                } else {
                    // Fallback for any other unexpected nested objects
                    fileConfig[parentKey] = {};
                }
            }

            // Now safely overwrite the specific target property
            fileConfig[parentKey][childKey] = value;
        }

        // Force QML to update reactive bindings
        root.config = currentConfig;
        saveConfig()
        configChanged()
    }

    component Type: Item {
        property string type: "wipe"
        property int step: 10
        property real duration: 0.5
        property int fps: 60
        property int angle: 30
        property real posX: 0
        property real posY: 0
    }

    property var config: {
        "macbook.jpg": {
            "reposition": {
                "scalar": 1,
                "verticalOffset": 1,
                "horizontalOffset": 0,
            },
            "transition": {
                "type": "grow",
                "step": 1,
                "duration": 1,
                "fps": 60,
                "posX": 0,
                "posY": 0,
            }
        }
    }

    function getTransition(image: string): var {
        return {
            "type"     : config[image]?.transition?.type     ?? transition.type,
            "step"     : config[image]?.transition?.step     ?? transition.step,
            "duration" : config[image]?.transition?.duration ?? transition.duration,
            "fps"      : config[image]?.transition?.fps      ?? transition.fps,
            "angle"    : config[image]?.transition?.angle    ?? transition.angle,
            "posX"     : config[image]?.transition?.posX     ?? transition.posX,
            "posY"     : config[image]?.transition?.posY     ?? transition.posY,
        }
    }

    function getReposition(image: string): var {
        return {
            "scalar"           : config[image]?.reposition?.scalar           ?? 1,
            "verticalOffset"   : config[image]?.reposition?.verticalOffset   ?? 0,
            "horizontalOffset" : config[image]?.reposition?.horizontalOffset ?? 0,
        }
    }

    onLiveChanged: {
        root.saveConfig()
    }

    property Type transition: Type {

        onTypeChanged: {
            root.saveConfig()
        }
        onStepChanged: {
            root.saveConfig()
        }
        onDurationChanged: {
            root.saveConfig()
        }
        onFpsChanged: {
            root.saveConfig()
        }
        onAngleChanged: {
            root.saveConfig()
        }
        onPosXChanged: {
            root.saveConfig()
        }
        onPosYChanged: {
            root.saveConfig()
        }

    }


    onWallpapersChanged: {
        saveConfig()
        advance(0)
        currentChanged()
    }

    function isLive(image: string): bool {
        return /\.mp4$|\.mp4_thumb\.jpg$/.test(image)
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
            item = item.toLowerCase().replace(/\s+/g,"").replace(/_/g,"")
            image = image.toLowerCase().replace(/\s+/g,"").replace(/_/g,"")
            //console.log(item)
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
        if (wallpapers.length > 1) selected = (selected + wallpapers.length + step)%(wallpapers.length)
        else selected = 0
    }

    function set(image) {

    }

    function minute(min: int): int {
        return min*60000
    }

    function rescan() {
        cacher.recache = true
        cacher.running = true
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

        id: cacher

        property bool recache: false

        Component.onCompleted: {
            SystemInfo.cputhreadsChanged.connect(()=> {
                if (SystemInfo.cputhreads > 0) {
                    cacher.running = true
                }
            })
        }

        command: [SystemInfo.configdir + "/scripts/wallpapers_cacher.sh", SystemInfo.homedir + root.path, SystemInfo.cputhreads, recache ? "--force" : ""]

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
                cacher.recache = false
                scan.running = true
                root.rescanned()
            }
        }

    }

    Process {

        id: scan

        command: ["ls", SystemInfo.homedir + root.path]

        stdout: StdioCollector {
            onStreamFinished: {

                const data = text.split("\n").filter(item => item != "")
                root.all = data

            }
        }

    }

    function saveConfig() {

        if (!root.loaded) return

        let originalConfig = root.config;
        let filteredConfig = {};

        for (let fileName in originalConfig) {
            if (originalConfig.hasOwnProperty(fileName)) {
                let fileConfig = originalConfig[fileName];
                let newFileConfig = {};

                // Loop through internal properties ("reposition", "transition", etc.)
                for (let prop in fileConfig) {
                    if (fileConfig.hasOwnProperty(prop)) {
                        if (prop === "reposition") {
                            let repo = fileConfig.reposition;
                            // Check if it's the specific "default" reposition we want to strip out
                            if (repo.scalar === 1 && repo.verticalOffset === 0 && repo.horizontalOffset === 0) {
                                continue; // Skip adding this default reposition block
                            }
                        }

                        // Keep the property if it passed the check above
                        newFileConfig[prop] = fileConfig[prop];
                    }
                }

                // QML Check: Count how many keys are actually inside our new inner object
                var remainingKeysCount = Object.keys(newFileConfig).length;

                // Only add the file to our main config if it actually has data left
                if (remainingKeysCount > 0) {
                    filteredConfig[fileName] = newFileConfig;
                }
            }
        }

        let config = {
            transition: {
                "type"     : root.transition.type,
                "step"     : root.transition.step,
                "duration" : root.transition.duration,
                "fps"      : root.transition.fps,
                "angle"    : root.transition.angle,
                "posX"      : root.transition.posX,
                "posY"      : root.transition.posY,
            },
            wallpapers: root.wallpapers,
            config: filteredConfig,
            live: root.live
        }

        SystemInfo.runDetached(["bash", "-c", "echo '" + JSON.stringify(config,null,2) + "' > " + SystemInfo.configdir + "/scripts/wallpapers_config.json"])

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
            root.transition.posX      = data.transition.posX      ?? root.transition.posX
            root.transition.posY      = data.transition.posY      ?? root.transition.posY

            root.wallpapers = data.wallpapers ?? []
            root.config = data.config ?? ({})

            root.live = data.live

            root.loaded = true

        }

    }

}

