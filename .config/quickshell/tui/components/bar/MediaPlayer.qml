import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

RowLayout {

    spacing: Cell.w(0)

    CellButton {

        text: MediaPlayerInfo.status == "playing" ? "⏸" : "▶"
        font: Cell.fontB
        fg: MediaPlayerInfo.activePlayer ? Colors.fgBase : Colors.fgSubtle

        color: MediaPlayerInfo.activePlayer ? [Colors.accentStrong, Colors.accentDim] : Colors.bgOverlay

        onPressed: (button) => {
            if (button != "L") return
            MediaPlayerInfo.playPauseMedia()
        }

    }

    Cells {

        visible: MediaPlayerInfo.activePlayer
        w: 26
        h: 1

        color: Colors.bgOverlay

        RowLayout {

            spacing: 0

            CellText {
                text: "[ "
                color: Colors.fgDim
            }

            MarqueeCellText {

                cellw: 22
                text: `${MediaPlayerInfo.title} - ${MediaPlayerInfo.artist}`

            }

            CellText {
                text: " ]"
                color: Colors.fgDim
            }

        }


    }

}
