import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

RowLayout {

    spacing: 0

    Rectangle {
        implicitWidth: Cell.w(3)
        implicitHeight: Cell.h(1)

        color: Colors.accentStrong

        Text {
            text: "[⏸]"
            font: Cell.fontB
            color: Colors.bgBase
        }
    }

    Rectangle {
        implicitWidth: Cell.w(22)
        implicitHeight: Cell.h(1)

        color: Colors.accentStrong

        MarqueeText {
            x: Cell.w(1)
            cellw: 20
            text: ` ${MediaPlayerInfo.title} - ${MediaPlayerInfo.artist} `
        }
    }

}
