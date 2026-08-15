pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import Quickshell.Services.Notifications
import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    visible: true

    property var notif: []

    w: 50
    h: Cell.hCount(layout.implicitHeight)

    Component.onCompleted: {

        PopupManager.opened.connect((name) => {
            if (name == "control_panel") notif = []
        })

        NotificationsInfo.notificationSent.connect((notif) => {

            if (SettingsInfo.dnd) return

            if (PopupManager.isOpen("control_panel")) return

            if (notif.lastGen) return

            let buffer = root.notif
            buffer = [notif, ...buffer]

            let new_notif = []

            for (const not of buffer) {
                if (not.object.summary) {
                    new_notif.push(not)
                }
            }

            if (new_notif.length > 3) {
                new_notif.slice(0, 3)
            }

            root.notif = new_notif

        })
    }

    ColumnLayout {

        id: layout

        spacing: Cell.h(2)

        Repeater {

            model: root.notif

            delegate: CellBox {

                id: popup

                required property int index
                required property var modelData

                property int urgency: modelData.urgency
                property string summary: modelData.summary
                property string body: modelData.body
                property string app: modelData.app
                property string icon: modelData.icon
                property string image: modelData.image
                property var object: modelData.object

                property bool focused: false

                function close() {
                    let notif = root.notif
                    root.notif = notif.slice(1)
                }

                w: root.w
                h: body.h + 3

                border.color: {
                    if (popup.urgency == 2) {
                        return Colors.blend(Colors.fgBase, Colors.danger, 0.8)
                    } else if (popup.urgency == 1) {
                        return Colors.blend(Colors.fgBase, Colors.warning, 0.5)
                    }
                    return Colors.fgBase
                }

                MouseControl {
                    anchors.fill: parent

                    onEntered: {
                        timer.stop()
                    }
                    onExited: {
                        timer.restart()
                    }

                    onReleased: (button) => {
                        if (button == "L") {
                            if (popup.object) {
                                for (const action of popup.object.actions) {
                                    if (action.identifier == "default") {
                                        action.invoke()
                                        popup.close()
                                        break
                                    }
                                }
                            }
                        }
                    }
                }

                Cells {

                    id: content

                    w: popup.contentW
                    h: popup.contentH

                    color: "transparent"

                    RowLayout {

                        spacing: 0

                        CellText {
                            text: " "
                        }

                        CellIcon {

                            Layout.alignment: Qt.AlignTop

                            w: 6
                            id: icon
                            image: popup.image
                            icon: [popup.icon, popup.app]
                        }

                        ColumnLayout {

                            spacing: 0

                            CellText {
                                text: popup.summary
                                preferedW: SettingsInfo.safeNotifications && popup.app != "REMINDERS & EVENTS" && popup.app != "" ? 2 : root.w - 8 - 6*icon.success
                                font: Cell.fontB
                                color: {
                                    if (popup.urgency == 2) {
                                        return Colors.blend(Colors.fgBase, Colors.danger, 0.8)
                                    } else if (popup.urgency == 1) {
                                        return Colors.blend(Colors.fgBase, Colors.warning, 0.5)
                                    }
                                    return Colors.fgBase
                                }
                            }

                            CellText {
                                id: body
                                text: SettingsInfo.safeNotifications && popup.app != "REMINDERS & EVENTS" ? "[Safe notification is ON]" : popup.body
                                preferedW: root.w - 14
                                wrap: true
                                color: {
                                    if (SettingsInfo.safeNotifications && popup.app != "") {
                                        return Colors.success
                                    } else {
                                        return Colors.fgBase
                                    }
                                }
                            }

                            CellText {

                                visible: {
                                    return popup.body.split("\n").length > 5
                                }

                                id: body_more
                                text: "..."
                                preferedW: root.w - 14
                                color: Colors.fgDim
                            }

                        }

                    }

                    CellButton {
                        x: Cell.alignRightWCell(implicitWidth,content.implicitWidth) - Cell.w(1)
                        padding: 1
                        text: "\uea76"
                        color: [Colors.bgOverlay, Colors.fgBase]
                        fg: [Colors.fgBase, Colors.bgSurface]

                        onReleased: (button) => {
                            let notif = root.notif
                            root.notif = notif.filter((_, i) => i != popup.index)
                        }
                    }

                    Timer {
                        id: timer

                        interval: {
                            const base = 3000
                            const extra = popup.body.length*10*popup.urgency
                            return Math.min(base + extra, 10000)
                        }
                        running: popup.index == 0
                        onTriggered: {
                            popup.close()
                        }
                    }

                }


            }

        }

    }

}
