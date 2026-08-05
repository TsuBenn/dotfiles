pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {
    id: root

    w: 48
    h: 20

    shortcuts: QuickMenuInfo.shortcuts

    property bool custom: false
    property bool help: false

    escapeToClose: !TextFieldManager.active

    onShortcutCalled: {
        close();
    }

    onVisibleChanged: {
        custom = false;
        help = false;
    }

    Cells {

        w: root.w
        h: root.h

        CellBox {
            id: box

            w: root.w
            h: root.h

            ColumnLayout {

                visible: !root.custom && !root.help

                spacing: 0

                RowLayout {

                    Layout.leftMargin: Cell.w(1)

                    spacing: Cell.w(1)

                    CellText {

                        text: " Action"
                        preferedW: list.w - 13 - 7
                        font: Cell.fontB
                    }

                    CellText {

                        text: "Keybind"
                        preferedW: 12
                        font: Cell.fontB
                    }
                }

                CellSeparator {

                    w: list.w
                    color: Colors.accentStrong
                    bg: "transparent"
                    connectStart: true
                    connectEnd: true
                }

                CellScrollList {
                    id: list

                    w: box.contentW
                    h: box.contentH - 4

                    itemH: 2

                    reloadOnChanges: true

                    model: [...QuickMenuInfo.binds]

                    delegate: ColumnLayout {
                        id: keybind

                        property var modelData

                        property int index
                        property var binds: modelData.binds
                        property string action: modelData.action

                        spacing: 0

                        Cells {

                            w: list.contentW
                            h: 1

                            color: "transparent"

                            RowLayout {

                                x: Cell.w(1)

                                spacing: Cell.w(1)

                                CellDropdown {
                                    id: action_list
                                    text: ""
                                    w: list.w - 13 - 8
                                    h: 5
                                    selected: QuickMenuInfo.action_index[keybind.action] ?? 0
                                    items: {
                                        let result = [];
                                        for (const actions of Object.keys(QuickMenuInfo.actions)) {
                                            result.push({
                                                "label": QuickMenuInfo.actions[actions].label,
                                                "data": actions
                                            });
                                        }
                                        // console.log(JSON.stringify(result, null, 2));
                                        return result;
                                    }
                                    onActivated: (index, label) => {
                                        QuickMenuInfo.setAction(keybind.index, items[index].data);
                                    }
                                }

                                Cells {

                                    w: 13
                                    h: 1

                                    color: Colors.bgOverlay

                                    CellTextField {

                                        x: Cell.w(1)

                                        w: parent.w - 2
                                        h: parent.h

                                        focusOnVisible: false
                                        unfocusOnEntered: true
                                        escapeToUnFocus: true
                                        autoApply: true

                                        autoClear: true

                                        bindText: keybind.binds.join(", ")

                                        placeholder: "Binds"

                                        onEntered: input => {
                                            if (input.trim() == "")
                                                return;
                                            let new_binds = input.split(",");
                                            for (const i in new_binds) {
                                                new_binds[i] = new_binds[i].trim();
                                            }
                                            QuickMenuInfo.setBinds(keybind.index, new_binds);
                                        }

                                        color: keybind.binds.join(", ").match(/\w!/) ? Colors.danger : Colors.success
                                        font: Cell.fontB
                                    }
                                }

                                CellButton {
                                    text: "-"
                                    fg: [Colors.fgBase, Colors.bgSurface]
                                    color: [Colors.bgOverlay, Colors.fgBase]
                                    onReleased: button => {
                                        QuickMenuInfo.removeBinds(keybind.index);
                                    }
                                }
                            }
                        }

                        CellSeparator {
                            w: list.contentW
                            color: Colors.bgOverlay
                        }
                    }

                    CellText {
                        visible: QuickMenuInfo.binds.length == 0
                        text: "\nNo Bindings Specified"
                        color: Colors.fgSubtle
                        centered: true
                        preferedW: list.contentW
                    }
                }

                CellSeparator {

                    w: list.w
                    color: Colors.accentStrong
                    bg: "transparent"
                    connectStart: true
                    connectEnd: true
                }

                RowLayout {

                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Cell.w(1)

                    spacing: Cell.w(1)

                    CellButton {
                        text: "?"
                        color: [Colors.bgOverlay, Colors.fgBase]
                        fg: [Colors.fgBase, Colors.bgSurface]

                        onReleased: button => {
                            if (button == "L") {
                                root.custom = false;
                                root.help = true;
                            }
                        }
                    }

                    CellButton {
                        text: "Manage custom actions"
                        color: [Colors.bgOverlay, Colors.fgBase]
                        fg: [Colors.fgBase, Colors.bgSurface]

                        onReleased: button => {
                            if (button == "L") {
                                root.custom = true;
                                root.help = false;
                            }
                        }
                    }

                    CellButton {

                        text: "Add"
                        color: [Colors.accentStrong, Colors.bgOverlay]
                        fg: [Colors.onAccent, Colors.fgBase]

                        onReleased: button => {
                            if (button == "L") {
                                QuickMenuInfo.addBinds();
                            }
                        }
                    }
                }
            }

            ColumnLayout {

                visible: root.custom

                spacing: 0

                CellText {
                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                    text: "Custom actions"
                    color: Colors.secondary
                    font: Cell.fontB
                }

                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                    bg: "transparent"
                    connectStart: true
                    connectEnd: true
                }

                CellScrollList {
                    id: custom_list

                    w: box.contentW
                    h: box.contentH - 4

                    itemH: 4

                    reloadOnChanges: true

                    model: Object.keys(QuickMenuInfo.custom_actions)

                    delegate: ColumnLayout {
                        id: custom

                        property var modelData

                        property var custom_actions: QuickMenuInfo.custom_actions[modelData]

                        property string label: custom_actions.label
                        property string cmd: custom_actions.cmd

                        spacing: 0

                        RowLayout {

                            Layout.leftMargin: Cell.w(1)

                            spacing: Cell.w(1)

                            Cells {

                                w: custom_list.contentW - 6
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {
                                    id: custom_label

                                    x: Cell.w(1)

                                    w: parent.w - 2
                                    h: parent.h

                                    escapeToUnFocus: true
                                    unfocusOnEntered: true
                                    focusOnVisible: false
                                    autoApply: true

                                    placeholder: "Custom action label"

                                    bindText: custom.label

                                    onEntered: input => {
                                        QuickMenuInfo.editCustom(custom.modelData, input, custom.cmd);
                                    }
                                }
                            }

                            CellButton {
                                text: "-"

                                fg: [Colors.onAccent, Colors.bgOverlay]
                                color: [Colors.accentStrong, Colors.fgBase]

                                onReleased: button => {
                                    if (button == "L") {
                                        QuickMenuInfo.removeCustom(custom.modelData);
                                    }
                                }
                            }
                        }

                        CellSeparator {
                            w: custom_list.contentW
                            padding: 1
                            color: Colors.bgOverlay
                            title {
                                text: "Shell command"
                                color: Colors.fgSubtle
                            }
                        }

                        Cells {
                            id: custom_cmd

                            Layout.leftMargin: Cell.w(1)

                            w: custom_list.contentW - 2
                            h: 1
                            color: Colors.bgOverlay

                            RowLayout {

                                spacing: 0

                                CellText {
                                    text: " > "
                                }

                                CellTextField {

                                    w: custom_cmd.w - 4
                                    h: custom_cmd.h

                                    escapeToUnFocus: true
                                    unfocusOnEntered: true
                                    focusOnVisible: false
                                    autoApply: true

                                    placeholder: "Shell command to execute..."

                                    bindText: custom.cmd

                                    onEntered: input => {
                                        QuickMenuInfo.editCustom(custom.modelData, custom.label, input);
                                    }
                                }
                            }
                        }

                        CellSeparator {
                            w: custom_list.contentW
                            color: Qt.lighter(Colors.bgOverlay, 1.5)
                        }
                    }

                    CellText {
                        visible: Object.keys(QuickMenuInfo.custom_actions).length == 0
                        text: "\nNo Custom Actions"
                        color: Colors.fgSubtle
                        centered: true
                        preferedW: custom_list.contentW
                    }
                }

                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                    bg: "transparent"
                    connectStart: true
                    connectEnd: true
                }

                RowLayout {

                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Cell.w(1)

                    spacing: Cell.w(1)

                    CellButton {
                        text: "Return"
                        fg: [Colors.fgBase, Colors.bgSurface]
                        color: [Colors.bgOverlay, Colors.fgBase]
                        onReleased: button => {
                            if (button == "L") {
                                root.custom = false;
                                root.help = false;
                            }
                        }
                    }

                    CellButton {
                        fg: [Colors.onAccent, Colors.fgBase]
                        color: [Colors.accentStrong, Colors.bgOverlay]
                        text: "Add"
                        onReleased: button => {
                            if (button == "L") {
                                QuickMenuInfo.addCustom();
                            }
                        }
                    }
                }
            }

            ColumnLayout {

                visible: root.help

                spacing: 0

                CellText {
                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                    text: "HOW TO USE"
                    color: Colors.secondary
                    font: Cell.fontB
                }

                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                    bg: "transparent"
                    connectStart: true
                    connectEnd: true
                }

                CellScrollView {
                    id: readme

                    w: box.contentW
                    h: box.contentH - 4

                    source: CellTextFormat {
                        w: readme.contentW
                        text: ReadmeInfo.getValue("quickmenu_usage")
                    }
                }

                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                    bg: "transparent"
                    connectStart: true
                    connectEnd: true
                }

                RowLayout {

                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Cell.w(1)

                    spacing: Cell.w(1)

                    CellButton {
                        text: "Return"
                        fg: [Colors.fgBase, Colors.bgSurface]
                        color: [Colors.bgOverlay, Colors.fgBase]
                        onReleased: button => {
                            if (button == "L") {
                                root.custom = false;
                                root.help = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
