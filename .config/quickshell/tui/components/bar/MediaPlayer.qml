import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

RowLayout {

    spacing: 0

    Cells {
        w: 3
        h: 1

        color: Colors.accentStrong

        CellText {
            text: " ⏸ "
            font: Cell.fontB
            color: Colors.bgBase
        }
    }

    Cells {
        visible: MediaPlayerInfo.activePlayer
        w: 22
        h: 1

        color: Colors.accentStrong

        MarqueeText {
            x: Cell.w(1)
            cellw: 20
            text: ` ${MediaPlayerInfo.title} - ${MediaPlayerInfo.artist} `
        }
    }

}
