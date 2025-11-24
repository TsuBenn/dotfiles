pragma ComponentBehavior: Bound

import Quickshell.Widgets
import QtQuick

ClippingRectangle {
    id: button

    property string text                 : "Text"
    property real   text_opacity         : 1
    property real   text_padding         : 10
    property real   font_size            : 13
    property string font_family          : "JetBrains Mono Nerd Font"
    property int    font_weight          : 800
    property real   font_opacity         : 1
    property real   spacing              : 0
    property var    bg_color             : ["transparent", "light gray", "gray"]
    property var    fg_color             : ["black", "black", "white"]

    property var    border_width         : [0, 0, 0]
    property var    border_color         : ["transparent", "transparent", "transparent"]

    property int    box_height           : 30
    property int    box_width            : 0
    property int    preferedWidth        : button.implicitWidth
    property bool   clickable            : true
    property bool   marquee              : false
    property bool   marqueeAble          : button.marquee && button_text.paintedWidth > preferedWidth

    property bool   centered             : true
    property bool   safe_release         : true


    border.width: {
        if (mouse.pressed && clickable) {
            return border_width[0]
        } else if (mouse.containsMouse && clickable) {
            return border_width[1]
        } else {
            return border_width[2]
        }
    }
    border.color: {
        if (mouse.pressed && clickable) {
            return border_color[0]
        } else if (mouse.containsMouse && clickable) {
            return border_color[1]
        } else {
            return border_color[2]
        }
    }

    signal pressed()
    signal released()

    Rectangle {
        visible: button.marqueeAble
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        implicitWidth: button.text_padding/2

        z:1

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {position: 1.0; color: button.color}
            GradientStop {position: 0.0; color: "transparent"}
        }
    }
    Rectangle {
        visible: button.marqueeAble
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        implicitWidth: button.text_padding/2

        z:1

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {position: 0.0; color: button.color}
            GradientStop {position: 1.0; color: "transparent"}
        }
    }

    implicitHeight: box_height > 0 ? box_height : (button_text.implicitHeight + text_padding)
    implicitWidth: box_width > 0 ? box_width : (button_text.implicitWidth + text_padding*2)

    color: {
        if (mouse.pressed && clickable) {
            return bg_color[2]
        } else if (mouse.containsMouse && clickable) {
            return bg_color[1]
        } else {
            return bg_color[0]
        }
    }

    radius: implicitHeight/2

    component ButtonText: Text {
        anchors.verticalCenterOffset: 0.8
        color: {
            if (mouse.pressed && button.clickable) {
                return button.fg_color[2]
            } else if (mouse.containsMouse && button.clickable) {
                return button.fg_color[1]
            } else {
                return button.fg_color[0]
            }
        }

        opacity: button.font_opacity

        font.family: button.font_family
        font.pointSize: button.font_size
        font.weight: button.font_weight
        font.wordSpacing: button.spacing
    }

    ButtonText {
        id: button_text
        visible: button.centered && !button.marqueeAble
        anchors.centerIn: parent
        text: button.text.trim() 
        opacity: button.text_opacity
    }

    ButtonText {
        visible: !button.centered || button.marqueeAble
        id: left_text
        anchors.verticalCenter: parent.verticalCenter

        opacity: button.text_opacity

        x: parent.x + button.text_padding - button.border.width

        text: button.text.trim()
    }


    Component.onCompleted: {
        if (button.marqueeAble) {
            button_text.text = "     " + button.text.trim()
            left_text.text = button.text.trim() + "     " + button.text.trim() + "     " + button.text.trim()
        } 
    }

    ParallelAnimation {
        id: marqueeAnim
        SequentialAnimation {
            PauseAnimation {duration: 500}
            NumberAnimation {
                target: left_text
                property: "x"
                from: button.text_padding
                to: -button_text.paintedWidth + button.text_padding
                duration: 10*(button_text.paintedWidth + button.implicitWidth)
                loops: Animation.Infinite
            }
        }
        ScriptAction { 
            script: {
                if (left_text.x==-button_text.paintedWidth + button.text_padding) {left_text.x = button.text_padding}
            }
        }
        SequentialAnimation {
            PauseAnimation {duration: 1000}
            ScriptAction {
                script: {
                    button_text.text = "       " + button.text.trim()
                    left_text.text = button.text.trim() + "       " + button.text.trim() + "       " + button.text.trim()
                }
            }
        }
    }

    NumberAnimation {
        id: returnAnimback
        target: left_text
        property: "x"
        duration: 1.2*(button_text.paintedWidth + button.implicitWidth)
        to: button.text_padding
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: returnAnimfor
        target: left_text
        property: "x"
        duration: 1.2*(button_text.paintedWidth + button.implicitWidth)
        to: -button_text.paintedWidth + button.text_padding
        easing.type: Easing.OutCubic
    }


    MouseControl {
        id: mouse

        visible: button.clickable

        anchors.fill: parent

        acceptedButtons: Qt.LeftButton

        preventStealing: true

        hoverEnabled: true

        onEntered: {if (button.marqueeAble) {marqueeAnim.start();}}
        onExited: {if (button.marqueeAble) {marqueeAnim.stop();
        if (left_text.x > -button_text.paintedWidth*(2/7)) {
            returnAnimback.start();
        } else {
            returnAnimfor.start();
        }
    }
}

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
