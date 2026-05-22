import qs.config
import qs.modules
import qs.services

import QtQuick
import QtMultimedia

Item {

    Image {

        height: parent.implicitHeight
        width: parent.implicitWidth

        fillMode: Image.PreserveAspectCrop

        source: SystemInfo.homedir + WallpaperInfo.path + WallpaperInfo.current

    }

    MediaPlayer {

        source: ""
        loops: MediaPlayer.Infinite
        videoOutput: live_wallpaper
        Component.onCompleted: {play();}

    }

    VideoOutput {
        id: live_wallpaper
        anchors.fill: parent
    }
}
