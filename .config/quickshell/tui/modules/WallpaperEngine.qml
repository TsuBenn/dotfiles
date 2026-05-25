import qs.config
import qs.modules
import qs.services

import QtQuick
import QtMultimedia

Item {

    id: root

    property var monitor: {
        "width": 1920,
        "height": 1080
    }

    property string current: WallpaperInfo.current
    property bool isLive: WallpaperInfo.isLive(WallpaperInfo.current)
    property bool live: WallpaperInfo.live && isLive

    property string shaders_path: SystemInfo.configdir + "/scripts/wallpaperShaders/"
    property string shaders_ext: ".frag.qsb"

    property string transition_type: {
        switch (WallpaperInfo.transition.type) {
            case "none": return "none"
            case "simple": return "fade"
            case "wipe": return "wipe"
            case "grow": return "grow"
            case "shrink": return "shrink"
            case "ripple": return "ripple"
            default: return "fade"
        }
    }

    onLiveChanged: {
        if (root.live) {
            live.source = SystemInfo.homedir + WallpaperInfo.path + root.current
            live.play()
        } else {
            live.pause()
        }
    }

    onCurrentChanged: {
        live.pause()
        root.grabBuffer()
    }

    function grabBuffer() {
        root.grabToImage(function(result) {
            buffer.source = result.url
            still.source = root.isLive ? SystemInfo.homedir + WallpaperInfo.cache_path + root.current + WallpaperInfo.still_prefix : SystemInfo.homedir + WallpaperInfo.path + root.current
            //fadeAnim.restart()
        })
    }

    Item {

        anchors.fill: parent

        id: main
        visible: false

        Image {

            id: still

            anchors.fill: parent

            source: root.isLive ? SystemInfo.homedir + WallpaperInfo.cache_path + root.current + WallpaperInfo.still_prefix : SystemInfo.homedir + WallpaperInfo.path + root.current

            fillMode: Image.PreserveAspectCrop

            retainWhileLoading: true

            asynchronous: true

            onStatusChanged: {
                if (status == Image.Ready) {
                    if (buffer.status == Image.Ready) {
                        fadeAnim.restart()
                    }
                    if (root.live) {
                        live.source = SystemInfo.homedir + WallpaperInfo.path + root.current
                        live.play()
                    } else {
                        live.source = ""
                        live.stop()
                    }
                }
            }

        }

        MediaPlayer {

            id: live
            source: ""
            loops: MediaPlayer.Infinite
            videoOutput: live_output

        }

        VideoOutput {
            id: live_output
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
        }

    }

    SequentialAnimation {
        id: fadeAnim
        NumberAnimation {
            target: root
            property: "transitionProgress"
            from: 0.0
            to: 1.0
            duration: WallpaperInfo.transition.duration*1000
            easing.type: Easing.InOutCubic
        }

    }

    ShaderEffectSource {
        id: main_buffer
        anchors.fill: parent
        sourceItem: main
        hideSource: true
        live: true
    }

    Image {

        id: buffer

        anchors.fill: parent
        visible: false

        opacity: 0

        source: ""

        onStatusChanged: {
            if (status == Image.Ready) {
                if (still.status == Image.Ready) {
                    opacity = 1
                    fadeAnim.restart()
                }
            }
        }

    }

    property double transitionProgress: 0

    function quantize(value, steps) {
        const step = 1 / steps;
        return Math.round(value / step) * step;
    }

    ShaderEffect {

        id: buffer_shader

        anchors.fill: parent

        property variant oldSource: buffer
        property variant newSource: main_buffer

        property real progress: {
            return root.quantize(root.transitionProgress, WallpaperInfo.transition.fps*WallpaperInfo.transition.duration)
        }

        property real winWidth: root.monitor.width
        property real winHeight: root.monitor.height

        property real transitionStep: WallpaperInfo.transition.step
        property real transitionFPS: WallpaperInfo.transition.fps
        property real transitionAngle: WallpaperInfo.transition.angle

        property real posX: WallpaperInfo.transition.posX
        property real posY: WallpaperInfo.transition.posY

        fragmentShader: root.shaders_path + root.transition_type + root.shaders_ext

    }

}
