pragma ComponentBehavior: Bound

import qs.services

import Quickshell.Widgets
import QtQuick

Rectangle {
    id: button

    property string text                 : "Text"
    property real   text_opacity         : 1
    property real   text_padding         : 10
    property real   font_size            : 13
    property string font_family          : "JetBrains Mono Nerd Font"
    property int    font_weight          : 800
    property real   font_opacity         : 1
    property real   spacing              : 0
    property var    bg_color             : ["transparent", Color.bgSurface, Color.accentStrong]
    property var    fg_color             : [Color.textPrimary, Color.textPrimary, Color.bgSurface]

    property var    border_width         : [0, 2, 0]
    property var    border_color         : [Color.accentStrong, Color.accentStrong, Color.accentStrong]

    property int    box_height           : 30
    property int    box_width            : 0
    property int    preferedWidth        : button.implicitWidth
    property bool   clickable            : true
    property bool   marquee              : false

    property bool   centered             : true
    property bool   safe_release         : true
    property bool   ignoreElide          : false


    border.width: {
        if (!border_width) return 0
        if (mouse.pressed && clickable) {
            return border_width[2]
        } else if (mouse.containsMouse && clickable) {
            return border_width[1]
        } else {
            return border_width[0]
        }
    }
    border.color: {
        if (!border_color) return 0
        if (mouse.pressed && clickable) {
            return border_color[2]
        } else if (mouse.containsMouse && clickable) {
            return border_color[1]
        } else {
            return border_color[0]
        }
    }

    Behavior on border.width {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

    signal pressed()
    signal released()

    implicitHeight: box_height > 0 ? box_height : (button_text.implicitHeight + text_padding)
    implicitWidth: box_width > 0 ? box_width : (button_text.implicitWidth + text_padding*2)

    color: {
        if (!bg_color) return 0
        if (mouse.pressed && clickable) {
            return bg_color[2]
        } else if (mouse.containsMouse && clickable) {
            return bg_color[1]
        } else {
            return bg_color[0]
        }
    }

    radius: implicitHeight/2

    Text {

        id: button_text

        text: button.text.trim() 
        opacity: button.text_opacity

        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 0.8

        anchors.centerIn: parent

        width: button.centered ? undefined : button.implicitWidth - button.text_padding*2 - button.border.width*2

        color: {
            if (!button.fg_color) return 0
            if (mouse.pressed && button.clickable) {
                return button.fg_color[2]
            } else if (mouse.containsMouse && button.clickable) {
                return button.fg_color[1]
            } else {
                return button.fg_color[0]
            }
        }

        font.family: button.font_family
        font.pointSize: button.font_size
        font.weight: button.font_weight
        elide: button.ignoreElide || button_text.implicitWidth < button.implicitWidth ? Text.ElideNone : Text.ElideRight

    }



    MouseControl {
        id: mouse

        visible: button.clickable

        anchors.fill: parent
        anchors.margins: -button.border.width

        acceptedButtons: Qt.LeftButton

        preventStealing: true

        hoverEnabled: true

        onPressed: {button.pressed()}
        onReleased: {
            if (button.safe_release) {
                if (containsMouse) button.released()
            } else {
                button.released()
            }
        }
    }

}
