pragma ComponentBehavior:Bound

import qs.assets

import Quickshell
import Quickshell.Widgets
import QtQuick
import Qt5Compat.GraphicalEffects

ClippingRectangle {

    id: root

    property bool centered: true
    property int box_width: the_text.implicitWidth
    property string text: "Scrolling Text"
    property string font_family: Fonts.system
    property color font_color: "black"
    property int spacing: 0
    property real padding: 15
    property int font_weight: 500
    property real font_size: 15
    property real font_minSize: font_size
    property bool hoverable: false
    property bool manual: false

    property real textImplicitWidth: 0

    function entered() {
        if (root.hoverable && root.marqueeAble) marqueeAnim.start()
    }
    function exited() {
        if (root.hoverable && root.marqueeAble) {
            marqueeAnim.stop();
            if (the_text.x > -temp_text.paintedWidth*(2/7)) {
                marqueeAnimReturnBack.start();
            } else {
                marqueeAnimReturnFor.start();
            }
        }
    }

    property bool marqueeAble: temp_text.paintedWidth > implicitWidth

    implicitHeight: the_text.implicitHeight
    implicitWidth: box_width

    color: "transparent" 

    Text {
        id: the_text

        x: root.centered ? (root.implicitWidth-implicitWidth)/2 : root.padding

        text: root.text.trim()
        font.family: root.font_family
        font.pointSize: root.font_size
        font.weight: root.font_weight
        color: root.font_color
    }

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {

            implicitWidth: root.implicitWidth
            implicitHeight: root.implicitHeight

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {position: 0.0; color: "transparent"}
                GradientStop {position: root.padding/root.width; color: "white"}
                GradientStop {position: 1.0 - (root.padding/2)/root.width; color: "white"}
                GradientStop {position: 1.0; color: "transparent"}
            }
        }
    }

    Text {
        id: temp_text

        visible: false

        text: root.text.trim() + "⠀⠀⠀⠀⠀⠀⠀"
        font.family: root.font_family
        font.pointSize: root.font_size
        font.weight: root.font_weight

    }


    Component.onCompleted: {
        if (manual) return
        if (root.marqueeAble && !root.hoverable) marqueeAnim.start()
        textChanged()
    }

    MouseArea {

        z: 1

        visible: !root.manual

        anchors.fill: parent

        acceptedButtons: Qt.NoButton

        hoverEnabled: true

        onEntered: if (root.hoverable && root.marqueeAble) marqueeAnim.start()
        onExited: if (root.hoverable && root.marqueeAble) {
            marqueeAnim.stop();
            if (the_text.x > -temp_text.paintedWidth*(2/7)) {
                marqueeAnimReturnBack.start();
            } else {
                marqueeAnimReturnFor.start();
            }
        }
    }

    NumberAnimation {
        running: false
        id: marqueeAnimReturnBack
        target: the_text
        property: "x"
        to: root.padding
        duration: 1.2*(temp_text.paintedWidth + root.implicitWidth)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        running: false
        id: marqueeAnimReturnFor
        target: the_text
        property: "x"
        to: -temp_text.paintedWidth+root.padding
        duration: 1.2*(temp_text.paintedWidth + root.implicitWidth)
        easing.type: Easing.OutCubic
    }

    ParallelAnimation {
        id: marqueeAnim
        SequentialAnimation {
            PauseAnimation {duration: root.hoverable ? 800 : 2000}
            NumberAnimation {
                target: the_text
                property: "x"
                from: root.padding
                to: -temp_text.paintedWidth+root.padding
                duration: 18*(temp_text.paintedWidth + root.implicitWidth)
            }
        }
        ScriptAction {
            script: {
                if (the_text.x==-temp_text.paintedWidth+root.padding) {
                    the_text.x = root.padding
                }
            }
        }
        loops: Animation.Infinite
    }

    function checkMarquee() {
        marqueeAnim.stop()

        temp_text.text = root.text.trim() 
        the_text.text = root.text.trim() 
        temp_text.font.pointSize = root.font_size
        the_text.font.pointSize = root.font_size

        root.textImplicitWidth = the_text.paintedWidth

        temp_text.font.pointSize = Math.max(root.font_size - 0.08 * Math.max(root.textImplicitWidth+root.padding*2 - root.implicitWidth,0),root.font_minSize)
        the_text.font.pointSize = Math.max(root.font_size - 0.08 * Math.max(root.textImplicitWidth+root.padding*2 - root.implicitWidth,0),root.font_minSize)

        if (root.centered) {
            the_text.x = (root.implicitWidth-the_text.implicitWidth)/2 
        } else {
            the_text.x = root.padding
        }

        root.marqueeAble = temp_text.paintedWidth+root.padding > root.implicitWidth
        if (!marqueeAble) return
        temp_text.text = "⠀⠀⠀⠀⠀⠀⠀" + root.text.trim()
        the_text.text = root.text.trim() + "⠀⠀⠀⠀⠀⠀⠀" + root.text.trim() + "⠀⠀⠀⠀⠀⠀⠀" + root.text.trim()
        if (!root.hoverable) marqueeAnim.start()
    }

    onWidthChanged: {
        if (manual) return
        root.checkMarquee()
    }

    onTextChanged: {
        if (manual) return
        root.checkMarquee()
    }





}

