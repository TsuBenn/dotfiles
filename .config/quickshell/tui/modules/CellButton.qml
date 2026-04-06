import qs.config
import qs.modules

import QtQuick

Item {

    id: root

    property int w: 0
    property int h: 0

    property string text: "Sample"
    property font font: Cell.font
    property var fg: Colors.bgBase
    property var color: Colors.accentStrong

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

        property bool pressed: false
        property bool hovered: false

        w: root.w > 0 ? root.w : text.w + root.padding*2
        h: root.h > 0 ? root.h : text.h

        color: {
            if (Array.isArray(root.color)) {
                if (root.color.length == 2) {
                    if (pressed) return root.color[1]
                    else return root.color[0]
                } else if (root.color.length == 3) {
                    if (hovered) return root.color[1]
                    else if (pressed) return root.color[2]
                    else return root.color[0]
                } else {
                    console.error("CellButton: \"color\" can only either be color or list of colors with size of 2 and 3")
                }
            }
            return root.color
        }

        CellText {

            id: text

            x: root.centered ? Cell.w(button.w/2 - w/2) : Cell.w(root.padding)

            preferedW: root.w > 0 ? Cell.wCount(root.implicitWidth) - root.padding-2 : 0

            text: root.text
            font: root.font
            color: {
                if (Array.isArray(root.fg)) {
                    if (root.fg.length == 2) {
                        if (button.pressed) return root.fg[1]
                        else return root.fg[0]
                    } else if (root.fg.length == 3) {
                        if (button.hovered) return root.fg[1]
                        else if (button.pressed) return root.fg[2]
                        else return root.fg[0]
                    } else {
                        console.error("CellButton: \"fg\" can only either be color or list of colors with size of 2 and 3")
                    }
                }
                return root.fg
            }

        }

        MouseControl {

            anchors.fill: parent

            holdEnabled: true

            onHeld: (button) => {
                console.log(button)
            }

        }

    }
}
