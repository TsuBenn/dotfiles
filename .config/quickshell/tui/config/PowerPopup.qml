pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    implicitWidth: monitor.width
    implicitHeight: monitor.height

    x: 0
    y: 0

    id: root

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
                binds: "5",
                action: () => {PowerManager.call("Logout", 3)},
            },
            {
                binds: "0",
                action: () => {PopupManager.close()},
            },
            {
                binds: "Up",
                action: () => {menu.selected = (menu.selected - 1 + 6)%6},
            },
            {
                binds: "Down",
                action: () => {menu.selected = (menu.selected + 1 + 6)%6},
            },
            {
                binds: "Return",
                action: () => {menu.actions[menu.selected]()},
            },
        ]
    }

    Cells {

        id: menu

        onVisibleChanged: {
            selected = 0
        }

        property int selected: 0
        property color select_color: Colors.blend(Colors.accentStrong,Colors.secondary, 0.5)
        property color base_color: Colors.fgBase

        property var actions: [
            () => PowerManager.call("Sleep", 3),
            () => PowerManager.call("Reboot", 3),
            () => PowerManager.call("Shutdown", 3),
                                () => NotificationsInfo.send("System","","Power","This function is not available <i>yet</i>", 0, false, "echo Hello"),
            () => PowerManager.call("Logout", 3),
            () => PopupManager.close(),
        ]

        w: Cell.wCount(root.implicitWidth) + 1
        h: Cell.hCount(root.implicitHeight) + 1

        color: Colors.transparent(Qt.darker(Colors.bgBase,2),0.8)

        Loader {

            active: root.visible || !SettingsInfo.optimizeMemory

            sourceComponent: ColumnLayout {

                Component.onCompleted: {

                    x = Cell.centerWCell(implicitWidth, menu.implicitWidth)
                    y = Cell.centerHCell(implicitHeight, menu.implicitHeight) - Cell.h(2)

                }


                spacing: Cell.h(1)

                CellText {

                    property int index: 0
                    property int selected: menu.selected == index

                    text: ANSI.render("1.suspend",selected ? 2 : 1)
                    clip: true

                    MouseControl {
                        anchors.fill: parent

                        onEntered: {
                            menu.selected = parent.index
                        }

                        onReleased: (button) => {
                            if (button == "L") {
                                menu.actions[parent.index]()
                            }
                        }
                    }

                    color: selected ? menu.select_color : menu.base_color

                }

                CellText {

                    property int index: 1
                    property int selected: menu.selected == index

                    text: ANSI.render("2.reboot",selected ? 2 : 1)
                    clip: true

                    MouseControl {
                        anchors.fill: parent

                        onEntered: {
                            menu.selected = parent.index
                        }

                        onReleased: (button) => {
                            if (button == "L") {
                                menu.actions[parent.index]()
                            }
                        }
                    }

                    color: selected ? menu.select_color : menu.base_color

                }

                CellText {

                    property int index: 2
                    property int selected: menu.selected == index

                    text: ANSI.render("3.shutdown",selected ? 2 : 1)
                    clip: true

                    MouseControl {
                        anchors.fill: parent

                        onEntered: {
                            menu.selected = parent.index
                        }

                        onReleased: (button) => {
                            if (button == "L") {
                                menu.actions[parent.index]()
                            }
                        }
                    }

                    color: selected ? menu.select_color : menu.base_color

                }

                CellText {

                    property int index: 3
                    property int selected: menu.selected == index

                    text: ANSI.render("4.lock",selected ? 2 : 1)
                    clip: true

                    MouseControl {
                        anchors.fill: parent

                        onEntered: {
                            menu.selected = parent.index
                        }

                        onReleased: (button) => {
                            if (button == "L") {
                                menu.actions[parent.index]()
                            }
                        }
                    }

                    color: selected ? menu.select_color : menu.base_color

                }

                CellText {

                    property int index: 4
                    property int selected: menu.selected == index

                    text: ANSI.render("5.logout",selected ? 2 : 1)
                    clip: true

                    MouseControl {
                        anchors.fill: parent

                        onEntered: {
                            menu.selected = parent.index
                        }

                        onReleased: (button) => {
                            if (button == "L") {
                                menu.actions[parent.index]()
                            }
                        }
                    }

                    color: selected ? menu.select_color : menu.base_color

                }

                CellText {

                    property int index: 5
                    property int selected: menu.selected == index

                    text: ANSI.render("0.cancel",selected ? 2 : 1)
                    clip: true

                    MouseControl {
                        anchors.fill: parent

                        onEntered: {
                            menu.selected = parent.index
                        }

                        onReleased: (button) => {
                            if (button == "L") {
                                menu.actions[parent.index]()
                            }
                        }
                    }

                    color: selected ? menu.select_color : menu.base_color

                }

            }
        }


    }

}
