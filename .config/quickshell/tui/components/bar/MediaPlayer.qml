import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

RowLayout {

    spacing: Cell.w(0)

    Cells {

        w: 3
        h: 1

        color: MediaPlayerInfo.activePlayer ? Colors.accentStrong : Colors.bgOverlay
        CellText {

            text: MediaPlayerInfo.status == "playing" ? " 1 " : " 0 "
            font: Cell.fontB
            color: MediaPlayerInfo.activePlayer ? Colors.bgBase : Colors.fgSubtle

        }

    }

    Cells {

        visible: MediaPlayerInfo.activePlayer
        w: 24
        h: 1

        color: Colors.bgOverlay

        RowLayout {

            spacing: 0

            CellText {
                text: "│"
                color: Colors.fgDim
            }

            MarqueeCellText {

                cellw: 22
                text: `${MediaPlayerInfo.title} - ${MediaPlayerInfo.artist}`

            }

        }


    }

}
