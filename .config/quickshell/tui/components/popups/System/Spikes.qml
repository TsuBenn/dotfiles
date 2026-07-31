import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 0

    property int w
    property var box

    CellText {
        text: "USAGE LOG"
        font: Cell.fontB
        color: Colors.secondary
        preferedW: root.w
        centered: true
    }

    CellSeparator {
        w: root.w
        color: Colors.accentDim
    }

    CellScrollList {
        w: root.w
        h: root.box.contentH - 15
        itemH: h
    }
}
