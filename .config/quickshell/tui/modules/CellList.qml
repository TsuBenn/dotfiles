import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Cells {

    id: root

    w: 10
    h: 5

    property int padding: 0
    property int spacing: 0

    property int offset: 0

    property bool scrollbar: true

    property var model
    property Component item

    color: "transparent"

    Cells {

        w: root.w - root.padding*2
        h: root.h

        clip: true

        color: "transparent"

        ColumnLayout {

            id: content

            spacing: Cell.h(root.spacing)

            Repeater {

                model: root.model

                delegate: root.item

            }

        }

    }

    Cells {

        id: scroll

        x: Cell.alignRightWCell(implicitWidth, root.implicitWidth)

        w: 1
        h: root.h

        color: Colors.bgOverlay

    }

    MouseControl {

        anchors.fill: parent

        acceptedButtons: Qt.NoButton

        onWheel: (delta) => {
            root.offset = Math.max(Math.min(root.offset + delta,Cell.hCount(content.implicitWidth)-root.h),0)
        }

    }

}
