import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    property bool minimal: SettingsInfo.minimal

    w: 51 - Cell.wCount(Cell.h(6),"ceil")*root.minimal + 2
    h: Cell.hCount(layout.implicitHeight) + 2

    shortcuts: [
        {
            binds: "Space",
            action: () => {
                MediaPlayerInfo.playPauseMedia()
            }
        },
        {
            binds: ["D", "L","Right"],
            action: () => {
                MediaPlayerInfo.nextMedia()
            }
        },
        {
            binds: ["A", "J","Left"],
            action: () => {
                MediaPlayerInfo.prevMedia()
            }
        },
    ]

    CellBox {

        id: box

        w: root.w
        h: root.h

        ColumnLayout {

            id: layout

            spacing: 0

            RowLayout {

                spacing: 0

                CellText {
                    text: " "
                }

                Cells {

                    id: art

                    visible: thumbnail.source != "" && !root.minimal

                    w: Cell.wCount(Cell.h(6),"ceil")
                    h: 6

                    color: "transparent"

                    Image {

                        y: sourceSize.width != sourceSize.height ? Cell.h(1) : 0

                        id: thumbnail

                        width: Cell.h(parent.h)
                        height: sourceSize.width == sourceSize.height ? Cell.h(parent.h) : Cell.h(3)

                        source: MediaPlayerInfo.artUrl ?? ""

                        fillMode: Image.PreserveAspectCrop

                    }

                }

                CellText {

                    visible: thumbnail.source != "" && !root.minimal

                    text: " "
                }

                ColumnLayout {

                    Layout.alignment: Qt.AlignTop

                    spacing: 0

                    CellText {
                        text: MediaPlayerInfo.title
                        font: Cell.fontBB
                        preferedW: box.contentW - 2 - 13*art.visible
                    }

                    CellText {
                        visible: text
                        text: MediaPlayerInfo.artist
                        font: Cell.fontB
                        color: Colors.fgDim
                        preferedW: box.contentW - 2 - 13*art.visible
                    }

                    CellSeparator {
                        w: box.contentW - 2 - 13*art.visible
                        type: 0
                        color: Colors.accentDim
                    }

                    Cells {

                        w: box.contentW - 2 - 13*art.visible
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
                        w: box.contentW - 2 - 13*art.visible
                        type: 2
                        percent: (MediaPlayerInfo.pos/MediaPlayerInfo.length)*100
                        cellInterval: 10

                        syncDelay: 200

                        interactive: true

                        wheel: false

                        onAdjusted: (percent) => {
                            MediaPlayerInfo.setPos(MediaPlayerInfo.length*(percent/100))
                        }

                        onVisibleChanged: {
                            if (visible) {
                                MediaPlayerInfo.requestPos()
                            }
                        }

                        Timer {

                            running: parent.visible && MediaPlayerInfo.status == "playing"
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

                            text: "R"

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

                            text: MediaPlayerInfo.status == "playing" ? " 1 " : " 0 "
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

                            text: MediaPlayerInfo.loopStatus == "track" ? "L1" : "L"

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

                visible: !root.minimal

                w: box.contentW
                type: 0
                color: Colors.accentStrong
            }

            CellAudioVisual {

                visible: !root.minimal

                w: box.contentW-1
                h: 5
                spacing: 1
                barW: 1

                color: [Colors.secondary, Colors.warning, Colors.danger]

            }

            CellSeparator {

                visible: SettingsInfo.hints

                w: box.contentW
                type: 0
                color: Colors.accentStrong

            }

            RowLayout {

                visible: SettingsInfo.hints

                Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(box.contentW))

                spacing: Cell.w(2)

                CellKeyHint {
                    visible: MediaPlayerInfo.canPrev
                    key: "←"
                    hint: "Prev"
                }

                CellKeyHint {
                    visible: MediaPlayerInfo.canPlay
                    key: "Space"
                    hint: MediaPlayerInfo.status == "playing" ? "Pause" : "Play"
                }

                CellKeyHint {
                    visible: MediaPlayerInfo.canNext
                    key: "→"
                    hint: "Next"
                }

            }

        }


    }

}
