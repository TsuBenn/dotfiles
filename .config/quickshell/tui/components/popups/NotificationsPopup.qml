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

    w: 40
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

                property string summary: modelData.summary
                property string body: modelData.body

                w: root.w
                h: 4 + (body.text.split("\n").length-1)

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

                        Cells {

                            Layout.alignment: Qt.AlignTop

                            w: 6
                            h: 2

                            color: "transparent"

                            Image {
                                source: "image://icon/zen-browser"
                                height: Cell.h(2)
                                width: Cell.h(2)

                                fillMode: Image.PreserveAspectCrop
                            }
                        }

                        ColumnLayout {

                            CellText {
                                text: popup.summary
                                preferedW: root.w - 15
                                font: Cell.fontB
                            }

                            CellText {
                                id: body
                                text: popup.body?.length > 0 ? popup.body : ""
                                preferedW: root.w - 10
                            }

                        }

                    }

                    CellButton {
                        x: Cell.alignRightWCell(implicitWidth,content.implicitWidth) - Cell.w(1)
                        padding: 1
                        text: "X"
                        color: [Colors.bgOverlay, Colors.fgBase]
                        fg: [Colors.fgBase, Colors.bgSurface]

                        onReleased: (button) => {
                            let notif = root.notif 
                            root.notif = notif.filter((_, i) => i != popup.index)
                        }
                    }

                }

                Timer {
                    id: timer

                    interval: 2000
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
