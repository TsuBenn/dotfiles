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
    property font fontB: Cell.fontB
    property color color: Colors.fgBase
    property color invert: Colors.bgSurface
    property color visual_color: Colors.secondary
    property color disabled_color: Colors.fgSubtle

    property bool focusOnVisible: true

    property bool hidden: false
    property bool disabled: false

    signal entered(text: string)
    signal textInput(text: string, change: string, mode: string)
    signal textAdded(text: string)
    signal textRemoved(text: string)

    onTextAdded: (text) => {
        textInput(root.text, text, "a")
    }
    onTextRemoved: (text) => {
        textInput(root.text, text, "r")
    }

    function clear() {
        cursorPos = 0
        visualPos = 0
        resetCursor()
        text = ""
    }

    function set(new_text: string) {
        text = new_text
        cursorPos = text.length
    }

    function resetCursor() {
        cursor_timer.restart()
        root.showCursor = true
    }

    onVisibleChanged: {
        clear()
        if (visible && focusOnVisible) {
            focus = true
            return
        }
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

        text: " ".repeat(root.visualPos > 0 ? root.cursorPos : Math.max(root.cursorPos+root.visualPos,0)) + "█".repeat(Math.abs(root.visualPos))
        font: root.font
        color: root.visual_color

    }

    CellText {

        id: cursor

        preferedW: root.w

        text: " ".repeat(root.cursorPos) + (root.showCursor && !(root.visual && root.cursorPos == root.text.length) ? "█" : "")
        font: root.font
        color: root.disabled ? root.disabled_color : root.color

        CellText {

            visible: root.showCursor && !root.hidden

            text: " ".repeat(root.cursorPos) + (root.text[root.cursorPos] ?? "")
            color: root.invert

        }

    }

    CellText {

        id: visual

        visible: !root.hidden

        preferedW: root.w

        text: " ".repeat(root.visualPos > 0 ? root.cursorPos : Math.max(root.cursorPos+root.visualPos,0)) + root.text.slice(root.visualPos > 0 ? root.cursorPos : root.cursorPos+root.visualPos, root.visualPos > 0 ? root.cursorPos+root.visualPos : root.cursorPos)
        font: root.fontB
        color: root.disabled ? root.disabled_color : root.invert

    }

    MouseControl {
        anchors.fill: parent

        onPressed: (button) => {
            if (button == "L") {
                root.focus = true
            }
        }
    }


    RowLayout {

        visible: root.hidden

        spacing: 0

        Repeater {
            model: Math.max(Math.min(root.text.length,input.preferedW-1),0)

            delegate: CellText {

                required property int index

                property bool invert: {
                    if (root.visualPos > 0 && index >= root.cursorPos && index < root.cursorPos+root.visualPos) {
                        return true
                    } else if (root.visualPos < 0 && index <= root.cursorPos && index > root.cursorPos+root.visualPos) {
                        return true
                    }
                    return false
                }

                text: "*"
                font: invert ? root.fontB : root.font
                color: root.disabled ? root.disabled_color : (invert ? root.invert : root.color)
            }
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
                    const removed = root.text.slice(root.cursorPos,root.cursorPos+root.visualPos)
                    root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos+root.visualPos, root.text.length)
                    root.textRemoved(removed)
                }
                if (root.visualPos < 0) {
                    const removed = root.text.slice(root.cursorPos+root.visualPos,root.cursorPos)
                    root.text = root.text.slice(0, root.cursorPos+root.visualPos) + root.text.slice(root.cursorPos, root.text.length)
                    root.cursorPos = root.cursorPos+root.visualPos
                    root.textRemoved(removed)
                }
                root.visualPos = 0
                return
            }
            const removed = root.text.match(/\S+\s*$/)[0]
            root.text = root.text.replace(/\S+\s*$/, "")
            if (removed) {
                root.cursorPos -= removed.length
                root.textRemoved(removed)
            } 
            else root.textRemoved("")
        } else if (event.key == Qt.Key_Backspace) {
            if (root.visual) {
                if (root.visualPos > 0) {
                    const removed = root.text.slice(root.cursorPos,root.cursorPos+root.visualPos)
                    root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos+root.visualPos, root.text.length)
                    root.textRemoved(removed)
                }
                if (root.visualPos < 0) {
                    const removed = root.text.slice(root.cursorPos+root.visualPos,root.cursorPos)
                    root.text = root.text.slice(0, root.cursorPos+root.visualPos) + root.text.slice(root.cursorPos, root.text.length)
                    root.cursorPos = root.cursorPos+root.visualPos
                    root.textRemoved(removed)
                }
                root.visualPos = 0
                return
            }
            if (root.cursorPos == 0) return
            const removed = root.text[root.cursorPos-1]
            root.text = root.text.slice(0, root.cursorPos - 1) + root.text.slice(root.cursorPos)
            root.cursorPos -= 1
            root.textRemoved(removed)
        } else if (event.key == Qt.Key_Delete) {
            if (root.visual) {
                if (root.visualPos > 0) {
                    const removed = root.text.slice(root.cursorPos,root.cursorPos+root.visualPos)
                    root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos+root.visualPos, root.text.length)
                    root.textRemoved(removed)
                }
                if (root.visualPos < 0) {
                    const removed = root.text.slice(root.cursorPos+root.visualPos,root.cursorPos)
                    root.text = root.text.slice(0, root.cursorPos+root.visualPos) + root.text.slice(root.cursorPos, root.text.length)
                    root.cursorPos = root.cursorPos+root.visualPos
                    root.textRemoved(removed)
                }
                root.visualPos = 0
                return
            }
            const removed = root.text[root.cursorPos]
            if (root.cursorPos == root.text.length) return
            root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos + 1)
            root.textRemoved(removed)
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
            root.textAdded(event.text)
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
