pragma ComponentBehavior:Bound

import qs.assets

import Quickshell
import Quickshell.Widgets
import QtQuick
import Qt5Compat.GraphicalEffects

ClippingRectangle {

    id: root

    property bool centered: true
    required property int box_width
    property string text: "Scrolling Text"
    property string font_family: Fonts.system
    property string font_color: "black"
    property int spacing: 0
    property int padding: 15
    property int font_weight: 500
    property int font_size: 15

    property bool marqueeAble: temp_text.paintedWidth+padding*2 > implicitWidth

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
                GradientStop {position: 1.0 - root.padding/root.width; color: "white"}
                GradientStop {position: 1.0; color: "transparent"}
            }
        }
    }

    Text {
        id: temp_text

        visible: false

        text: root.text.trim() + "     "
        font.family: root.font_family
        font.pointSize: root.font_size
        font.weight: root.font_weight

    }


    Component.onCompleted: {
        if (root.marqueeAble) marqueeAnim.start()
    }

    ParallelAnimation {
        id: marqueeAnim
        NumberAnimation {
            target: the_text
            property: "x"
            from: root.padding
            to: -temp_text.paintedWidth+root.padding
            duration: 15*(temp_text.paintedHeight + root.implicitWidth)
        }
        ScriptAction {
            script: {
                if (the_text.x==-temp_text.paintedWidth+root.padding) {
                    the_text.x = root.padding
                }
            }
        }
        SequentialAnimation {
            PauseAnimation {duration: 1000}
            ScriptAction {
                script: {
                    root.marqueeAble = temp_text.paintedWidth+root.padding*2 > root.implicitWidth
                    root.marqueeAble ? marqueeAnim.start() : marqueeAnim.stop()
                    temp_text.text = "     " + root.text.trim()
                    the_text.text = root.text.trim() + "     " + root.text.trim() + "     " + root.text.trim()
                }
            }
        }
        loops: Animation.Infinite
    }

    onTextChanged: {
        temp_text.text = root.text.trim()
        root.marqueeAble = temp_text.paintedWidth > root.implicitWidth
        if (!marqueeAble) return
        temp_text.text = root.text.trim() + "     "
        marqueeAnim.start()
    }

}

