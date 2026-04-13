pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    property var box

    spacing: 0

    CellScrollView {

        id: list

        w: root.box.contentW
        h: 26

        ColumnLayout {

            spacing: 0

            Repeater {

                model: NotificationsInfo.notifications_groups

                delegate: Cells {

                    id: notif

                    required property var modelData

                    property bool group: modelData.notifications.length > 1
                    property bool expanded: false

                    w: list.contentW
                    h: 3

                    color: "transparent"

                    Cells {

                        x: Cell.w(6)

                        property bool hovered: false

                        w: list.contentW - 7
                        h: 2

                        color: hovered ? Colors.bgOverlay : "transparent"

                        MouseControl {

                            anchors.fill: parent

                            onEntered: {
                                parent.hovered = true
                            }
                            onExited: {
                                parent.hovered = false
                            }

                        }

                    }

                    ColumnLayout {

                        spacing: 0

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

                                Layout.alignment: Qt.AlignTop

                                spacing: 0

                                CellText {
                                    text: notif.modelData.appName ?? "Unknown"
                                    font: Cell.fontB
                                    preferedW: list.contentW - 9 - 3*notif.group
                                }

                                CellText {
                                    text: notif.modelData.notifications[notif.modelData.notifications.length - 1].summary ?? ""
                                    color: notif.group ? Colors.fgSubtle : Colors.fgBase
                                }

                            }

                            CellText {

                                visible: notif.group

                                Layout.alignment: Qt.AlignTop

                                text: !notif.expanded ? " \udb80\udf5d" : " \udb80\udf60"

                            }
                            
                        }

                        CellSeparator {

                            type: 2
                            padding: 1
                            color: Colors.bgOverlay
                            w: list.contentW

                        }

                    }


                }

            }

        }

    }

    CellSeparator {
        w: root.box.contentW
        padding: 1
        color: Colors.fgSubtle
    }

    RowLayout {
        spacing: 0

        CellText {
            text: " "
        }

        CellButton {

            text: "Clear"

            color: [Colors.bgOverlay, Colors.fgBase]
            fg: [Colors.fgBase, Colors.bgSurface]

            font: buttonDown ? Cell.fontB : Cell.font

        }

        CellText {
            text: " "
        }

        CellButton {

            text: "Collapse All"

            color: [Colors.bgOverlay, Colors.fgBase]
            fg: [Colors.fgBase, Colors.bgSurface]

            font: buttonDown ? Cell.fontB : Cell.font

        }
    }

}

