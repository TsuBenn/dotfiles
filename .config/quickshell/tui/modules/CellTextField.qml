import qs.config
import qs.modules

import QtQuick

Item {

    id: root

    property int w: 0
    property int h: 0

    property string text: ""
    property bool showCursor : true
    property bool blinkCursor : true

    implicitWidth: root.w > 0 ? Cell.w(w) : input.implicitWidth
    implicitHeight: root.h > 0 ? Cell.h(h) : input.implicitHeight

    property font font: Cell.font
    property color color: Colors.fgBase

    property bool hidden: false

    signal entered(text: string)

    function resetCursor() {
        cursor_timer.restart()
        root.showCursor = true
    }

    onVisibleChanged: {
        resetCursor()
        text = ""
    }

    onTextChanged: {
        resetCursor()
    }

    Timer {

        id: cursor_timer

        running: root.blinkCursor
        interval: 500
        repeat: true
        onTriggered: {
            root.showCursor = !root.showCursor
        }

    }

    CellText {

        id: input

        preferedW: root.w

        text: (root.hidden ? "*".repeat(root.text.length) : root.text) + (root.showCursor ? "█" : "")
        font: root.font
        color: root.color

    }

    Keys.onPressed: (event) => {
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
