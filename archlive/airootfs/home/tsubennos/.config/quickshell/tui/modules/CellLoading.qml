import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int style: 0
    property int pulseInterval: 200

    property int frame: 0

    property string text: ""
    property color color: Colors.fgBase
    property font font: Cell.font

    implicitWidth: loading.implicitWidth
    implicitHeight: loading.implicitHeight

    RowLayout {

        id: loading

        spacing: 0

        CellText {
            visible: root.text != ""
            text: root.text
            color: root.color
            font: root.font
        }

        CellText {
            visible: root.style > 0
            text: " "
            color: root.color
            font: root.font
        }

        CellText {

            property var frames: [".  ", ".. ", "..."]

            visible: root.style == 0
            text: frames[root.frame % frames.length]
            pure: false
            lockPure: true
        }

        CellText {

            property var frames: ["-","\\","|","/"]

            visible: root.style == 1
            text: frames[root.frame % frames.length]
            pure: false
            lockPure: true
        }

        CellText {

            property var frames: ["⠇", "⠋", "⠙", "⠸", "⢰", "⣠", "⣄", "⡆"]

            visible: root.style == 2
            text: frames[root.frame % frames.length]
            pure: false
            lockPure: true
        }

    }

    Timer {
        interval: root.pulseInterval
        running: root.visible
        repeat: true
        onTriggered: {
            root.frame++
        }
    }

}
