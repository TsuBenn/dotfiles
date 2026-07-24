pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {
    id: root

    w: 48
    h: 3

    onVisibleChanged: {
        textfield.clear();
        SpellCheckerInfo.results = [];
        if (visible)
            SpellCheckerInfo.active = true;
        else
            SpellCheckerInfo.active = false;
    }

    property var results: SpellCheckerInfo.results

    shortcuts: [
        {
            binds: ["Left", "Backtab"],
            action: () => {
                list.advance(-1);
            }
        },
        {
            binds: ["Right", "Tab"],
            action: () => {
                list.advance(1);
            }
        },
        {
            binds: "Return",
            action: () => {
                if (list.selected == -1)
                    return;
                SystemInfo.copy_clipboard(list.model[list.selected].word);
                close();
            }
        },
    ]

    Cells {

        w: root.w
        h: root.h

        CellBox {
            id: box

            w: root.w
            h: Cell.hCount(layout.implicitHeight) + 2

            header.text: " Spellchecker "

            ColumnLayout {
                id: layout

                spacing: 0

                Timer {
                    id: debounce
                    property string query: ""
                    interval: 500
                    onTriggered: {
                        SpellCheckerInfo.check(query);
                    }
                }

                CellTextField {
                    id: textfield
                    Layout.leftMargin: Cell.w(1)

                    w: box.contentW - 2
                    h: 1

                    forceFocus: true
                    canEnter: false
                    escapeToUnFocus: false
                    vertMove: false

                    onTextInput: input => {
                        if (input == "") {
                            SpellCheckerInfo.results = [];
                            return;
                        }
                        debounce.query = input.trim().split(" ").pop();
                        debounce.restart();
                        SpellCheckerInfo.correct = false;
                    }

                    color: SpellCheckerInfo.correct ? Colors.success : (list.model.length > 0 ? Colors.danger : Colors.fgBase)
                }

                CellSeparator {
                    visible: list.h > 0
                    w: box.contentW
                    color: Colors.accentStrong
                    bg: "transparent"
                    connectStart: true
                    connectEnd: true
                }

                CellScrollList {
                    id: list
                    w: box.contentW
                    h: Math.min(model.length * itemH, 8)
                    model: SpellCheckerInfo.results

                    property int selected: -1

                    onSelectedChanged: {
                        if (selected > -1) {
                            scrollToView(selected);
                        }
                    }

                    onModelChanged: selected = -1

                    function advance(delta) {
                        if (selected == 0 && delta == -1) {
                            selected = -1;
                            return;
                        }
                        selected = (selected + delta + model.length) % (model.length);
                    }

                    Behavior on h {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    itemH: 2

                    property int maxpadding: {
                        if (model.length == 0)
                            return 0;
                        let max = 0;
                        for (const res of model) {
                            if (res.word.length > max) {
                                max = res.word.length;
                            }
                        }
                        return max;
                    }

                    delegate: Cells {
                        id: sug

                        property int index
                        property var modelData
                        w: list.contentW
                        h: 2

                        property bool selected: list.selected == index

                        color: Colors.bgSurface

                        ColumnLayout {

                            spacing: 0

                            RowLayout {

                                spacing: 0

                                CellText {
                                    text: " " + (sug.selected ? "> " : "") + sug.modelData.word + " ".repeat(Math.max(list.maxpadding - sug.modelData.word.length + 1 + !sug.selected * 2, 0))
                                    color: Colors.success
                                    font: Cell.fontBB
                                }

                                CellText {
                                    text: "| "
                                    color: Colors.fgSubtle
                                }

                                Repeater {
                                    model: sug.modelData.changes
                                    delegate: RowLayout {

                                        required property string type
                                        required property var modelData
                                        property string char: modelData.char ?? ""
                                        property string from: modelData.from ?? ""
                                        property string to: modelData.to ?? ""

                                        spacing: 0

                                        CellText {
                                            // opacity: parent.type == "delete" || parent.type == "replace" ? 0.5 : 1
                                            text: {
                                                switch (parent.type) {
                                                case "match":
                                                    return parent.char;
                                                case "insert":
                                                    return "<b>" + parent.char + "</b>";
                                                case "delete":
                                                    return "<i>" + parent.char + "</i>";
                                                case "replace":
                                                    return /* "<u><i>" + parent.from + "</i></u>"; */ "";
                                                case "transpose":
                                                    return "<b>" + parent.from + "</b>";
                                                }
                                                return parent.char;
                                            }
                                            color: {
                                                switch (parent.type) {
                                                case "match":
                                                    return Colors.fgBase;
                                                case "insert":
                                                    return Colors.success;
                                                case "delete":
                                                    return Colors.fgSubtle;
                                                case "replace":
                                                    return Colors.fgSubtle;
                                                case "transpose":
                                                    return Colors.warning;
                                                }
                                                return Colors.fgBase;
                                            }
                                            font: parent.type != "match" ? Cell.fontB : Cell.font
                                        }
                                        CellText {
                                            text: parent.to
                                            color: parent.type == "transpose" ? Colors.warning : Colors.info
                                            font: Cell.fontB
                                        }
                                    }
                                }
                            }

                            CellSeparator {
                                w: list.contentW
                                color: Colors.bgOverlay
                                bg: "transparent"
                            }
                        }
                    }
                }

                CellSeparator {
                    visible: SettingsInfo.hints
                    w: box.contentW
                    color: Colors.accentStrong
                    bg: "transparent"
                    connectStart: true
                    connectEnd: true
                }

                RowLayout {

                    visible: SettingsInfo.hints

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    spacing: Cell.w(2)

                    CellText {
                        text: "Matched"
                        color: Colors.fgBase
                    }

                    CellText {
                        text: "<b>Add</b>"
                        color: Colors.success
                    }

                    CellText {
                        text: "<i>Remove</i>"
                        color: Colors.fgSubtle
                    }

                    CellText {
                        text: "<b>Replace</b>"
                        color: Colors.info
                    }

                    CellText {
                        text: "<b>Swap</b>"
                        color: Colors.warning
                    }
                }
            }
        }
    }
}
