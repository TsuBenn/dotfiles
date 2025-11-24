pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property list<MprisPlayer> players: Mpris.players.values
    property MprisPlayer activePlayer: Mpris.players.values[0] ?? null

    property string title         : activePlayer?.trackTitle ?? ""
    property string artist        : activePlayer?.trackArtist ?? ""
    property string album         : activePlayer?.trackAlbum ?? ""
    property string artUrl        : activePlayer?.trackArtUrl ?? ""
    property string status        : {
        if (!activePlayer?.playbackState) return ""
        switch (activePlayer?.playbackState) {
            case MprisPlaybackState.Playing: return "playing"
            case MprisPlaybackState.Paused: return "paused"
            case MprisPlaybackState.Stopped: return "stopped"
        }
    }
    property string entry         : activePlayer?.desktopEntry ?? ""
    property string dbusName      : activePlayer?.dbusName ?? ""
    property real   length        : activePlayer?.lengthSupported ? activePlayer.length : null
    property real   pos           : activePlayer?.positionSupported ? activePlayer.position : null
    property real   volume        : activePlayer?.volumeSupported ? activePlayer.volume : null

    property bool   canPlay       : activePlayer?.canPlay ?? ""
    property bool   canPause      : activePlayer?.canPause ?? ""
    property bool   canNext       : activePlayer?.canGoNext ?? ""
    property bool   canPrev       : activePlayer?.canGoPrevious ?? ""
    property bool   canLoop       : activePlayer?.loopSupported ?? ""
    property bool   canShuffle    : activePlayer?.shuffleSupported ?? ""
    property bool   canVolume     : activePlayer?.volumeSupported ?? ""

    signal adjusted()

    function formatTime(num): string {
        const hour = Math.floor(num/3600)
        const minute = Math.floor(num/60) - hour*60
        const second = Math.floor(num) - minute*60 - hour*3600

        return (hour > 0 ? hour + ":" : "") + (minute || minute == 0 ? minute.toString().padStart(2, '0') : "--") + ":" + (second || second == 0 ? second.toString().padStart(2, '0') : "--" )
    }

    function requestPos() {
    }
    
    function releasePos() {
    }

    function setVolume(num) {
        if (activePlayer)
        activePlayer.volume = num
    }

    function getPos(): real {
        if (activePlayer)
        activePlayer.positionChanged()
    }

    function setPos(num) {
        if (activePlayer)
        activePlayer.position = num
    }

    function playPauseMedia() {
        if (activePlayer)
        activePlayer.togglePlaying()
    }

    function playMedia() {
        if (activePlayer)
        activePlayer.play()
    }

    function pauseMedia() {
        if (activePlayer)
        activePlayer.pause()
    }

    function nextMedia() {
        if (activePlayer)
        activePlayer.next()
    }

    function prevMedia() {
        if (activePlayer)
        activePlayer.previous()
    }

    function toggleShuffle() {
        if (activePlayer)
        activePlayer.shuffle = !activePlayer.shuffle
    }

    function test() {
        //console.log(root.status)
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            root.test()
        }
    }

}
