pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property int w: 0
    property int h: 1

    property string text: ""

    property string placeholder: ""

    property string unit: ""
    property string bindText: ""

    property bool autoClear: false

    property bool showCursor: false
    property bool blinkCursor: true

    property bool canCopy: true

    property bool escapeToUnFocus: true
    property bool unfocusOnEntered: false

    property int cursorPos: 0
    property int visualPos: 0

    property bool visual: visualPos != 0

    property bool editable: true

    property bool scroll: true
    property bool wrap: false

    implicitWidth: root.w > 0 ? Cell.w(w) : root.text.length + 1
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
    signal textCopied(text: string)
    signal textRemoved(text: string)

    clip: true

    property var processed_text: [""]

    Timer {
        id: cursorTimer
        running: root.visible && root.blinkCursor && root.focus
        repeat: true
        interval: 500
        onTriggered: {
            root.showCursor = !root.showCursor;
        }
    }

    onBlinkCursorChanged: {
        showCursor = focus;
    }

    onVisibleChanged: {
        if (visible) {
            if (focusOnVisible) {
                grabFocus();
            }
        }
    }

    onFocusChanged: {
        if (focus) {
            resetCursor();
        } else {
            showCursor = focus;
        }
    }

    function isBetween(num, bound1, bound2): bool {
        const min = Math.min(bound1, bound2);
        const max = Math.max(bound1, bound2);

        return num >= min && num <= max;
    }

    function grabFocus() {
        if (visible) {
            forceActiveFocus();
        }
    }

    function unFocus() {
        focus = false;
    }

    function set(str: string) {
        textRemoved(text);
        root.text = str;
        textAdded(text);
    }

    function resetCursor() {
        cursorTimer.restart();
        showCursor = focus;
    }

    function clear() {
        cursorPos = 0;
        visualPos = 0;
        resetCursor();
        set("");
    }

    function wrapText(str: string): var {
        console.log("str: " + str);
        if (root.w == 0)
            return [str];
        let result = [];
        let buffer = "";
        for (const c of str) {
            if (c == "\n") {
                result.push(buffer);
                buffer = "";
                continue;
            }
            buffer += c;
            if (buffer.length == root.w) {
                result.push(buffer);
                buffer = "";
            }
        }
        if (buffer) {
            result.push(buffer);
        }
        return result;
    }

    onTextChanged: {
        root.processed_text = wrapText(root.text);
        console.log(processed_text);
    }

    RowLayout {

        spacing: Cell.w(1)

        Cells {
            id: text

            clip: true

            w: root.w - unit.w - 1
            h: root.h

            color: "transparent"

            CellText {
                visible: root.text.length == 0
                text: root.placeholder
                color: root.disabled_color
                preferedH: text.h
                preferedW: text.w
                wrap: true
            }

            ColumnLayout {

                spacing: 0

                Repeater {

                    model: root.processed_text.length

                    delegate: RowLayout {
                        id: text_line

                        required property int index

                        property string line: root.processed_text[index] ?? ""

                        spacing: 0

                        Repeater {

                            model: text_line.line.length

                            delegate: CellText {
                                id: text_char

                                required property int index

                                property bool selected: root.isBetween(getPos(), root.cursorPos, root.cursorPos + root.visualPos) && root.visualPos != 0

                                function getPos(): int {
                                    return index + text_line.index;
                                }

                                text: root.hidden ? "*" : (text_line.line[index] ?? " ")
                                color: root.disabled ? root.disabled_color : (selected ? root.invert : root.color)
                                bg: selected ? root.visual_color : "transparent"
                            }
                        }
                    }
                }
            }

            CellText {

                visible: !root.disabled && root.showCursor

                x: Cell.w(root.cursorPos % text.w)
                y: Cell.h(Math.floor(root.cursorPos / text.w))

                color: root.invert
                bg: root.color

                text: root.text[root.cursorPos] ?? " "
            }
        }

        CellText {
            id: unit
            Layout.alignment: Qt.AlignTop

            text: root.unit

            color: root.color
        }
    }

    function type(c: string) {
        if (visualPos != 0) {
            delete_selections();
        }
        root.text = root.text.slice(0, cursorPos) + c + root.text.slice(cursorPos);
        root.cursorPos++;
        root.textAdded(c);
    }

    function move_word_left() {
        if (cursorPos == 0)
            return false;
        do {
            cursorPos--;
            if (cursorPos == 0)
                break;
        } while (root.text[cursorPos - 1] != " ")
        return true;
    }

    function move_char_left() {
        visualPos = 0;
        if (cursorPos == 0)
            return false;
        cursorPos--;
        return true;
    }

    function extend_char_left() {
        if (cursorPos == 0)
            return false;
        cursorPos--;
        visualPos++;
        return true;
    }

    function extend_word_left() {
        if (cursorPos == 0)
            return false;
        do {
            extend_char_left();
            if (cursorPos == 0)
                break;
        } while (root.text[cursorPos - 1] != " ")
        return true;
    }

    function move_word_right() {
        if (cursorPos == root.text.length)
            return false;
        do {
            cursorPos++;
            if (cursorPos == root.text.length)
                break;
        } while (root.text[cursorPos] != " ")
        return true;
    }

    function move_char_right(): bool {
        visualPos = 0;
        if (cursorPos == root.text.length)
            return false;
        cursorPos++;
        return true;
    }

    function extend_char_right() {
        if (cursorPos == root.text.length)
            return false;
        cursorPos++;
        visualPos--;
        return true;
    }

    function extend_word_right() {
        if (cursorPos == root.text.length)
            return false;
        do {
            extend_char_right();
            if (cursorPos == root.text.length)
                break;
        } while (root.text[cursorPos] != " ")
        return true;
    }

    function select_all() {
        if (cursorPos == 0)
            return false;
        cursorPos = root.text.length - 1;
        visualPos = -(root.text.length - 1);
        return true;
    }

    function delete_selections() {
        let min = Math.min(cursorPos, cursorPos + visualPos);
        let max = Math.max(cursorPos, cursorPos + visualPos);
        let rm = root.text.slice(min, max + 1);
        root.text = root.text.slice(0, min) + root.text.slice(max + 1);
        visualPos = 0;
        cursorPos = min;
        root.textRemoved(rm);
    }

    function delete_char_left() {
        if (visualPos != 0) {
            delete_selections();
            return;
        }
        if (cursorPos == 0)
            return false;
        let rm = root.text[cursorPos - 1];
        root.text = root.text.slice(0, cursorPos - 1) + root.text.slice(cursorPos);
        root.cursorPos--;
        root.textRemoved(rm);
        return true;
    }

    function delete_word_left() {
        if (visualPos != 0) {
            delete_selections();
            return;
        }
        let rm = "";
        if (cursorPos == 0)
            return false;
        do {
            delete_char_left();
            if (cursorPos == 0)
                break;
        } while (root.text[cursorPos - 1] != " ")
        root.textRemoved(rm);
        return true;
    }

    function delete_char_right() {
        if (visualPos != 0) {
            delete_selections();
            return;
        }
        let rm = root.text[cursorPos];
        root.text = root.text.slice(0, cursorPos) + root.text.slice(cursorPos + 1);
        root.cursorPos;
        root.textRemoved(rm);
        return rm ? true : false;
    }

    Keys.onPressed: event => {
        console.log(JSON.stringify(event, null, 2));
        const shift = Qt.ShiftModifier;
        const ctrl = Qt.ControlModifier;
        const mod = event.modifiers;
        const key = event.key;
        const etext = event.text;
        resetCursor();
        if (event.key == Qt.Key_Backspace) {
            if (mod & ctrl)
                root.delete_word_left();
            else
                root.delete_char_left();
        } else if (event.key == Qt.Key_Delete) {
            root.delete_char_right();
        } else if (event.key == Qt.Key_Right) {
            if ((mod & ctrl) && (mod & shift)) {
                root.extend_word_right();
            } else if (mod & ctrl) {
                root.move_word_right();
            } else if (mod & shift)
                root.extend_char_right();
            else {
                root.move_char_right();
            }
        } else if (event.key == Qt.Key_Left) {
            if ((mod & ctrl) && (mod & shift)) {
                root.extend_word_left();
            } else if (mod & ctrl) {
                root.move_word_left();
            } else if (mod & shift)
                root.extend_char_left();
            else {
                root.move_char_left();
            }
        } else if (mod & ctrl) {
            if (event.key == Qt.Key_A)
                root.select_all();
        } else if (etext.length > 0 && etext >= " ") {
            root.type(etext);
        } else {
            return;
        }
        event.accepted = true;
    }
}
