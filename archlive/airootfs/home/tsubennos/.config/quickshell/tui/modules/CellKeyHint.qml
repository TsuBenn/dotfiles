import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

RowLayout {

    id: root

    property string key: "Key"
    property string hint: "Do stuff"

    property bool disabled: false

    property int padding: 1

    spacing: 0

    CellText {
        text: " ".repeat(root.padding) + root.key + " ".repeat(root.padding)
        bg: Colors.bgOverlay
        color: root.disabled ? Colors.fgSubtle : Colors.fgBase
    }

    CellText {
        text: ` ${root.hint}`
        color: root.disabled ? Colors.fgSubtle : Colors.fgBase
    }
}
