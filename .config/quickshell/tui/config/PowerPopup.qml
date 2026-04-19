import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    id: root

    w: 18
    h: Cell.hCount(layout.implicitHeight)

    CellBox {

        w: root.w + 2
        h: root.h + 2

        ColumnLayout {

            id: layout

            spacing: 0

            ShortcutHandler {
                shortcuts: [
                    {
                        binds: "1",
                        action: () => {PowerManager.call("Sleep", 3)},
                    },
                    {
                        binds: "2",
                        action: () => {PowerManager.call("Reboot", 3)},
                    },
                    {
                        binds: "3",
                        action: () => {PowerManager.call("Shutdown", 3)},
                    },
                    {
                        binds: "4",
                        action: () => {PowerManager.call("Logout", 3)},
                    },
                    {
                        binds: "0",
                        action: () => {PopupManager.close()},
                    },
                ]
            }

            RowLayout {

                spacing: 0

                CellText {
                    text: " "
                }

                CellKeyHint {
                    visible: SettingsInfo.hints
                    key: "1"
                    hint: ""
                }

                CellButton {

                    padding: 1

                    text: "Sleep"

                    centered: false

                    w: root.w - 2 - 4*SettingsInfo.hints

                    color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                    fg: [Colors.fgBase, Colors.bgSurface]

                    onReleased: (button) => {
                        if (button == "L") {
                            PowerManager.call("Sleep", 3)
                        }
                    }

                }

            }

            RowLayout {

                spacing: Cell.w(0)

                CellText {
                    text: " "
                }

                CellKeyHint {
                    visible: SettingsInfo.hints
                    key: "2"
                    hint: ""
                }

                CellButton {

                    padding: 1

                    text: "Reboot"

                    centered: false

                    w: root.w - 2 - 4*SettingsInfo.hints

                    color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                    fg: [Colors.fgBase, Colors.bgSurface]

                    onReleased: (button) => {
                        if (button == "L") {
                            PowerManager.call("Reboot", 3)
                        }
                    }

                }

            }


            RowLayout {

                spacing: Cell.w(0)

                CellText {
                    text: " "
                }

                CellKeyHint {
                    visible: SettingsInfo.hints
                    key: "3"
                    hint: ""
                }

                CellButton {

                    padding: 1

                    text: "Shutdown"

                    centered: false

                    w: root.w - 2 - 4*SettingsInfo.hints

                    color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                    fg: [Colors.fgBase, Colors.bgSurface]

                    onReleased: (button) => {
                        if (button == "L") {
                            PowerManager.call("Shutdown", 3)
                        }
                    }

                }
            }


            RowLayout {

                spacing: Cell.w(0)

                CellText {
                    text: " "
                }

                CellKeyHint {
                    visible: SettingsInfo.hints
                    key: "4"
                    hint: ""
                }

                CellButton {

                    padding: 1

                    text: "Logout"

                    centered: false

                    w: root.w - 2 - 4*SettingsInfo.hints

                    color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                    fg: [Colors.fgBase, Colors.bgSurface]

                    onReleased: (button) => {
                        if (button == "L") {
                            PowerManager.call("Logout", 3)
                        }
                    }

                }
            }


            CellText {
                text: ""
            }

            RowLayout {

                spacing: Cell.w(0)

                CellText {
                    text: " "
                }

                CellKeyHint {
                    visible: SettingsInfo.hints
                    key: "0"
                    hint: ""
                }

                CellButton {

                    padding: 1

                    text: "Cancel"

                    centered: false

                    w: root.w - 2 - 4*SettingsInfo.hints

                    color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                    fg: [Colors.fgBase, Colors.bgSurface]

                    onReleased: (button) => {
                        if (button == "L") {
                            PopupManager.close()
                        }
                    }

                }
            }


        }


    }

}
