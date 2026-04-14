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

    property int cursorPos: 0
    property int visualPos: 0

    property bool visual: visualPos != 0

    implicitWidth: root.w > 0 ? Cell.w(w) : input.implicitWidth
    implicitHeight: root.h > 0 ? Cell.h(h) : input.implicitHeight

    property font font: Cell.font
    property color color: Colors.fgBase
    property color invert: Colors.bgSurface
    property color visual_color: Colors.fgSubtle
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
        cursorPos = 0
        visualPos = 0
        focus = false
    }

    onCursorPosChanged: {
        resetCursor()
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

        text: root.text
        font: root.font
        color: root.disabled ? root.disabled_color : root.color

    }

    CellText {

        preferedW: root.w

        text: " ".repeat(root.visualPos > 0 ? root.cursorPos : root.cursorPos+root.visualPos) + "█".repeat(Math.abs(root.visualPos))
        font: root.font
        color: root.visual_color

    }
    CellText {

        id: visual

        preferedW: root.w

        text: " ".repeat(root.visualPos > 0 ? root.cursorPos : root.cursorPos+root.visualPos) + root.text.slice(root.visualPos > 0 ? root.cursorPos : root.cursorPos+root.visualPos, root.visualPos > 0 ? root.cursorPos+root.visualPos : root.cursorPos)
        font: root.font
        color: root.disabled ? root.disabled_color : root.color

    }

    MouseControl {
        anchors.fill: parent

        onPressed: (button) => {
            if (button == "L") {
                root.focus = true
            }
        }
    }

    CellText {

        visible: !root.hidden

        id: cursor

        preferedW: root.w

        text: " ".repeat(root.cursorPos) + (root.showCursor && !(root.visual && root.cursorPos == root.text.length) ? "█" : "")
        font: root.font
        color: root.disabled ? root.disabled_color : root.color

        CellText {

            visible: root.showCursor

            text: " ".repeat(root.cursorPos) + (root.text[root.cursorPos] ?? "")
            color: root.invert

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
            root.visualPos = 0
            root.entered(root.text)
        } else if (event.key == Qt.Key_Backspace && event.modifiers == Qt.ControlModifier) {
            if (root.visual) {
                if (root.visualPos > 0) {
                    root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos+root.visualPos, root.text.length)
                }
                if (root.visualPos < 0) {
                    root.text = root.text.slice(0, root.cursorPos+root.visualPos) + root.text.slice(root.cursorPos, root.text.length)
                    root.cursorPos = root.cursorPos+root.visualPos
                }
                root.visualPos = 0
                return
            }
            root.text = root.text.replace(/\S+\s*$/, "")
        } else if (event.key == Qt.Key_Backspace) {
            if (root.visual) {
                if (root.visualPos > 0) {
                    root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos+root.visualPos, root.text.length)
                }
                if (root.visualPos < 0) {
                    root.text = root.text.slice(0, root.cursorPos+root.visualPos) + root.text.slice(root.cursorPos, root.text.length)
                    root.cursorPos = root.cursorPos+root.visualPos
                }
                root.visualPos = 0
                return
            }
            if (root.cursorPos == 0) return
            root.text = root.text.slice(0, root.cursorPos - 1) + root.text.slice(root.cursorPos)
            root.cursorPos -= 1
        } else if (event.key == Qt.Key_Delete) {
            if (root.visual) {
                if (root.visualPos > 0) {
                    root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos+root.visualPos, root.text.length)
                }
                if (root.visualPos < 0) {
                    root.text = root.text.slice(0, root.cursorPos+root.visualPos) + root.text.slice(root.cursorPos, root.text.length)
                    root.cursorPos = root.cursorPos+root.visualPos
                }
                root.visualPos = 0
                return
            }
            if (root.cursorPos == root.text.length) return
            root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos + 1)
        } else if (event.text.length > 0 && event.text >= " ") {
            if (root.visual) {
                if (root.visualPos > 0) {
                    root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos+root.visualPos, root.text.length)
                }
                if (root.visualPos < 0) {
                    root.text = root.text.slice(0, root.cursorPos+root.visualPos) + root.text.slice(root.cursorPos, root.text.length)
                    root.cursorPos = root.cursorPos+root.visualPos
                }
                root.visualPos = 0
            }
            root.text = root.text.slice(0, root.cursorPos) + event.text + root.text.slice(root.cursorPos)
            root.cursorPos += 1
        } else if (event.key == Qt.Key_Left && event.modifiers == Qt.ShiftModifier) {
            if (root.cursorPos == 0) return
            root.cursorPos -= 1
            root.visualPos += 1
        } else if (event.key == Qt.Key_Right && event.modifiers == Qt.ShiftModifier) {
            if (root.cursorPos == root.text.length) return
            root.cursorPos += 1
            root.visualPos -= 1
        } else if (event.key == Qt.Key_Left) {
            root.visualPos = 0
            root.cursorPos -= 1
            if (root.cursorPos < 0) {
                root.cursorPos = 0
            }
        } else if (event.key == Qt.Key_Right) {
            root.visualPos = 0
            root.cursorPos += 1
            if (root.cursorPos > root.text.length) {
                root.cursorPos = root.text.length
            }
        } else if (event.key == Qt.Key_A && event.modifiers == Qt.ControlModifier) {
            root.visualPos = -root.text.length
            root.cursorPos = root.text.length
        }
    }

}
