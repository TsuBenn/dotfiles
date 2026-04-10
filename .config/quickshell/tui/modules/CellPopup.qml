import qs.config
import qs.modules

import QtQuick
import Quickshell

Item {

    id: root

    visible: PopupManager.isOpen(name)

    property int w: 3
    property int h: 3

    property int cellX
    property int cellY

    property string name

    property int safeMargin: 0

    x: Cell.w(cellX)
    y: Cell.h(cellY)

    focus: true

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)

    MouseControl {
        anchors.fill: parent
    }

}
