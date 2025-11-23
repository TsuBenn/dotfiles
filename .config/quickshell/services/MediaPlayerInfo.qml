pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property var sources: [] 

    property string currentSource : ""
    property string title         : ""
    property string artist        : ""
    property string album         : ""
    property string artUrl        : ""
    property string objpath       : ""
    property string status        : ""
    property string entry         : ""
    property var    length        : 0
    property var    pos           : 0

    signal adjusted()

    function formatTime(num): string {
        const hour = Math.floor(num/3600000000)
        const minute = Math.floor(num/60000000) - hour*60
        const second = Math.floor(num/1000000) - minute*60 - hour*3600

        return (hour > 0 ? hour + ":" : "") + (minute || minute == 0 ? minute.toString().padStart(2, '0') : "--") + ":" + (second || second == 0 ? second.toString().padStart(2, '0') : "--" )

    }

    function reloadSources() {
        checkSources.running = true
    }

    function setPosMedia(num) {
        mediaPlayer.exec(["bash","-c","dbus-send --print-reply --session --dest=" + root.currentSource + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.SetPosition objpath:" + root.objpath + " int64:" + num])
        reloadSources()
    }

    function playPauseMedia() {
        mediaPlayer.exec(["bash","-c","dbus-send --print-reply --session --dest=" + root.currentSource + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause"])
        reloadSources()
    }

    function playMedia() {
        mediaPlayer.exec(["bash","-c","dbus-send --print-reply --session --dest=" + root.currentSource + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play"])
        reloadSources()
    }

    function pauseMedia() {
        mediaPlayer.exec(["bash","-c","dbus-send --print-reply --session --dest=" + root.currentSource + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause"])
        reloadSources()
    }

    function nextMedia() {
        mediaPlayer.exec(["bash","-c","dbus-send --print-reply --session --dest=" + root.currentSource + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next"])
        reloadSources()
    }

    function prevMedia() {
        mediaPlayer.exec(["bash","-c","dbus-send --print-reply --session --dest=" + root.currentSource + " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous"])
        reloadSources()
    }

    Process {
        id: mediaPlayer
        stdout: StdioCollector {
            onStreamFinished: {
                root.adjusted()
            }
        }
    }

    Process {
        id: checkSources
        running: true
        command: ["bash", "-c", "dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames"]

        stdout: StdioCollector {
            onStreamFinished: {
                const datas = text.match(/string\s+"org\.mpris\.MediaPlayer2\..*"/g)
                if (datas) {
                    let sources = []

                    for (const data of datas) {
                        const raw = data.match(/string\s+"(org\.mpris\.MediaPlayer2\.([a-zA-Z0-9]+).*)"/)
                        sources.push({"source": raw[1], "entry": raw[2]})
                    }

                    root.sources = sources

                    if (!root.currentSource) root.currentSource = root.sources[0].source

                    checkMetadata.running = true
                }
            }
        }
    }

    Process {
        id: checkMetadata
        command: ["bash", "-c", "dbus-send --print-reply --dest=" + root.currentSource + " /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.GetAll string:'org.mpris.MediaPlayer2.Player'"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.title = text.match(/title[\s\S]*?string "(.*)"/m)?.[1] ?? ""
                root.artist = text.match(/artist[\s\S]*?string "(.*)"/m)?.[1] ?? ""
                root.album = text.match(/album[\s\S]*?string "(.*)"/m)?.[1] ?? ""
                root.artUrl = text.match(/artUrl[\s\S]*?string "file:\/\/(.*)"/m)?.[1] ?? ""
                root.objpath = text.match(/trackid[\s\S]*?object path "(.*)"/m)?.[1] ?? ""
                root.length = parseInt(text.match(/length[\s\S]*?int64\s+(.*)/m)?.[1]) ?? ""
                root.status = text.match(/PlaybackStatus[\s\S]*?string "(.*)"/m)?.[1] ?? ""
                root.pos = parseInt(text.match(/Position[\s\S]*?int64 (.*)/m)?.[1]) ?? ""
                checkEntry.running = true
            }
        }
    }

    Process {
        id: checkEntry
        command: ["bash", "-c", "dbus-send --print-reply --dest=" + root.currentSource + " /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.GetAll string:'org.mpris.MediaPlayer2'"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.entry = text.match(/DesktopEntry[\s\S]*?string "(.*)"/m)?.[1] ?? ""
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            root.reloadSources() 
        }
    }
}
