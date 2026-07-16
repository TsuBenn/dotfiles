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
    property bool canPaste: true

    property bool escapeToUnFocus: true
    property bool unfocusOnEntered: false

    property int cursorPos: 0
    property int visualPos: 0

    property bool visual: visualPos != 0
    property bool editable: root.text.length > 0
    property bool moveable: root.text.length > 0
    property bool vertMove: root.wrap
    property bool horiMove: true
    property bool canEnter: true

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

    // Scroll Offsets for Virtualization
    property int rowOffset: 0
    property int colOffset: 0

    signal entered(text: string)
    signal textInput(text: string, change: string, mode: string)
    signal textAdded(text: string)
    signal textCopied(text: string)
    signal textRemoved(text: string)

    onTextAdded: text => {
        textInput(root.text, text, "a");
    }

    onTextRemoved: text => {
        textInput(root.text, text, "r");
    }

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

    onCursorPosChanged: {
        resetCursor();
    }

    onBlinkCursorChanged: {
        showCursor = focus;
    }

    onVisibleChanged: {
        if (visible) {
            if (focusOnVisible) {
                grabFocus();
            }
        } else {
            unFocus();
        }
    }

    onDisabledChanged: {
        unFocus();
    }

    onFocusChanged: {
        if (focus) {
            if (disabled)
                unFocus();
            if (autoClear)
                clear();
            resetCursor();
            cursorPos = root.text.length;
            TextFieldManager.activated();
        } else {
            if (autoApply)
                enter();
            bind();
            showCursor = focus;
        }
    }

    Connections {
        target: TextFieldManager
        function onActive_fieldsChanged() {
            if (TextFieldManager.active_fields > 1) {
                TextFieldManager.deactivated();
            }
        }
    }

    Component.onCompleted: {
        bind();
    }

    onBindTextChanged: {
        bind();
    }

    function bind() {
        if (bindText != "" && !focus)
            root.text = root.bindText;
    }

    function isBetween(num, bound1, bound2): bool {
        const min = Math.min(bound1, bound2);
        const max = Math.max(bound1, bound2);

        return num >= min && num < max;
    }

    function grabFocus() {
        if (visible) {
            forceActiveFocus();
        }
    }

    function unFocus() {
        if (focus) {
            TextFieldManager.deactivated();
            focus = false;
        }
    }

    function set(str: string) {
        root.text = str;
        cursorPos = root.text.length;
    }

    function resetCursor() {
        cursorTimer.restart();
        showCursor = focus;
        cursorPos = Math.max(Math.min(cursorPos, root.text.length), 0);
    }

    function clear() {
        cursorPos = 0;
        visualPos = 0;
        resetCursor();
        set("");
    }

    function wrapText(str: string): var {
        if ((root.w == 0 || root.scroll) && !root.wrap)
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
        resetCursor();
    }

    RowLayout {
        spacing: Cell.w(1)

        Cells {
            id: text
            clip: true
            w: root.w - unit.w - (unit.w ? 1 : 0)
            h: root.h
            color: "transparent"

            SequentialAnimation {
                id: copy_anim
                ColorAnimation {
                    target: text
                    property: "color"
                    duration: 0
                    to: root.color
                    easing.type: Easing.OutCubic
                }
                ColorAnimation {
                    target: text
                    property: "color"
                    duration: 500
                    to: "transparent"
                    easing.type: Easing.OutCubic
                }
            }

            CellText {
                visible: root.text.length == 0
                text: root.placeholder
                color: root.disabled_color
                preferedH: text.h
                preferedW: text.w
                wrap: true
            }

            ColumnLayout {
                id: text_input
                spacing: 0

                Component.onCompleted: {
                    root.cursorPosChanged.connect(() => {
                        if (!root.wrap && root.scroll) {
                            let current_col = root.cursorPos;
                            if (current_col >= root.colOffset + text.w) {
                                root.colOffset = current_col - text.w + 1;
                            } else if (current_col < root.colOffset) {
                                root.colOffset = current_col;
                            }
                        } else if (root.wrap && root.scroll) {
                            let current_row = Math.floor(root.cursorPos / text.w);
                            if (current_row >= root.rowOffset + text.h) {
                                root.rowOffset = current_row - text.h + 1;
                            } else if (current_row < root.rowOffset) {
                                root.rowOffset = current_row;
                            }
                        }
                    });
                }

                Repeater {
                    model: root.h // Fixed rows count based on viewport height

                    delegate: RowLayout {
                        id: text_line
                        required property int index
                        spacing: 0

                        readonly property int virtualRow: index + root.rowOffset
                        readonly property var lineData: root.processed_text[virtualRow] ?? ""

                        Repeater {
                            model: text.w // Fixed columns count based on viewport width

                            delegate: CellText {
                                id: text_char
                                required property int index

                                readonly property int virtualCol: index + root.colOffset
                                readonly property int absolutePos: root.wrap ? (text_line.virtualRow * text.w + virtualCol) : virtualCol
                                readonly property bool selected: root.isBetween(absolutePos, root.cursorPos, root.cursorPos + root.visualPos) && root.visualPos != 0

                                // Check if character exists in data model, otherwise fallback to empty space
                                text: absolutePos < root.text.length ? (root.hidden ? "*" : (text_line.lineData[virtualCol] ?? " ")) : " "

                                color: root.disabled ? root.disabled_color : (selected ? root.invert : root.color)
                                bg: selected ? root.visual_color : "transparent"
                                font: selected ? root.fontB : root.font
                            }
                        }
                    }
                }
            }

            CellText {
                visible: !root.disabled && root.showCursor && root.focus

                // Calculate position relative to fixed layout frame
                x: root.wrap ? Cell.w(root.cursorPos % text.w) : Cell.w(root.cursorPos - root.colOffset)

                y: root.wrap ? Cell.h(Math.floor(root.cursorPos / text.w) - root.rowOffset) : 0

                color: root.invert
                bg: root.color
                font: root.fontB
                text: root.text[root.cursorPos] ? (root.hidden ? "*" : root.text[root.cursorPos]) : " "
            }

            MouseControl {
                anchors.fill: parent
                onPressed: button => {
                    if (button == "L") {
                        root.grabFocus();
                    } else if (button == "R") {
                        root.grabFocus();
                        root.select_all();
                    }
                }
            }
        }

        CellText {
            id: unit
            Layout.alignment: Qt.AlignTop
            text: root.unit
            color: root.disable ? root.disabled_color : root.color
        }
    }

    function type(c: string) {
        if (visualPos != 0) {
            delete_selections();
        }
        root.text = root.text.slice(0, cursorPos) + c + root.text.slice(cursorPos);
        root.cursorPos += c.length;
        root.textAdded(c);
    }

    function move_line_up() {
        if (cursorPos < text.w)
            return;
        for (let i = 0; i < text.w; i++) {
            move_char_left();
            if (cursorPos == 0) {
                break;
            }
        }
        return true;
    }

    function extend_line_up() {
        if (cursorPos < text.w)
            return;
        for (let i = 0; i < text.w; i++) {
            extend_char_left();
            if (cursorPos == 0) {
                break;
            }
        }
        return true;
    }

    function move_line_down() {
        if (cursorPos == root.text.length)
            return;
        for (let i = 0; i < text.w; i++) {
            move_char_right();
            if (cursorPos == root.text.length) {
                break;
            }
        }
        return true;
    }

    function extend_line_down() {
        if (cursorPos == root.text.length)
            return;
        for (let i = 0; i < text.w; i++) {
            extend_char_right();
            if (cursorPos == root.text.length) {
                break;
            }
        }
        return true;
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

    function delete_char_left(track = true) {
        if (visualPos != 0) {
            delete_selections();
            return;
        }
        if (cursorPos == 0) {
            root.textRemoved("");
            return false;
        }
        let rm = root.text[cursorPos - 1];
        root.text = root.text.slice(0, cursorPos - 1) + root.text.slice(cursorPos);
        root.cursorPos;
        if (track)
            root.textRemoved(rm);
        return true;
    }

    function delete_word_left() {
        if (visualPos != 0) {
            delete_selections();
            return;
        }
        let rm = "";
        if (cursorPos == 0) {
            root.textRemoved("");
            return false;
        }
        do {
            delete_char_left(false);
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

    function delete_selections() {
        let min = Math.min(cursorPos, cursorPos + visualPos);
        let max = Math.max(cursorPos, cursorPos + visualPos);
        let rm = root.text.slice(min, max);
        root.text = root.text.slice(0, min) + root.text.slice(max);
        visualPos = 0;
        cursorPos = min;
        root.textRemoved(rm);
    }

    function select_all() {
        if (root.text.length == 0)
            return false;
        cursorPos = root.text.length;
        visualPos = -(root.text.length);
        return true;
    }

    function copy(str: string) {
        copy_anim.restart();
        SystemInfo.copy_clipboard(str);
        textCopied(str);
    }

    function copy_selections() {
        if (!canCopy)
            return;
        let min = Math.min(cursorPos, cursorPos + visualPos);
        let max = Math.max(cursorPos, cursorPos + visualPos);
        let cp = root.text.slice(min, max + 1);
        copy(cp);
    }

    function paste() {
        const to_paste = ClipboardInfo.clipboard[0];
        // console.log(JSON.stringify(to_paste));
        if (to_paste.type.includes("text"))
            type(to_paste.data);
    }

    function enter() {
        entered(root.text);
        if (unfocusOnEntered && focus)
            unFocus();
    }

    function cut_selections() {
        if (!canCopy)
            return;
        copy_selections();
        delete_selections();
    }

    Keys.onPressed: event => {
        // console.log(JSON.stringify(event, null, 2));
        const shift = Qt.ShiftModifier;
        const ctrl = Qt.ControlModifier;
        const mod = event.modifiers;
        const key = event.key;
        const etext = event.text;
        if (event.key == Qt.Key_Backspace) {
            if (mod & ctrl)
                root.delete_word_left();
            else
                root.delete_char_left();
        } else if (event.key == Qt.Key_Return) {
            if (root.canEnter)
                root.enter();
            else
                return;
        } else if (event.key == Qt.Key_Escape) {
            if (escapeToUnFocus)
                root.unFocus();
            else
                return;
        } else if (event.key == Qt.Key_Delete) {
            root.delete_char_right();
        } else if (event.key == Qt.Key_Up) {
            if (mod & shift) {
                if (!root.editable || !root.wrap)
                    return;
                root.extend_line_up();
            } else {
                if (!root.moveable || !root.vertMove)
                    return;
                root.move_line_up();
            }
        } else if (event.key == Qt.Key_Down) {
            if (mod & shift) {
                if (!root.editable || !root.wrap)
                    return;
                root.extend_line_down();
            } else {
                if (!root.moveable || !root.vertMove)
                    return;
                root.move_line_down();
            }
        } else if (event.key == Qt.Key_Right) {
            if ((mod & ctrl) && (mod & shift)) {
                if (!root.editable)
                    return;
                root.extend_word_right();
            } else if (mod & ctrl) {
                {
                    if (!root.moveable || !root.horiMove)
                        return;
                    root.move_word_right();
                }
            } else if (mod & shift) {
                if (!root.editable)
                    return;
                root.extend_char_right();
            } else {
                if (!root.moveable || !root.horiMove)
                    return;
                root.move_char_right();
            }
        } else if (event.key == Qt.Key_Left) {
            if ((mod & ctrl) && (mod & shift)) {
                if (!root.editable)
                    return;
                root.extend_word_left();
            } else if (mod & ctrl) {
                if (!root.moveable || !root.horiMove)
                    return;
                root.move_word_left();
            } else if (mod & shift) {
                if (!root.editable)
                    return;
                root.extend_char_left();
            } else {
                if (!root.moveable || !root.horiMove)
                    return;
                root.move_char_left();
            }
        } else if (mod & ctrl) {
            if (event.key == Qt.Key_A) {
                if (!root.editable)
                    return;
                root.select_all();
            } else if (event.key == Qt.Key_C) {
                if (!root.canCopy)
                    return;
                root.copy_selections();
            } else if (event.key == Qt.Key_X) {
                if (!root.canCopy)
                    return;
                root.cut_selections();
            } else if (event.key == Qt.Key_V) {
                if (!root.canPaste)
                    return;
                root.paste();
            } else
                return;
        } else if (etext.length > 0 && etext >= " ") {
            root.type(etext);
        } else
            return;
        // console.log("accepted");
        event.accepted = true;
    }
}
