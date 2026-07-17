import qs.config
import qs.services
import qs.modules

import Quickshell
import QtQuick

FloatingWindow {
    id: root

    visible: PopupManager.isOpen(name)

    property string name

    property int w: 20
    property int h: 10

    maximumSize: Qt.size(Cell.w(w + 1), Cell.h(h + 1))
    minimumSize: Qt.size(Cell.w(w + 1), Cell.h(h + 1))

    color: Colors.bgSurface

    default property alias content: cell.data

    Cells {
        id: cell

        w: root.w
        h: root.h

        anchors.centerIn: parent

        color: root.color
    }
}
