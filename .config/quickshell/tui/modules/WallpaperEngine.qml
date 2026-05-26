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
        switch (WallpaperInfo.getTransition(main.current).type) {
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

    Component.onCompleted: {
        main.current = root.current
    }

    function grabBuffer() {
        root.grabToImage(function(result) {
            buffer.source = result.url
            //fadeAnim.restart()
        })
    }

    Item {

        anchors.fill: parent

        id: main
        visible: false

        clip: true

        property string current: root.current

        Image {

            id: still

            anchors.centerIn: parent

            anchors.verticalCenterOffset: ((height - parent.height)/2)*WallpaperInfo.getReposition(main.current).verticalOffset
            anchors.horizontalCenterOffset: ((width - parent.width)/2)*WallpaperInfo.getReposition(main.current).horizontalOffset

            width:  sourceSize.width  * scalar * WallpaperInfo.getReposition(main.current).scalar
            height: sourceSize.height * scalar * WallpaperInfo.getReposition(main.current).scalar

            property double scalar: Math.max(parent.width/sourceSize.width, parent.height/sourceSize.height)

            source: root.isLive ? SystemInfo.homedir + WallpaperInfo.cache_path + root.current + WallpaperInfo.still_prefix : SystemInfo.homedir + WallpaperInfo.path + root.current

            retainWhileLoading: true

            asynchronous: true

            onStatusChanged: {
                if (status == Image.Ready) {
                    main.current = root.current
                    fadeAnim.restart()
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

            anchors.centerIn: parent

            anchors.verticalCenterOffset: ((height - parent.height)/2)*WallpaperInfo.getReposition(main.current).verticalOffset
            anchors.horizontalCenterOffset: ((width - parent.width)/2)*WallpaperInfo.getReposition(main.current).horizontalOffset

            width:  sourceRect.width  * scalar * WallpaperInfo.getReposition(main.current).scalar
            height: sourceRect.height * scalar * WallpaperInfo.getReposition(main.current).scalar

            property double scalar: Math.max(parent.width/sourceRect.width, parent.height/sourceRect.height)

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
            duration: WallpaperInfo.getTransition(main.current).duration*1000
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

        source: ""

        onStatusChanged: {
            if (status == Image.Ready) {
                root.transitionProgress = 0
                still.source = root.isLive ? SystemInfo.homedir + WallpaperInfo.cache_path + root.current + WallpaperInfo.still_prefix : SystemInfo.homedir + WallpaperInfo.path + root.current
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
            return root.quantize(root.transitionProgress, WallpaperInfo.getTransition(root.current).fps*WallpaperInfo.getTransition(main.current).duration)
        }

        property real winWidth: root.monitor.width
        property real winHeight: root.monitor.height

        property real transitionStep: WallpaperInfo.getTransition(main.current).step
        property real transitionFPS: WallpaperInfo.getTransition(main.current).fps
        property real transitionAngle: WallpaperInfo.getTransition(main.current).angle

        property real posX: WallpaperInfo.getTransition(main.current).posX
        property real posY: WallpaperInfo.getTransition(main.current).posY

        fragmentShader: root.shaders_path + root.transition_type + root.shaders_ext

    }

}
