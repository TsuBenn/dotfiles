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
    signal textCopied(text: string)
    signal textRemoved(text: string)

    clip: true

    onEntered: {
        if (unfocusOnEntered)
            unFocus();
    }

    onDisabledChanged: {
        unFocus();
        if (!disabled && focusOnVisible && visible) {
            grabFocus();
        }
    }

    function refresh() {
        visibleChanged();
    }

    onFocusChanged: {
        if (focus) {
            if (disabled) {
                unFocus();
                return;
            }
            if (autoClear) {
                set("");
            } else if (bindText) {
                text = Qt.binding(() => bindText);
                cursorPos = bindText.length;
            }
            TextFieldManager.activated();
            resetCursor();
        } else if (!focus) {
            TextFieldManager.deactivated();
            showCursor = false;
            visualPos = 0;
            if (autoApply) {
                if (text != bindText)
                    entered(text);
            }
            if (bindText) {
                text = Qt.binding(() => bindText);
                cursorPos = bindText.length;
                return;
            }
        }
    }

    onTextAdded: text => {
        textInput(root.text, text, "a");
    }
    onTextRemoved: text => {
        textInput(root.text, text, "r");
    }

    function grabFocus() {
        if (visible) {
            forceActiveFocus();
        }
    }

    function unFocus() {
        focus = false;
    }

    function clear() {
        cursorPos = 0;
        visualPos = 0;
        resetCursor();
        text = root.bindText;
        textfield.offset = 0;
    }

    function set(new_text: string) {
        text = new_text;
        cursorPos = text.length;
    }

    function resetCursor() {
        cursor_timer.restart();
        root.showCursor = focus;
    }

    onVisibleChanged: {
        if (autoClear) {
            clear();
        }
        if (bindText != "") {
            text = Qt.binding(() => bindText);
        }
        if (visible && focusOnVisible) {
            grabFocus();
            return;
        }
        unFocus();
    }

    onCursorPosChanged: {
        resetCursor();
        if (cursorPos + textfield.offset > (root.w - (root.unit.length > 0 ? root.unit.length - 1 : 0)) - 1) {
            textfield.offset -= 1;
        }
        if (cursorPos + textfield.offset < 0) {
            textfield.offset += 1;
            textfield.offset = Math.max(textfield.offset, 0);
        }
    }

    onTextChanged: {
        resetCursor();
    }

    Component.onCompleted: {
        TextFieldManager.unFocusAll.connect(() => {
            if (root) {
                root.unFocus();
            }
        });
        root.visibleChanged();
    }

    Timer {
        id: cursor_timer

        running: (root.blinkCursor && !root.disabled && root.focus) || root.showCursor
        interval: 500
        repeat: true
        onTriggered: {
            if (root.focus) {
                root.showCursor = !root.showCursor;
                return;
            }
            root.showCursor = false;
        }
    }

    onTextCopied: {
        copied_anim.restart();
    }

    SequentialAnimation {
        id: copied_anim
        ColorAnimation {
            target: snap
            property: "color"
            to: root.color
            duration: 0
        }
        ColorAnimation {
            target: snap
            property: "color"
            to: Colors.transparent(root.color, 0)
            duration: 500
            easing.type: Easing.OutCubic
        }
        ColorAnimation {
            target: snap
            property: "color"
            to: "transparent"
            duration: 0
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {

        spacing: 0

        Item {
            id: textfield

            property int offset: 0

            Layout.leftMargin: (!root.wrap && root.scroll) ? Math.min(Cell.w(offset), 0) : 0

            implicitHeight: Cell.h(1)
            implicitWidth: Cell.w(root.w - (root.unit.length > 0 ? root.unit.length - 1 : 0))

            Repeater {

                model: root.h

                delegate: Loader {
                    id: loader

                    required property int index

                    active: root.visible || !root.optimizeMemory

                    sourceComponent: Item {

                        y: Cell.h(loader.index)
                        x: -Cell.w(loader.index * root.w)

                        Loader {

                            active: root.text.length == 0

                            sourceComponent: CellText {
                                id: placeholder

                                visible: root.text.length == 0

                                text: root.placeholder
                                color: root.disabled_color
                            }
                        }

                        Loader {

                            active: !root.hidden

                            sourceComponent: CellText {
                                id: input

                                visible: !root.hidden

                                text: root.text
                                font: root.font
                                color: root.disabled ? root.disabled_color : root.color
                            }
                        }

                        Loader {

                            active: root.visible || !root.optimizeMemory

                            sourceComponent: CellText {

                                text: " ".repeat(root.visualPos > 0 ? root.cursorPos : Math.max(root.cursorPos + root.visualPos, 0)) + "█".repeat(Math.abs(root.visualPos))
                                font: root.font
                                color: root.visual_color
                            }
                        }

                        Loader {

                            active: root.visible || !root.optimizeMemory

                            sourceComponent: CellText {
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
                        }

                        Loader {

                            active: !root.hidden

                            sourceComponent: CellText {
                                id: visual

                                visible: !root.hidden

                                text: " ".repeat(root.visualPos > 0 ? root.cursorPos : Math.max(root.cursorPos + root.visualPos, 0)) + root.text.slice(root.visualPos > 0 ? root.cursorPos : root.cursorPos + root.visualPos, root.visualPos > 0 ? root.cursorPos + root.visualPos : root.cursorPos)
                                font: root.fontB
                                color: root.disabled ? root.disabled_color : root.invert
                            }
                        }

                        Loader {

                            active: root.hidden

                            sourceComponent: RowLayout {

                                visible: root.hidden

                                spacing: 0

                                Repeater {

                                    model: root.text.length

                                    delegate: CellText {

                                        required property int index

                                        property bool invert: {
                                            if (root.visualPos > 0 && index >= root.cursorPos && index < root.cursorPos + root.visualPos) {
                                                return true;
                                            } else if (root.visualPos < 0 && index <= root.cursorPos && index > root.cursorPos + root.visualPos) {
                                                return true;
                                            }
                                            return false;
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
            }
        }
    }

    Cells {
        id: snap

        h: root.h
        w: root.w

        color: "transparent"
    }

    CellText {

        preferedW: root.w

        text: " ".repeat(root.w - root.unit.length) + root.unit
        font: root.font
        color: root.disabled ? root.disabled_color : root.color
    }

    MouseControl {

        visible: !root.disabled

        anchors.fill: parent

        onPressed: button => {
            if (button == "L") {
                root.forceActiveFocus();
            }
        }
    }

    function delete_char_back() {
        if (root.visual) {
            if (root.visualPos > 0) {
                const removed = root.text.slice(root.cursorPos, root.cursorPos + root.visualPos);
                root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos + root.visualPos, root.text.length);
                root.textRemoved(removed);
            }
            if (root.visualPos < 0) {
                const removed = root.text.slice(root.cursorPos + root.visualPos, root.cursorPos);
                root.text = root.text.slice(0, root.cursorPos + root.visualPos) + root.text.slice(root.cursorPos, root.text.length);
                root.cursorPos = root.cursorPos + root.visualPos;
                root.textRemoved(removed);
            }
            root.visualPos = 0;
            return;
        }
        if (root.cursorPos == 0) {
            root.textRemoved("");
            return;
        }
        const removed = root.text[root.cursorPos - 1];
        root.text = root.text.slice(0, root.cursorPos - 1) + root.text.slice(root.cursorPos);
        root.cursorPos -= 1;
        root.textRemoved(removed);
    }

    function delete_word_back() {
        if (root.text.length > 0) {
            if (root.visual) {
                if (root.visualPos > 0) {
                    const removed = root.text.slice(root.cursorPos, root.cursorPos + root.visualPos);
                    root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos + root.visualPos, root.text.length);
                    root.textRemoved(removed);
                }
                if (root.visualPos < 0) {
                    const removed = root.text.slice(root.cursorPos + root.visualPos, root.cursorPos);
                    root.text = root.text.slice(0, root.cursorPos + root.visualPos) + root.text.slice(root.cursorPos, root.text.length);
                    root.cursorPos = root.cursorPos + root.visualPos;
                    root.textRemoved(removed);
                }
                root.visualPos = 0;
                return;
            }

            const start = cursorPos;

            let inword = 0;

            while (cursorPos > 0) {
                cursorPos -= 1;
                if (root.text[cursorPos] != " ") {
                    continue;
                }
                if (root.text[cursorPos - 1] == " ") {
                    continue;
                }
                break;
            }

            const end = cursorPos;

            const removed = root.text.slice(end, start);
            root.text = root.text.slice(0, end) + root.text.slice(start, root.text.length);
            root.textRemoved(removed);
        } else
            root.textRemoved("");
    }

    function enter() {
        root.visualPos = 0;
        root.entered(root.text);
    }

    function delete_char_forward() {
        if (root.visual) {
            if (root.visualPos > 0) {
                const removed = root.text.slice(root.cursorPos, root.cursorPos + root.visualPos);
                root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos + root.visualPos, root.text.length);
                root.textRemoved(removed);
            }
            if (root.visualPos < 0) {
                const removed = root.text.slice(root.cursorPos + root.visualPos, root.cursorPos);
                root.text = root.text.slice(0, root.cursorPos + root.visualPos) + root.text.slice(root.cursorPos, root.text.length);
                root.cursorPos = root.cursorPos + root.visualPos;
                root.textRemoved(removed);
            }
            root.visualPos = 0;
            return;
        }
        const removed = root.text[root.cursorPos];
        if (root.cursorPos == root.text.length)
            return;
        root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos + 1);
        root.textRemoved(removed);
    }

    function select_char_back() {
        if (!root.editable)
            return;
        if (root.cursorPos == 0)
            return;
        root.cursorPos -= 1;
        root.visualPos += 1;
    }

    function select_char_forward() {
        if (!root.editable)
            return;
        if (root.cursorPos == root.text.length)
            return;
        root.cursorPos += 1;
        root.visualPos -= 1;
    }

    function select_char_forward_word() {
        if (!root.editable)
            return;
        if (root.cursorPos == root.text.length)
            return;
        if (root.text[Math.min(root.cursorPos + 1, text.length)] != " " && root.cursorPos < root.text.length) {
            root.cursorPos += 1;
            root.visualPos -= 1;
        }
        while (root.cursorPos < root.text.length && root.text[root.cursorPos] != " ") {
            root.cursorPos += 1;
            root.visualPos -= 1;
        }
    }

    function move_cursor_back() {
        if (!root.editable)
            return;
        root.visualPos = 0;
        root.cursorPos -= 1;
        if (root.cursorPos < 0) {
            root.cursorPos = 0;
        }
    }

    function move_cursor_back_word() {
        if (!root.editable)
            return;
        root.visualPos = 0;
        if (root.text[Math.max(root.cursorPos - 1, 0)] != " " && root.cursorPos > 0)
            root.cursorPos -= 1;
        while (root.cursorPos > 0 && root.text[root.cursorPos] != " ") {
            root.cursorPos -= 1;
        }
        if (root.cursorPos < 0) {
            root.cursorPos = 0;
        }
    }

    function move_cursor_forward() {
        if (!root.editable)
            return;
        root.visualPos = 0;
        root.cursorPos += 1;
        if (root.cursorPos > root.text.length) {
            root.cursorPos = root.text.length;
        }
    }

    function move_cursor_forward_word() {
        if (!root.editable)
            return;
        root.visualPos = 0;
        if (root.text[Math.min(root.cursorPos + 1, text.length)] != " " && root.cursorPos < root.text.length)
            root.cursorPos += 1;
        while (root.cursorPos < root.text.length && root.text[root.cursorPos] != " ") {
            root.cursorPos += 1;
        }
        if (root.cursorPos < 0) {
            root.cursorPos = 0;
        }
    }

    function select_all() {
        root.visualPos = -root.text.length;
        root.cursorPos = root.text.length;
    }

    function type(char: string) {
        if (root.visual) {
            if (root.visualPos > 0) {
                root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos + root.visualPos, root.text.length);
            }
            if (root.visualPos < 0) {
                root.text = root.text.slice(0, root.cursorPos + root.visualPos) + root.text.slice(root.cursorPos, root.text.length);
                root.cursorPos = root.cursorPos + root.visualPos;
            }
            root.visualPos = 0;
        }
        root.text = root.text.slice(0, root.cursorPos) + char + root.text.slice(root.cursorPos);
        root.cursorPos += 1;
        root.textAdded(char);
    }

    function copy_selected() {
        if (root.visualPos == 0)
            return;
        if (!root.canCopy)
            return;
        let copy = "";
        if (root.visual) {
            if (root.visualPos > 0) {
                copy = root.text.slice(root.cursorPos, root.cursorPos + root.visualPos);
            }
            if (root.visualPos < 0) {
                copy = root.text.slice(root.cursorPos + root.visualPos, root.cursorPos);
            }
        }
        SystemInfo.copy_clipboard(copy);
        root.textCopied(copy);
    }

    function cut_selected() {
        if (root.visualPos == 0)
            return;
        if (!root.canCopy)
            return;
        let copy = "";
        if (root.visual) {
            if (root.visualPos > 0) {
                copy = root.text.slice(root.cursorPos, root.cursorPos + root.visualPos);
                root.text = root.text.slice(0, root.cursorPos) + root.text.slice(root.cursorPos + root.visualPos, root.text.length);
            }
            if (root.visualPos < 0) {
                copy = root.text.slice(root.cursorPos + root.visualPos, root.cursorPos);
                root.text = root.text.slice(0, root.cursorPos + root.visualPos) + root.text.slice(root.cursorPos, root.text.length);
                root.cursorPos = root.cursorPos + root.visualPos;
            }
            root.visualPos = 0;
        }
        SystemInfo.copy_clipboard(copy);
        root.textCopied(copy);
    }

    Keys.onPressed: event => {
        if (root.disabled)
            return;
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key == Qt.Key_C) {
                root.copy_selected();
            } else if (event.key == Qt.Key_X) {
                root.cut_selected();
            } else if (event.key == Qt.Key_V) {
                ClipboardInfo.paste();
            } else if (event.key == Qt.Key_Left) {
                root.move_cursor_back_word();
            } else if (event.key == Qt.Key_Right) {
                root.move_cursor_forward_word();
            } else if (event.key == Qt.Key_A) {
                root.select_all();
            } else if (event.key == Qt.Key_Backspace) {
                root.delete_word_back();
            } else {
                return;
            }
            event.accepted = true;
        } else if (event.modifiers & Qt.ShiftModifier) {
            if (event.key == Qt.Key_Left) {
                root.select_char_back();
            } else if (event.key == Qt.Key_Right) {
                root.select_char_forward();
            } else {
                return;
            }
            event.accepted = true;
        }

        if (event.key == Qt.Key_Return) {
            root.enter();
        } else if (event.key == Qt.Key_Escape) {
            if (root.escapeToUnFocus)
                root.unFocus();
        } else if (event.key == Qt.Key_Backspace) {
            root.delete_char_back();
        } else if (event.key == Qt.Key_Delete) {
            root.delete_char_forward();
        } else if (event.text.length > 0 && event.text >= " ") {
            root.type(event.text);
        } else if (event.key == Qt.Key_Left) {
            root.move_cursor_back();
        } else if (event.key == Qt.Key_Right) {
            root.move_cursor_forward();
        } else {
            return;
        }
        event.accepted = true;
    }
}
