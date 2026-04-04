import qs.modules.homepanel

import Quickshell
import QtQuick

Rectangle {
    radius: Config.radius
    property string bg_color: "#d93232"
    property string bg_hovered: "#c22929"
    property string bg_pressed: "white"

    property string fg_color: "white"
    property string fg_hovered: "white"
    property string fg_pressed: "red"

    property string icon: "\udb81\udc25"
    property int icon_size: 40

    property bool hovered: false
    property bool pressed: false

    property string button_color

    anchors.fill: parent
    anchors.centerIn: parent

    color: {
        if (pressed) {
            return bg_pressed
        } else if (hovered) {
            return bg_hovered
        } else {
            return bg_color
        }
    }

    Text {
        anchors.centerIn: parent

        height: implicitHeight*1.05

        text: parent.icon
        font.pointSize: parent.icon_size

        color: {
            if (parent.pressed) {
                return parent.fg_pressed
            } else if (parent.hovered) {
                return parent.fg_hovered
            } else {
                return parent.fg_color
            }
        }

    }

    signal clicked()
    signal released()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: parent.hovered = true
        onExited: parent.hovered = false
        onPressed: {
            parent.pressed = true
            parent.clicked()
        }
        onReleased: {
            parent.pressed = false
            if (parent.hovered) parent.released()
        }
    }
}
