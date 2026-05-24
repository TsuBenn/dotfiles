import qs.config
import qs.modules
import qs.services

import QtQuick
import QtMultimedia

Item {

    id: root

    property string current: WallpaperInfo.current
    property bool isLive: WallpaperInfo.isLive(WallpaperInfo.current)
    property bool live: WallpaperInfo.live

    onCurrentChanged: {
        grabBuffer()
    }

    function grabBuffer() {
        root.grabToImage(function(result) {
            buffer.source = result.url
            still.source = root.isLive ? SystemInfo.homedir + WallpaperInfo.cache_path + root.current + WallpaperInfo.still_prefix : SystemInfo.homedir + WallpaperInfo.path + root.current
            fadeAnim.restart()
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
                    if (root.isLive) {
                        live.source = SystemInfo.homedir + WallpaperInfo.path + root.current
                        live.play()
                    } else {
                        live.pause()
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
            duration: 500
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

    }

    property real transitionProgress: 0

    ShaderEffect {

        id: buffer_shader

        anchors.fill: parent

        implicitHeight: 500
        implicitWidth: 500

        property variant oldSource: buffer
        property variant newSource: main_buffer

        property real progress: root.transitionProgress

        fragmentShader: SystemInfo.configdir + "/scripts/wallpaperFade.frag.qsb"

    }

}
