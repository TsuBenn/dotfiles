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

    Cells {

        w: root.w
        h: root.h

        CellBox {

            id: box

            w: root.w
            h: root.h

            ColumnLayout {

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

                                RowLayout {

                                    Layout.leftMargin: Cell.w(1)

                                    spacing: Cell.w(1)

                                    CellDropdown {
                                        text: ""
                                        w: list.w - 12 - 4
                                        h: 10
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

                                            bindText: keybind.binds.join(", ")

                                            placeholder: "Binds"

                                            color: Colors.success
                                            font: Cell.fontB

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

                    spacing: 0

                }
            }

        }

    }

}
