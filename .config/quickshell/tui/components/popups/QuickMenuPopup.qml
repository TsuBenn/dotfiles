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

    shortcuts: TextFieldManager.active ? [] : QuickMenuInfo.shortcuts

    property bool custom: false

    escapeToClose: !TextFieldManager.active 

    onShortcutsChanged: {
        refreshShortcuts()
    }

    Cells {

        w: root.w
        h: root.h

        CellBox {

            id: box

            w: root.w
            h: root.h

            ColumnLayout {

                visible: !root.custom

                spacing: 0

                RowLayout {

                    Layout.leftMargin: Cell.w(1)

                    spacing: Cell.w(1)

                    CellText {

                        text: " Action"
                        preferedW: list.w - 12 - 3
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

                }

                CellScrollView {

                    id: list

                    w: box.contentW
                    h: box.contentH - 4

                    source: ColumnLayout {

                        spacing: 0

                        Repeater {

                            model: QuickMenuInfo.binds

                            delegate: ColumnLayout {

                                id: keybind

                                required property int index
                                required property var binds
                                required property string action

                                spacing: 0

                                Cells {

                                    w: list.contentW
                                    h: 1

                                    color: "transparent"

                                    RowLayout {

                                        x: Cell.w(1)

                                        spacing: Cell.w(1)

                                        CellDropdown {
                                            text: ""
                                            w: list.w - 12 - 4
                                            h: 5
                                            selected: QuickMenuInfo.action_index[keybind.action]
                                            items: {
                                                let result = []
                                                for (const actions of Object.keys(QuickMenuInfo.actions)) {
                                                    result.push({
                                                        "label": QuickMenuInfo.actions[actions].label,
                                                        "action": () => QuickMenuInfo.setAction(keybind.index, actions),
                                                    })
                                                }
                                                return result
                                            }
                                        }

                                        Cells {

                                            w: 12
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

                                                bindText: keybind.binds.join(", ")

                                                placeholder: "Binds"

                                                onEntered: (input) => {
                                                    let new_binds = input.split(",")
                                                    for (const i in new_binds) {
                                                        new_binds[i] = new_binds[i].trim()
                                                    }
                                                    QuickMenuInfo.setBinds(keybind.index, new_binds)
                                                }

                                                color: QuickMenuInfo.faultyIndex.includes(4) ? Colors.danger : Colors.success 
                                                font: Cell.fontB

                                            }

                                        }

                                    }

                                    MouseControl {

                                        anchors.fill: parent
                                        anchors.topMargin: -Cell.h(0.4)
                                        anchors.bottomMargin: -Cell.h(0.4)

                                        acceptedButtons: Qt.RightButton

                                        onPressed: (button) => {
                                            if (button == "R") {
                                                const global = mapToGlobal(mouseX, mouseY)
                                                ContextMenuManager.show([
                                                    {label: "Remove", action: () => QuickMenuInfo.removeBinds(keybind.index)}
                                                ],global.x, global.y,undefined,"")
                                            }
                                        }
                                    }

                                }

                                CellSeparator {

                                    w: list.contentW
                                    color: Colors.bgOverlay

                                }

                            }

                        }

                    }

                }

                CellSeparator {

                    w: list.w
                    color: Colors.accentStrong

                }

                RowLayout {

                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Cell.w(1)

                    spacing: Cell.w(1)
                    
                    CellButton {
                        text: "Manage custom actions"
                        color: [Colors.bgOverlay, Colors.fgBase]
                        fg: [Colors.fgBase, Colors.bgSurface]

                        onReleased: (button) => {
                            if (button == "L") {
                                root.custom = true
                            }
                        }

                    }

                    CellButton {

                        text: "Add"
                        color: [Colors.accentStrong, Colors.bgOverlay]
                        fg: [Colors.onAccent, Colors.fgBase]

                        onReleased: (button) => {
                            if (button == "L") {
                                QuickMenuInfo.addBinds()
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
                }

            }

        }

    }

}
