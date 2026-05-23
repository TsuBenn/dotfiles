import qs.config
import qs.modules
import qs.services

import Quickshell.Io
import QtQuick
import QtMultimedia

Item {

    id: root

    property string current: WallpaperInfo.current
    property bool isLive: WallpaperInfo.isLive(WallpaperInfo.current)
    property bool live: WallpaperInfo.live

    property var awww_command: [
        "awww", "img", 
        "-t", WallpaperInfo.transition.type, 
        "--transition-step", WallpaperInfo.transition.step, 
        "--transition-duration", WallpaperInfo.transition.duration, 
        "--transition-fps", WallpaperInfo.transition.fps, 
        "--transition-angle", WallpaperInfo.transition.angle, 
        "--transition-pos", WallpaperInfo.transition.pos[0] + "," + WallpaperInfo.transition.pos[1], 
        root.isLive ? SystemInfo.homedir + WallpaperInfo.cache_path + root.current + WallpaperInfo.still_prefix : SystemInfo.homedir + WallpaperInfo.path + WallpaperInfo.current
    ]

    onCurrentChanged: {
        if (isLive) {
            live.play()
            live_delay.restart()
        } else {
            setWallpaper()
        }
    }

    function setWallpaper() {
        if (current) {


            SystemInfo.runDetached([
                "awww", "img", 
                "-t", WallpaperInfo.transition.type, 
                "--transition-step", WallpaperInfo.transition.step, 
                "--transition-duration", WallpaperInfo.transition.duration, 
                "--transition-fps", WallpaperInfo.transition.fps, 
                "--transition-angle", WallpaperInfo.transition.angle, 
                "--transition-pos", WallpaperInfo.transition.pos[0] + "," + WallpaperInfo.transition.pos[1], 
                root.isLive ? SystemInfo.homedir + WallpaperInfo.cache_path + "nothing.png" : SystemInfo.homedir + WallpaperInfo.path + WallpaperInfo.current
            ])

        }
    }

    Timer {
        id: live_delay
        interval: 100
        onTriggered: {
            root.setWallpaper()
        }
    }

    Process {

        id: awww_daemon

        running: true
        command: ["awww-daemon", "-l", "bottom"]

    }

    MediaPlayer {

        id: live
        source: root.isLive ? SystemInfo.homedir + WallpaperInfo.path + WallpaperInfo.current : ""
        loops: MediaPlayer.Infinite
        videoOutput: live_output

    }

    VideoOutput {
        id: live_output
        anchors.fill: parent
    }

}
