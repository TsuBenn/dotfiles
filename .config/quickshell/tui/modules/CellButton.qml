import qs.config
import qs.modules

import QtQuick

Item {

    id: root

    property int w: 0
    property int h: 0

    property string text: "Sample"
    property font font: Cell.font
    property var fg: Colors.onAccent
    property var color: Colors.accentStrong

    property int padding: 1
    property bool centered: true
    property bool marquee: false

    property bool safeRelease: true
    property bool clickable: true

    property string buttonDown: mouse.buttonDown

    property bool holdEnabled: false
    property int holdInterval: 100
    property int holdOffset: 0

    signal entered()
    signal exited()
    signal pressed(button: string)
    signal released(button: string)
    signal held(button: string)

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    
    onVisibleChanged: {
        mouse.buttonDown = ""
        mouse.hovered = false
    }

    onClickableChanged: {
        mouse.buttonDown = ""
        mouse.hovered = false
    }

    Cells {

        id: button

        w: root.w > 0 ? root.w : text.w + root.padding*2
        h: root.h > 0 ? root.h : text.h

        color: {
            if (Array.isArray(root.color)) {
                if (root.color.length == 2) {
                    if (mouse.buttonDown) return root.color[1]
                    else return root.color[0]
                } else if (root.color.length == 3) {
                    if (mouse.buttonDown) return root.color[2]
                    else if (mouse.hovered) return root.color[1]
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

            centered: root.centered
            text: root.text
            font: root.font
            color: {
                if (Array.isArray(root.fg)) {
                    if (root.fg.length == 2) {
                        if (mouse.buttonDown) return root.fg[1]
                        else return root.fg[0]
                    } else if (root.fg.length == 3) {
                        if (mouse.buttonDown) return root.fg[2]
                        else if (mouse.hovered) return root.fg[1]
                        else return root.fg[0]
                    } else {
                        console.error("CellButton: \"fg\" can only either be color or list of colors with size of 2 and 3")
                    }
                }
                return root.fg
            }

        }

        MouseControl {

            id: mouse

            visible: root.clickable

            anchors.fill: parent

            holdEnabled: root.holdEnabled
            holdOffset: root.holdOffset
            holdInterval: root.holdInterval

            onEntered: {
                root.entered()
            }
            onExited: {
                root.exited()
            }
            onPressed: (button) => {
                root.pressed(button)
            }
            onReleased: (button) => {
                if (!root.safeRelease) {
                    root.released(button)
                } else if (hovered) {
                    root.released(button)
                }
            }
            onHeld: (button) => {
                root.held(button)
            }

        }

    }
}
