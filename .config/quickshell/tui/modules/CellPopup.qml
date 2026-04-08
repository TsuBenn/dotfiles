import qs.config
import qs.modules

import QtQuick
import Quickshell

PanelWindow {

    id: root

    property int w: 3
    property int h: 3

    property int x: 0
    property int y: 0

    focusable: true

    anchors {
        top: true
        left: true
    }

    margins {
        left: Cell.w(root.x)
        top: Cell.h(root.y)
    }

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)

    Cells {

        w: root.w
        h: root.h

        grid: true

    }

}
