pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    implicitWidth: monitor.width
    implicitHeight: monitor.height

    x: 0
    y: 0

    property bool lock: false

    id: root

    onVisibleChanged: {
        if (visible) {
            openAnim.restart()
        }
    }

    function close() {
        if (closeAnim.running) return
        closeAnim.restart()
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { 
            target: root
            property: "opacity"
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: PopupManager.close(root.name)
        }
    }
    SequentialAnimation {
        id: openAnim
        NumberAnimation { 
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

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
                active: !root.lock,
                action: () => {SystemInfo.lock()},
            },
            {
                binds: root.lock ? "4" : "5",
                action: () => {PowerManager.call("Logout", 3)},
            },
            {
                binds: "0",
                action: () => {root.close()},
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
            () => SystemInfo.lock(),
            () => PowerManager.call("Logout", 3),
            () => root.close(),
        ]

        w: Cell.wCount(root.implicitWidth) + 1
        h: Cell.hCount(root.implicitHeight) + 1

        color: Colors.transparent(Qt.darker(Colors.bgBase,2),0.8)

        MouseControl {

            anchors.fill: parent

            onReleased: (button) => {
                if (button == "L") {
                    root.close()
                }
            }

        }

        Loader {

            active: root.visible || !root.optimizeMemory

            sourceComponent: Cells {

                w: Cell.wCount(layout.implicitWidth)
                h: Cell.hCount(layout.implicitHeight)

                color: "transparent"

                Component.onCompleted: {
                    x = Cell.centerWCell(implicitWidth, menu.implicitWidth) - Cell.w(3)
                    y = Cell.centerHCell(implicitHeight, menu.implicitHeight)
                }

                ColumnLayout {

                    id: layout


                    spacing: Cell.h(1)

                    component Option: CellText {

                        id: option

                        property int index: 0
                        property string title: "1.suspend"
                        property var action: undefined

                        readonly property int selected: menu.selected == index

                        pure: false
                        lockPure: true
                        text: ANSI.render(title,selected ? 2 : 1)
                        clip: true

                        MouseControl {

                            anchors.fill: parent

                            onEntered: {
                                menu.selected = parent.index
                            }

                            onReleased: (button) => {
                                if (button == "L") {
                                    if (option.action) {
                                        option.action()
                                    } else {
                                        menu.actions[option.index]()
                                    }
                                }
                            }
                        }

                        color: selected ? menu.select_color : menu.base_color

                    }

                    Option {
                        index: 0
                        title: "1.suspend"
                    }

                    Option {
                        index: 1
                        title: "2.reboot"
                    }

                    Option {
                        index: 2
                        title: "3.Shutdown"
                    }

                    Option {
                        visible: !root.lock
                        index: 3
                        title: "4.lock"
                    }

                    Option {
                        index: 4
                        title: root.lock ? "4.logout" : "5.logout"
                    }

                    Option {
                        index: 5
                        title: "0.cancel"
                    }

                }

            }
        }


    }

}
