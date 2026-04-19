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
        NotificationsInfo.notificationSent.connect((notif) => {
            let new_notif = root.notif
            new_notif = [...new_notif, notif]
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

                property bool focused: false

                w: root.w
                h: 4 + (body.text.split("\n").length-1)

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
                            icon: [popup.icon, popup.app]
                        }

                        ColumnLayout {

                            spacing: 0

                            CellText {
                                text: popup.summary
                                preferedW: root.w - 10 - 6*icon.success
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
                                text: popup.body?.length > 0 ? popup.body.trim() : ""
                                preferedW: root.w - 14
                                wrap: true
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
                            const base = 2000
                            const extra = popup.body.length*100
                            return Math.min(base + extra, 15000)
                        }
                        running: popup.index == 0
                        onTriggered: {
                            let notif = root.notif 
                            root.notif = notif.slice(1)
                        }
                    }

                }


            }

        }

    }

}
