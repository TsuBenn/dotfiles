import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

RowLayout {

    spacing: Cell.w(0)

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
        fg: MediaPlayerInfo.activePlayer ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

        padding: 0

        color: MediaPlayerInfo.activePlayer ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay

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

    Cells {

        visible: MediaPlayerInfo.activePlayer
        w: 25
        h: 1

        color: Colors.bgOverlay

        RowLayout {

            spacing: 0

            CellText {
                text: "▏"
                color: Colors.fgDim
                font: Cell.fontB
            }

            MarqueeCellText {

                cellw: 22
                text: `${MediaPlayerInfo.title} - ${MediaPlayerInfo.artist}`

            }

            CellText {
                text: " │"
                color: Colors.fgDim
                font: Cell.fontB
            }

        }

        MouseControl {

            anchors.fill: parent

            onReleased: (button) => {
                if (button == "L") {
                    PopupManager.toggle("media_player")
                }
            }

        }

    }

}
