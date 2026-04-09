import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Cells {

    id: root

    w: 10
    h: 5

    property int contentW: w - scrollbar

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

            y: -Cell.h(1)*root.offset

            Repeater {

                model: root.model

                delegate: root.item

            }

        }

    }

    Cells {

        visible: root.scrollbar

        z: 1

        id: scroll

        x: Cell.alignRightWCell(implicitWidth, root.implicitWidth)

        w: 1
        h: root.h

        color: Colors.bgOverlay

        Cells {

            id: scroll_thumb

            w: 1
            h: Math.round((root.h/Cell.hCount(content.implicitHeight))*root.h)

            y: Cell.h(Math.round((root.offset/(Cell.hCount(content.implicitHeight)-root.h))*(scroll.h-h)))

            color: Colors.fgDim

        }

        MouseControl {

            anchors.fill: parent

            onPressed: (button) => {
                if (button == "L") {
                    root.offset = (Cell.hCount(content.implicitHeight)-root.h)*(Math.min(Math.max(mouseY,scroll_thumb.implicitHeight/2),scroll.implicitHeight-scroll_thumb.implicitHeight/2)-scroll_thumb.implicitHeight/2)/(scroll.implicitHeight-scroll_thumb.implicitHeight)
                }
            }
            onMoved: {
                if (buttonDown == "L") {
                    root.offset = (Cell.hCount(content.implicitHeight)-root.h)*(Math.min(Math.max(mouseY,scroll_thumb.implicitHeight/2),scroll.implicitHeight-scroll_thumb.implicitHeight/2)-scroll_thumb.implicitHeight/2)/(scroll.implicitHeight-scroll_thumb.implicitHeight)
                }
            }

        }

    }

    MouseControl {

        anchors.fill: parent

        acceptedButtons: Qt.NoButton

        hoverEnabled: false

        onWheel: (delta) => {
            root.offset = Math.max(Math.min(root.offset + delta,Cell.hCount(content.implicitHeight)-root.h),0)
        }

    }

}
