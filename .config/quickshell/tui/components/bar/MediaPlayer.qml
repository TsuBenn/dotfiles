import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

RowLayout {

    spacing: Cell.w(0)

    CellButton {

        id: button

        text: MediaPlayerInfo.status == "playing" ? " ⏸ " : " ▶ "
        font: Cell.fontB
        fg: MediaPlayerInfo.activePlayer ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

        padding: 0

        color: MediaPlayerInfo.activePlayer ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay

        onPressed: (button) => {
            if (button != "L") return
            MediaPlayerInfo.playPauseMedia()
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


    }

}
