import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    w: 51
    h: SettingsInfo.minimal ? 6 : 10

    CellBox {

        id: box

        w: root.w+2
        h: root.h+2

        ColumnLayout {

            spacing: 0

            RowLayout {

                spacing: 0

                CellText {
                    text: " "
                }

                Cells {

                    id: art

                    visible: thumbnail.source != ""

                    w: Cell.wCount(Cell.h(6),"ceil")
                    h: 6

                    color: "transparent"

                    Image {

                        id: thumbnail

                        width: Cell.h(parent.h)
                        height: Cell.h(parent.h)

                        source: MediaPlayerInfo.artUrl ?? ""

                        fillMode: Image.PreserveAspectCrop

                    }

                }

                CellText {

                    visible: thumbnail.source != ""

                    text: " "
                }

                ColumnLayout {

                    Layout.alignment: Qt.AlignTop

                    spacing: 0

                    CellText {
                        text: MediaPlayerInfo.title
                        font: Cell.fontBB
                        preferedW: box.contentW - 2 - 15*art.visible
                    }

                    CellText {
                        visible: text
                        text: MediaPlayerInfo.artist
                        font: Cell.fontB
                        color: Colors.fgDim
                        preferedW: box.contentW - 2 - 15*art.visible
                    }

                    CellSeparator {
                        w: box.contentW - 2 - 15*art.visible
                        type: 2
                        color: Colors.bgOverlay
                    }

                    Cells {

                        w: box.contentW - 2 - 15*art.visible
                        h: 1

                        color: "transparent"

                        CellDropdown {

                            w: 12
                            text: ""
                            selected: {
                                for (const i in MediaPlayerInfo.players) {
                                    if (MediaPlayerInfo.players[i].dbusName == MediaPlayerInfo.activePlayer.dbusName) {
                                        return i
                                    }
                                }
                                return 0
                            }
                            items: {
                                let items = [] 
                                for (const i in MediaPlayerInfo.players) {
                                    items.push({
                                        label: MediaPlayerInfo.players[i].desktopEntry.toUpperCase(),
                                        action: () => {
                                            MediaPlayerInfo.pauseMedia()
                                            MediaPlayerInfo.activePlayer = MediaPlayerInfo.players[i]
                                        }
                                    })
                                }
                                return items
                            }

                        }

                        RowLayout {
                            anchors.right: parent.right
                            spacing: 0

                            CellText {
                                text: MediaPlayerInfo.formatTime(MediaPlayerInfo.pos)
                            }

                            CellText {
                                text: " / " + MediaPlayerInfo.formatTime(MediaPlayerInfo.length)
                                color: Colors.fgDim
                            }
                        }

                    }

                    CellProgressSquare {
                        w: box.contentW - 2 - 15*art.visible
                        type: 2
                        percent: (MediaPlayerInfo.pos/MediaPlayerInfo.length)*100
                        cellInterval: 10

                        syncDelay: 200

                        interactive: true

                        wheel: false

                        onAdjusted: (percent) => {
                            MediaPlayerInfo.setPos(MediaPlayerInfo.length*(percent/100))
                        }

                        Timer {

                            running: visible && MediaPlayerInfo.status == "playing"
                            repeat: true
                            interval: 1000
                            onTriggered: {
                                MediaPlayerInfo.requestPos()
                            }

                        }
                    }

                    RowLayout {

                        Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(box.contentW - 2 - 15*art.visible))

                        spacing: Cell.w(2)

                        CellButton {

                            text: "RAND"

                            font: Cell.fontB
                            fg: MediaPlayerInfo.canShuffle ? (MediaPlayerInfo.shuffleStatus ? Colors.onAccent : Colors.fgBase) : Colors.fgSubtle

                            clickable: MediaPlayerInfo.canPrev

                            color: MediaPlayerInfo.canShuffle && MediaPlayerInfo.shuffleStatus ? Colors.accentStrong : Colors.bgOverlay

                            onReleased: (button) => {
                                if (button != "L") return
                                MediaPlayerInfo.toggleShuffle()
                            }

                        }

                        CellButton {

                            text: " < "

                            font: Cell.fontB
                            fg: MediaPlayerInfo.canPrev ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                            clickable: MediaPlayerInfo.canPrev

                            padding: 0

                            color: MediaPlayerInfo.canPrev ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay

                            onReleased: (button) => {
                                if (button != "L") return
                                MediaPlayerInfo.prevMedia()
                            }

                        }

                        CellButton {

                            id: button

                            text: MediaPlayerInfo.status == "playing" ? " ⏸ " : " ▶ "
                            font: Cell.fontB
                            fg: MediaPlayerInfo.activePlayer ? [Colors.bgSurface, Colors.fgBase] : Colors.fgSubtle

                            padding: 0

                            color: MediaPlayerInfo.activePlayer ? [Colors.fgBase, Colors.bgOverlay] : Colors.bgOverlay

                            onReleased: (button) => {
                                if (button != "L") return
                                MediaPlayerInfo.playPauseMedia()
                            }

                        }

                        CellButton {

                            text: " > "

                            font: Cell.fontB
                            fg: MediaPlayerInfo.canNext ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                            clickable: MediaPlayerInfo.canNext

                            padding: 0

                            color: MediaPlayerInfo.canNext ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay

                            onReleased: (button) => {
                                if (button != "L") return
                                MediaPlayerInfo.nextMedia()
                            }

                        }

                        CellButton {

                            text: MediaPlayerInfo.loopStatus == "track" ? "LOOP1" : "LOOP"

                            font: Cell.fontB
                            fg: MediaPlayerInfo.canLoop ? (MediaPlayerInfo.loopStatus != "none" ? Colors.onAccent : Colors.fgBase) : Colors.fgSubtle

                            clickable: MediaPlayerInfo.canPrev

                            color: MediaPlayerInfo.canLoop && MediaPlayerInfo.loopStatus != "none" ? Colors.accentStrong : Colors.bgOverlay

                            onReleased: (button) => {
                                if (button != "L") return
                                MediaPlayerInfo.itterateLoop()
                            }

                        }


                    }

                }

            }

            CellSeparator {
                w: box.contentW
                type: 2
                color: Colors.fgSubtle
            }

            CellAudioVisual {

                Layout.leftMargin: Cell.w(1)

                w: box.contentW
                h: 3

                spacing: 1
            }

        }


    }

}
