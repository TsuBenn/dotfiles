pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {
    id: root

    implicitWidth: monitor.width
    implicitHeight: monitor.height

    layer.enabled: true

    x: 0
    y: 0

    property bool lock: false

    onVisibleChanged: {
        if (visible) {
            openAnim.restart();
            blackout.opacity = 0;
            countdown.opacity = 1;
            top_bar.implicitHeight = 0;
            bottom_bar.implicitHeight = 0;
        } else {
            list.show = true;
            countdown.active = false;
        }
    }

    function onSigClose() {
        if (closeAnim.running)
            return;
        countdown.active = false;
        blacking_out.stop();
        timer.stop();
        closeAnim.restart();
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: 200 * (1 + blackout.opacity)
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: {
                blackout.opacity = 0;
                countdown.opacity = 1;
                countdown.active = false;
                top_bar.implicitHeight = 0;
                bottom_bar.implicitHeight = 0;
                root.forceClose();
            }
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

    ParallelAnimation {
        id: blacking_out
        NumberAnimation {
            target: blackout
            property: "opacity"
            to: 1
            duration: 2000
            easing.type: Easing.InQuart
        }
        NumberAnimation {
            target: top_bar
            property: "implicitHeight"
            to: root.monitor.height / 2 + Cell.h(1)
            duration: 2000
            easing.type: Easing.InQuart
        }
        NumberAnimation {
            target: bottom_bar
            property: "implicitHeight"
            to: root.monitor.height / 2 + Cell.h(1)
            duration: 2000
            easing.type: Easing.InQuart
        }
        SequentialAnimation {
            PauseAnimation {
                duration: 2000
            }
            NumberAnimation {
                target: countdown
                property: "opacity"
                to: 0
                duration: 1000
                easing.type: Easing.InCubic
            }
        }
    }

    shortcuts: [
        {
            binds: "1",
            action: () => {
                PowerManager.call("Sleep", 3);
            }
        },
        {
            binds: "2",
            action: () => {
                PowerManager.call("Reboot", 3);
            }
        },
        {
            binds: "3",
            action: () => {
                PowerManager.call("Shutdown", 3);
            }
        },
        {
            binds: "4",
            active: !root.lock,
            action: () => {
                SystemInfo.lock();
            }
        },
        {
            binds: root.lock ? "4" : "5",
            action: () => {
                PowerManager.call("Logout", 3);
            }
        },
        {
            binds: "0",
            action: () => {
                root.close();
            }
        },
        {
            binds: "Up",
            action: () => {
                menu.selected = (menu.selected - 1 + 6) % 6;
            }
        },
        {
            binds: "Down",
            action: () => {
                menu.selected = (menu.selected + 1 + 6) % 6;
            }
        },
        {
            binds: "Return",
            action: () => {
                menu.actions[menu.selected]();
            }
        },
    ]

    Cells {
        id: menu

        onVisibleChanged: {
            selected = 0;
        }

        property int selected: 0
        property color select_color: Colors.blend(Colors.accentStrong, Colors.secondary, 0.5)
        property color base_color: Colors.fgBase

        property var actions: [() => PowerManager.call("Sleep", 3), () => PowerManager.call("Reboot", 3), () => PowerManager.call("Shutdown", 3), () => SystemInfo.lock(), () => PowerManager.call("Logout", 3), () => root.close(),]

        w: Cell.wCount(root.implicitWidth, "ceil")
        h: Cell.hCount(root.implicitHeight, "ceil")

        color: Colors.transparent(Qt.darker(Colors.bgBase, 2), 0.8)

        MouseControl {

            anchors.fill: parent

            onReleased: button => {
                if (button == "L") {
                    root.close();
                }
            }
        }

        Cells {
            id: list

            property bool show: true

            visible: show

            w: Cell.wCount(layout.implicitWidth)
            h: Cell.hCount(layout.implicitHeight)

            x: Cell.centerWCell(implicitWidth, menu.implicitWidth) - Cell.w(3)
            y: Cell.centerHCell(implicitHeight, menu.implicitHeight)

            color: "transparent"

            ColumnLayout {
                id: layout

                spacing: Cell.h(1)

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

        Component.onCompleted: {
            PowerManager.called.connect((mode, count) => {
                if (root && !root.visible) {
                    openAnim.restart();
                    blackout.opacity = 0;
                    countdown.opacity = 1;
                    top_bar.implicitHeight = 0;
                    bottom_bar.implicitHeight = 0;
                }
                countdown.mode = mode;
                countdown.count = count;
                countdown.active = true;
                list.show = false;
                blacking_out.restart();
                if (!PopupManager.isOpen("power")) {
                    PopupManager.open("power");
                }
            });
        }

        Rectangle {
            id: blackout

            anchors.fill: parent

            color: "black"
        }

        Rectangle {
            id: top_bar

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            implicitHeight: root.monitor.height / 2

            color: "black"
        }

        Rectangle {
            id: bottom_bar

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            implicitHeight: root.monitor.height / 2

            color: "black"
        }

        CellText {
            id: countdown

            property int count: 3

            property string mode: "Sleep"

            property bool active: false

            visible: !list.show

            layer.enabled: true

            x: Cell.centerWCell(implicitWidth, menu.implicitWidth) - Cell.w(3)
            y: Cell.centerHCell(implicitHeight, menu.implicitHeight)
            pure: false
            lockPure: true
            text: ANSI.render(mode + " in " + count, 2)
            color: menu.select_color
        }

        Timer {
            id: close_delay
            interval: 500
            onTriggered: {
                root.close();
            }
        }

        Timer {
            id: timer

            interval: 1000
            running: countdown.active
            repeat: true
            onTriggered: {
                if (countdown.count > 0) {
                    countdown.count--;
                }
                if (countdown.count == 0 && countdown.active) {
                    countdown.active = false;
                    close_delay.running = true;
                    switch (countdown.mode) {
                    case "Shutdown":
                        SystemInfo.shutdown();
                        break;
                    case "Sleep":
                        SystemInfo.sleep();
                        break;
                    case "Reboot":
                        SystemInfo.reboot();
                        break;
                    case "Logout":
                        SystemInfo.logout();
                        break;
                    }
                }
            }
        }
    }

    component Option: CellText {
        id: option

        property int index: 0
        property string title: "1.suspend"
        property var action: undefined

        readonly property int selected: menu.selected == index

        pure: false
        lockPure: true
        text: ANSI.render(title, selected ? 2 : 1)
        clip: true

        MouseControl {

            anchors.fill: parent

            onEntered: {
                menu.selected = parent.index;
            }

            onReleased: button => {
                if (button == "L") {
                    if (option.action) {
                        option.action();
                    } else {
                        menu.actions[option.index]();
                    }
                }
            }
        }

        color: selected ? menu.select_color : menu.base_color
    }
}
