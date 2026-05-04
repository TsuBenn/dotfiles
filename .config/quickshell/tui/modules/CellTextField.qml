pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int w: 0
    property int h: 0

    property string text: ""

    property string placeholder: ""

    property string unit: "" 
    property string bindText: ""

    property bool autoClear: false

    property bool showCursor : true
    property bool blinkCursor : true

    property bool escapeToUnFocus : true

    property int cursorPos: 0
    property int visualPos: 0

    property bool visual: visualPos != 0

    property bool editable: true

    implicitWidth: root.w > 0 ? Cell.w(w) : text.length + 1
    implicitHeight: root.h > 0 ? Cell.h(h) : 1

    property font font: Cell.font
    property font fontB: Cell.fontB
    property color color: Colors.fgBase
    property color invert: Colors.bgSurface
    property color visual_color: Colors.secondary
    property color disabled_color: Colors.fgSubtle

    property bool focusOnVisible: true
    property bool autoApply: false

    property bool hidden: false
    property bool disabled: false

    signal entered(text: string)
    signal textInput(text: string, change: string, mode: string)
    signal textAdded(text: string)
    signal textRemoved(text: string)

    clip: true

    onFocusChanged: {
        if (focus) {
            TextFieldManager.activated()
            resetCursor()
        } else if (!focus) {
            TextFieldManager.deactivated()
            showCursor = false
        }

        if (autoApply && !focus) {
            entered(text)
            return
        }
        if (autoClear && focus) {
            set("")
        }
        if (bindText) {
            set(bindText)
        } 
    }

    onTextAdded: (text) => {
        textInput(root.text, text, "a")
    }
    onTextRemoved: (text) => {
        textInput(root.text, text, "r")
    }

    function grabFocus() {
        focus = true
    }

    function unFocus() {
        focus = false
    }

    function clear() {
        cursorPos = 0
        visualPos = 0
        resetCursor()
        text = root.bindText
        textfield.offset = 0
    }

    function set(new_text: string) {
        text = new_text
        cursorPos = text.length
    }

    function resetCursor() {
        cursor_timer.restart()
        root.showCursor = focus
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
        if (cursorPos + textfield.offset > (root.w - (root.unit.length > 0 ? root.unit.length - 1 : 0)) - 1) {
            textfield.offset -= 1
        }
        if (cursorPos + textfield.offset < 0) {
            textfield.offset += 1
            textfield.offset = Math.max(textfield.offset,0)
        }
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
            if (root.focus) {
                root.showCursor = !root.showCursor
                return
            }
            root.showCursor = false
        }

    }

    Item {

        id: textfield

        property int offset: 0

        x: Math.min(Cell.w(offset),0)

        implicitHeight: Cell.h(root.h)
        implicitWidth: Cell.w(root.w - (root.unit.length > 0 ? root.unit.length - 1 : 0))

        Loader {

            active: root.visible || !SettingsInfo.optimizeMemory

            sourceComponent: Item {

                CellText {

                    visible: root.text.length == 0

                    id: placeholder

                    text: root.placeholder
                    color: root.disabled_color

                }

                CellText {

                    visible: !root.hidden

                    id: input

                    text: root.text
                    font: root.font
                    color: root.disabled ? root.disabled_color : root.color

                }

                CellText {

                    text: " ".repeat(root.visualPos > 0 ? root.cursorPos : Math.max(root.cursorPos+root.visualPos,0)) + "█".repeat(Math.abs(root.visualPos))
                    font: root.font
                    color: root.visual_color

                }

                CellText {

                    id: cursor

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

                    text: " ".repeat(root.visualPos > 0 ? root.cursorPos : Math.max(root.cursorPos+root.visualPos,0)) + root.text.slice(root.visualPos > 0 ? root.cursorPos : root.cursorPos+root.visualPos, root.visualPos > 0 ? root.cursorPos+root.visualPos : root.cursorPos)
                    font: root.fontB
                    color: root.disabled ? root.disabled_color : root.invert

                }

                RowLayout {

                    visible: root.hidden

                    spacing: 0

                    Repeater {

                        model: root.text.length

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

            }
        }


    }

    CellText {

        preferedW: root.w

        text: " ".repeat(root.w - root.unit.length) +  root.unit
        font: root.font
        color: root.disabled ? root.disabled_color : root.color

    }

    MouseControl {

        visible: !root.disabled

        anchors.fill: parent

        onPressed: (button) => {
            if (button == "L") {
                root.focus = true
            }
        }
    }



    function delete_char_back() {
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
        if (root.cursorPos == 0) {
            root.textRemoved("")
            return
        }
        const removed = root.text[root.cursorPos-1]
        root.text = root.text.slice(0, root.cursorPos - 1) + root.text.slice(root.cursorPos)
        root.cursorPos -= 1
        root.textRemoved(removed)
    }

    function delete_word_back() {
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
    }

    function enter() {
        root.visualPos = 0
        root.entered(root.text)
    }

    function delete_char_forward() {
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
    }

    function select_char_back() {
        if (!root.editable) return
        if (root.cursorPos == 0) return
        root.cursorPos -= 1
        root.visualPos += 1
    }

    function select_char_forward() {
        if (!root.editable) return
        if (root.cursorPos == root.text.length) return
        root.cursorPos += 1
        root.visualPos -= 1
    }

    function select_char_forward_word() {
        if (!root.editable) return
        if (root.cursorPos == root.text.length) return
        if (root.text[Math.min(root.cursorPos+1,text.length)] != " " && root.cursorPos < root.text.length ) {
            root.cursorPos += 1
            root.visualPos -= 1
        }
        while (root.cursorPos < root.text.length && root.text[root.cursorPos] != " ") {
            root.cursorPos += 1
            root.visualPos -= 1
        }
    }

    function move_cursor_back() {
        if (!root.editable) return
        root.visualPos = 0
        root.cursorPos -= 1
        if (root.cursorPos < 0) {
            root.cursorPos = 0
        }
    }

    function move_cursor_back_word() {
        if (!root.editable) return
        root.visualPos = 0
        if (root.text[Math.max(root.cursorPos-1,0)] != " " && root.cursorPos > 0 ) root.cursorPos -= 1
        while (root.cursorPos > 0 && root.text[root.cursorPos] != " ") {
            root.cursorPos -= 1
        }
        if (root.cursorPos < 0) {
            root.cursorPos = 0
        }
    }

    function move_cursor_forward() {
        if (!root.editable) return
        root.visualPos = 0
        root.cursorPos += 1
        if (root.cursorPos > root.text.length) {
            root.cursorPos = root.text.length
        }
    }

    function move_cursor_forward_word() {
        if (!root.editable) return
        root.visualPos = 0
        if (root.text[Math.min(root.cursorPos+1,text.length)] != " " && root.cursorPos < root.text.length ) root.cursorPos += 1
        while (root.cursorPos < root.text.length && root.text[root.cursorPos] != " ") {
            root.cursorPos += 1
        }
        if (root.cursorPos < 0) {
            root.cursorPos = 0
        }
    }

    function select_all() {
        root.visualPos = -root.text.length
        root.cursorPos = root.text.length
    }

    function type(char: string) {
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
        root.text = root.text.slice(0, root.cursorPos) + char + root.text.slice(root.cursorPos)
        root.cursorPos += 1
        root.textAdded(char)
    }

    Keys.onPressed: (event) => {
        if (root.disabled) return
        if (event.key == Qt.Key_Return) {
            root.enter()
        } else if (event.key == Qt.Key_Escape) {
            if (root.escapeToUnFocus) {
                root.unFocus()
            }
        } else if (event.key == Qt.Key_Backspace && event.modifiers == Qt.ControlModifier) {
            root.delete_word_back()
        } else if (event.key == Qt.Key_Backspace) {
            root.delete_char_back()
        } else if (event.key == Qt.Key_Delete) {
            root.delete_char_forward()
        } else if (event.text.length > 0 && event.text >= " ") {
            root.type(event.text)
        } else if (event.key == Qt.Key_Left && event.modifiers == Qt.ControlModifier) {
            root.move_cursor_back_word()
        } else if (event.key == Qt.Key_Right && event.modifiers == Qt.ControlModifier) {
            root.move_cursor_forward_word()
        } else if (event.key == Qt.Key_Left && event.modifiers == Qt.ShiftModifier) {
            root.select_char_back()
        } else if (event.key == Qt.Key_Right && event.modifiers == Qt.ShiftModifier) {
            root.select_char_forward()
        } else if (event.key == Qt.Key_Left) {
            root.move_cursor_back()
        } else if (event.key == Qt.Key_Right) {
            root.move_cursor_forward()
        } else if (event.key == Qt.Key_A && event.modifiers == Qt.ControlModifier) {
            root.select_all()
        }
    }

}
