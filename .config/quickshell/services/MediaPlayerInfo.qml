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
    property bool   shuffleStatus : activePlayer ? (activePlayer?.shuffleSupported && activePlayer?.shuffle) : false
    property string status        : {
        if (!activePlayer?.playbackState) return ""
        if (!activePlayer?.canControl) return "stopped"
        switch (activePlayer?.playbackState) {
            case MprisPlaybackState.Playing: return "playing"
            case MprisPlaybackState.Paused: return "paused"
            case MprisPlaybackState.Stopped: return "stopped"
        }
    }
    property string loopStatus        : {
        if (activePlayer.loopSupported) {
            if (activePlayer.loopState == MprisLoopState.None) return "none"
            else if (activePlayer.loopState == MprisLoopState.Track) return "track"
            else if (activePlayer.loopState == MprisLoopState.Playlist) return "playlist"
        }
        return "none"
    }
    property string entry         : activePlayer?.desktopEntry ?? ""
    property string dbusName      : activePlayer?.dbusName ?? ""
    property real   length        : activePlayer?.lengthSupported ? activePlayer.length : null
    property real   pos           : activePlayer?.positionSupported ? activePlayer.position : null
    property real   volume        : activePlayer?.volumeSupported ? activePlayer.volume : null

    property bool   canPlay       : activePlayer?.canPlay ?? false
    property bool   canPause      : activePlayer?.canPause ?? false
    property bool   canNext       : activePlayer?.canGoNext ?? false
    property bool   canPrev       : activePlayer?.canGoPrevious ?? false
    property bool   canLoop       : activePlayer?.loopSupported ?? false
    property bool   canShuffle    : activePlayer?.shuffleSupported ?? false
    property bool   canVolume     : activePlayer?.volumeSupported ?? false

    signal adjusted()

    function formatTime(num): string {
        const hour = Math.floor(num/3600)
        const minute = Math.floor(num/60) - hour*60
        const second = Math.floor(num) - minute*60 - hour*3600

        return (hour > 0 ? hour + ":" : "") + (minute || minute == 0 ? minute.toString().padStart(2, '0') : "--") + ":" + (second || second == 0 ? second.toString().padStart(2, '0') : "--" )
    }

    function setVolume(num) {
        if (activePlayer)
        activePlayer.volume = num
    }

    function requestPos() {
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

    function itterateLoop() {
        if (activePlayer) {
            if (root.loopStatus == "none") {activePlayer.loopState = MprisLoopState.Track; root.loopStatus = "track"}
            else if (root.loopStatus == "track") {activePlayer.loopState = MprisLoopState.Playlist; root.loopStatus = "playlist"}
            else if (root.loopStatus == "playlist") {activePlayer.loopState = MprisLoopState.None; root.loopStatus = "none"}
        }
    }

    function test() {
        console.log(root.loopStatus + " " + activePlayer.loopState)
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
