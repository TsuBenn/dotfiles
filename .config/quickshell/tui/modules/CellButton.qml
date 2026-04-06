import qs.config
import qs.modules

import QtQuick

Item {

    id: root

    property int w: 0
    property int h: 0

    property string text: "Sample"
    property font font: Cell.font
    property color fg: Colors.bgBase
    property color color: Colors.accentStrong

    property int padding: 1
    property bool centered: true
    property bool marquee: false

    property bool safeRelease: true

    signal entered()
    signal exited()
    signal pressed()
    signal released()

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    Cells {

        id: button

        w: root.w > 0 ? root.w : text.w + root.padding*2
        h: root.h > 0 ? root.h : text.h

        color: root.color

        CellText {

            id: text

            x: root.centered ? Cell.w(button.w/2 - w/2) : Cell.w(root.padding)

            preferedW: root.w > 0 ? Cell.wCount(root.implicitWidth) - root.padding-2 : 0

            text: root.text
            font: root.font
            color: root.fg

        }

        MouseControl {

            anchors.fill: parent

            onPressed: (button) => {
                console.log(button)
            }

        }

    }
}
