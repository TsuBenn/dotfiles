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
        still.source = root.isLive ? SystemInfo.homedir + WallpaperInfo.cache_path + root.current + WallpaperInfo.still_prefix : SystemInfo.homedir + WallpaperInfo.path + root.current
    }

    function grabBuffer() {
        root.grabToImage(function(result) {
            buffer.source = result.url
        })
    }

    Item {

        anchors.fill: parent

        id: main

        Image {

            id: still

            anchors.fill: parent

            source: root.isLive ? SystemInfo.homedir + WallpaperInfo.cache_path + root.current + WallpaperInfo.still_prefix : SystemInfo.homedir + WallpaperInfo.path + root.current

            fillMode: Image.PreserveAspectCrop

            retainWhileLoading: true

            asynchronous: true

            onStatusChanged: {
                if (status == Image.Ready) {
                    fadeAnim.restart()
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
        }

    }

    SequentialAnimation {
        id: fadeAnim
        NumberAnimation {
            target: buffer
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 500
        }

    }

    Image {

        id: buffer

        anchors.fill: parent
        source: ""

    }

}
