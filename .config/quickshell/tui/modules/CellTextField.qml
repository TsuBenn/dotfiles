pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int w: 0
    property int h: 0

    property string text: ""

    property string placeholder: ""

    property bool showCursor : true
    property bool blinkCursor : true

    implicitWidth: root.w > 0 ? Cell.w(w) : input.implicitWidth
    implicitHeight: root.h > 0 ? Cell.h(h) : input.implicitHeight

    property font font: Cell.font
    property color color: Colors.fgBase
    property color disabled_color: Colors.fgSubtle

    property bool focusOnVisible: true

    property bool hidden: false
    property bool disabled: false

    signal entered(text: string)

    function resetCursor() {
        cursor_timer.restart()
        root.showCursor = true
    }

    onVisibleChanged: {
        resetCursor()
        text = ""
        if (visible && focusOnVisible) {
            focus = true
            return
        }
        focus = false
    }

    onTextChanged: {
        resetCursor()
    }

    function fieldFocus(on = true) {
        focus = on
    }

    Timer {

        id: cursor_timer

        running: root.blinkCursor && !root.disabled
        interval: 500
        repeat: true
        onTriggered: {
            root.showCursor = !root.showCursor
        }

    }

    CellText {

        visible: root.text.trim() == ""

        id: placeholder

        preferedW: root.w

        text: root.placeholder
        font: root.font
        color: root.disabled_color

    }

    CellText {

        visible: !root.hidden

        id: input

        preferedW: root.w

        text: root.text + (root.showCursor ? "█" : "")
        font: root.font
        color: root.disabled ? root.disabled_color : root.color

        MouseControl {
            anchors.fill: parent

            onPressed: (button) => {
                if (button == "L") {
                    root.focus = true
                }
            }
        }

    }

    RowLayout {

        visible: root.hidden

        spacing: 0

        Repeater {
            model: Math.max(Math.min(root.text.length,input.preferedW-1),0)

            delegate: CellText {
                text: "*"
                font: root.font
                color: root.disabled ? root.disabled_color : root.color
            }
        }

        CellText {
            text: (root.showCursor ? "█" : "")
            font: root.font
            color: root.disabled ? root.disabled_color : root.color
        }
    }

    Keys.onPressed: (event) => {
        if (root.disabled) return
        if (event.key == Qt.Key_Return) {
            root.entered(root.text)
        } else if (event.key == Qt.Key_Backspace && event.modifiers == Qt.ControlModifier) {
            root.text = root.text.replace(/\S+\s*$/, "")
        } else if (event.key == Qt.Key_Backspace) {
            root.text = root.text.slice(0,-1)
        } else if (event.text.length > 0 && event.text >= " ") {
            root.text += event.text
        }
    }

}
