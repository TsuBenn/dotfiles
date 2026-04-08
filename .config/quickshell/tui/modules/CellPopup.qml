import qs.config

import QtQuick
import Quickshell

PanelWindow {

    id: root

    property int w: 10
    property int h: 2

    property int x: 0
    property int y: 0

    anchors {
        top: true
        left: true
    }

    margins {
        left: root.x
        top: root.y
    }

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)
    
}
